--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Overkill Prevention",
    desc      = "Prevents some units from firing at units which are going to be killed by incoming missiles.",
    author    = "Google Frog, ivand",
    date      = "14 Jan 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spValidUnitID         = Spring.ValidUnitID
local spSetUnitTarget       = Spring.SetUnitTarget
local spGetUnitHealth       = Spring.GetUnitHealth
local spGetGameFrame        = Spring.GetGameFrame
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spGetUnitCommands     = Spring.GetUnitCommands
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitArmored      = Spring.GetUnitArmored
local spGetUnitSeparation   = Spring.GetUnitSeparation
local spGetUnitIsStunned    = Spring.GetUnitIsStunned
local spGetUnitShieldState	= Spring.GetUnitShieldState

local pmap = VFS.Include("LuaRules/Utilities/pmap.lua")

local DECAY_FRAMES = 1200 -- time in frames it takes to decay 100% para to 0 (taken from unit_boolean_disable.lua)

local addSearchRadius = 200 --addition to a shield radius when search of nearby covered units is being performed

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end

-- damage to shields modifiers (taken from armordefs.lua)
--local EMP_DAMAGE_MOD = 1/3
--local SLOW_DAMAGE_MOD = 1/3
local DISARM_DAMAGE_MOD = 1/3
--local FLAMER_DAMAGE_MOD = 3
--local GAUSS_DAMAGE_MOD = 1.5


local canHandleUnit = {}
local units = {}
local shields = {}
local shieldCoveredUnits = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local HandledUnitDefIDs = {
	[UnitDefNames["corrl"].id] = true, --Defender
	[UnitDefNames["armcir"].id] = true, --Chainsaw
	[UnitDefNames["nsaclash"].id] = true, --Scalpel
	[UnitDefNames["missiletower"].id] = true, --Hacksaw
	[UnitDefNames["screamer"].id] = true, --Screamer
	[UnitDefNames["amphaa"].id] = true, --Angler
	[UnitDefNames["puppy"].id] = true, --Puppy
	[UnitDefNames["fighter"].id] = true, --Swift's rocket weapon
	[UnitDefNames["hoveraa"].id] = true, --Flail
	[UnitDefNames["spideraa"].id] = true, --Tarantula
	[UnitDefNames["vehaa"].id] = true, --Crasher
	[UnitDefNames["gunshipaa"].id] = true, --Trident
	[UnitDefNames["gunshipsupport"].id] = true, --Rapier
	[UnitDefNames["armsnipe"].id] = true, --Sharpshooter
	[UnitDefNames["amphraider3"].id] = true, --Duck
	[UnitDefNames["amphriot"].id] = true, --Scallop's sea weapon
	[UnitDefNames["subarty"].id] = true, --Serpent (Sniper sub)
	[UnitDefNames["subraider"].id] = true, --Submarine (ordinal sub)
	[UnitDefNames["corcrash"].id] = true, --Vandal
	[UnitDefNames["cormist"].id] = true, --Slasher
	[UnitDefNames["tawf114"].id] = true, --Banisher	
	[UnitDefNames["shieldarty"].id] = true, --Shields's racketeer
}

include("LuaRules/Configs/customcmds.h.lua")

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Prevent Overkill", "Fire at anything"}
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local incomingDamage = {}

function GG.OverkillPrevention_IsDoomed(targetID)
	if incomingDamage[targetID] then
		local gameFrame = spGetGameFrame()
		local lastFrame = incomingDamage[targetID].lastFrame or 0
		return (gameFrame <= lastFrame and incomingDamage[targetID].doomed)
	end
	return false
end

function GG.OverkillPrevention_IsDisarmExpected(targetID)
	if incomingDamage[targetID] then
		local gameFrame = spGetGameFrame()
		local lastFrame = incomingDamage[targetID].lastFrame or 0
		return (gameFrame <= lastFrame and incomingDamage[targetID].disarmed)
	end
	return false
end

--[[
	unitID, targetID - unit IDs. Self explainatory
	fullDamage - regular damage of salvo (one or more projectiles shot simultaneously)
	salvoSize - size of regular damage salvo
	disarmDamage - disarming damage
	disarmTimeout - for how long in frames unit projectile may cause unit disarm state (it's a cap for "disarmFrame" unit param)
	timeout -- percieved projectile travel time from unitID to targetID in frames
]]--
local function CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, salvoSize, disarmDamage, disarmTimeout, timeout)
	local incData = incomingDamage[targetID]
	local targetFrame = gameFrame + timeout
	
	local armor = select(2, spGetUnitArmored(targetID)) or 1
	local adjHealth = spGetUnitHealth(targetID)/armor -- health, adjusted by factor of armor
	
	local disarmFrame = spGetUnitRulesParam(targetID, "disarmframe") or -1
	if disarmFrame == -1 then
		--no disarm damage on targetID yet(already)
		disarmFrame = gameFrame 
	end 

	local block = false
	
	if incData then --seen this target, makes sense to calculate if this shot needs to be blocked
	
		--shields
		local shieldCoverData = shieldCoveredUnits[targetID]
		local relevantShields={} --hash of shield IDs, that can potentially cover particular target
		
		local targetUnitDefID = spGetUnitDefID(targetID)	
		local targetSpeed = UnitDefs[targetUnitDefID].speed or 0 --used for shield-related part of the code
		
		if shieldCoverData then		
			local unitAllyID = spGetUnitAllyTeam(unitID)		
			
			for _, shID in pairs (shieldCoverData) do
				if (spValidUnitID(shID) and spGetUnitHealth(shID) > 0.0) and --shield must be valid and alive
				((not spGetUnitIsStunned(shID)) and spGetUnitRulesParam(shID, "disarmed") ~= 1) and --TODO check if unit will be disarmed soon?
				(shields[shID].allyTeamID ~= unitAllyID) then --check if shield belongs to another alliance, thus will block our projectiles
				
					--Spring.Echo("shields[shID].shieldWeaponDefID="..shields[shID].shieldWeaponDefID)
					local shWDef=WeaponDefs[shields[shID].shieldWeaponDefID]
					local shieldPowerMax=shWDef.shieldPower
					local shieldPowerRegen=shWDef.shieldPowerRegen --HP/sec
					local shieldRadius=shWDef.shieldRadius

					local enabledShield, curShieldPower = spGetUnitShieldState(shID)
					curShieldPower=curShieldPower*enabledShield --just in case
					
					relevantShields[shID] = {curShieldPower = curShieldPower, shieldPowerMax = shieldPowerMax, shieldPowerRegen = shieldPowerRegen, shieldRadius = shieldRadius} --saving relevant shield parameters for future calculation
				end
			end			
				
		end
		--/shields
		
		local startIndex, endIndex = incData.frames:GetIdxs()
		for i = startIndex, endIndex do
			local keyValue = incData.frames:GetKV(i)
			local frame, data = keyValue[1], keyValue[2]

			if frame < gameFrame then
				--remove old frame data
				incData.frames:TrimFront() --frames should come in ascending order, so it's safe to trim front of array one by one
			else
				local disarmDamages = data.disarmDamages
				local regularDamages = data.regularDamages
				
				--By convention I've just established hereby, if both regular and non-regular damages happen same frame the non-regular damages are applied first				

				if disarmDamages then
					for idx, damage in pairs(disarmDamages) do
						local damageToShield = damage * DISARM_DAMAGE_MOD	
						local absorbed = false
						for shID, shData in pairs (relevantShields) do
							local shieldSpeed = shields[shID].speed
							if spGetUnitSeparation(shID, targetID, true) <= (targetSpeed + shieldSpeed) * (frame - gameFrame) then --this shield can potentially cover this target @frame time
							
								local expectedShieldPower = shData.curShieldPower + shData.shieldPowerRegen * (frame - gameFrame) / 30 --estimate how powerful shield will be @frame time
								if expectedShieldPower > shData.shieldPowerMax then expectedShieldPower = shData.shieldPowerMax end --cap shieldPower to maximum power of shield 								
								
								if damageToShield <= expectedShieldPower then  --this shield has absorbed damage
									relevantShields[shID].curShieldPower = relevantShields[shID].curShieldPower - damageToShield
									--this can go below 0, but it's virtual, since calculus is done @frame and it's <0 @gameFrame
									absorbed = true
									break
								end
							end
						end
						
						if not absorbed then --this projectile comes through all shields (if any)
							local disarmExtra = math.floor(damage/adjHealth*DECAY_FRAMES)
							disarmFrame = disarmFrame + disarmExtra
							if disarmFrame > frame + DECAY_FRAMES + disarmTimeout then 
								disarmFrame = frame + DECAY_FRAMES + disarmTimeout 
							end
						end
						
					end
				end
				
				if regularDamages then
					for idx, damage in pairs(regularDamages) do
						local damageToShield = damage
						local absorbed = false
						for shID, shData in pairs (relevantShields) do
							local shieldSpeed = shields[shID].speed
							if spGetUnitSeparation(shID, targetID, true) <= (targetSpeed + shieldSpeed) * (frame - gameFrame) then --this shield can potentially cover this target @frame time
							
								local expectedShieldPower = shData.curShieldPower + shData.shieldPowerRegen * (frame - gameFrame) / 30 --estimate how powerful shield will be @frame time
								if expectedShieldPower > shData.shieldPowerMax then expectedShieldPower = shData.shieldPowerMax end --cap shieldPower to maximum power of shield 								
								
								if damageToShield <= expectedShieldPower then  --this shield has absorbed damage
									relevantShields[shID].curShieldPower = relevantShields[shID].curShieldPower - damageToShield
									--this can go below 0, but it's virtual, since calculus is done @frame and it's <0 @gameFrame
									absorbed = true
									break
								end
							end
						end

						if not absorbed then --this projectile comes through all shields (if any)
							adjHealth = adjHealth - damage
						end
						
					end
				end
				
			end
		end
	else --new target
		incomingDamage[targetID] = {frames = pmap()}
		incData = incomingDamage[targetID]
	end
	
	local doomed = (adjHealth < 0) and (fullDamage > 0) --for regular projectile
	local disarmed = (disarmFrame - gameFrame - timeout >= DECAY_FRAMES) and (disarmDamage > 0) --for disarming projectile
	
	incomingDamage[targetID].doomed = doomed
	incomingDamage[targetID].disarmed = disarmed
	
	block = doomed or disarmed --assume function is not called with both regular and disarming damage types
	
	--Spring.Echo("Blocked="..tostring(block))
	
	
	if not block then
		--Spring.Echo("^^^^SHOT^^^^")
		local frameData = incData.frames:Get(targetFrame)
		if not frameData then frameData = {} end
		
		-- damages used to be bluntly summed up, however this approach was just wrong when dealing with shields or disarming missiles.
		-- For such cases numeric sum of projectile powers gives different outcome to individual projectiles simulation
		-- Example: 2 projectiles 500 damage each will not penetrate two shields 550 shield power each, however single imaginary 1000 (500+500) damage projectile will penetrate both.
			
		if fullDamage > 0 then
			if not frameData.regularDamages then frameData.regularDamages = {} end
			local singleDamage = fullDamage / salvoSize				
			for i = 1, salvoSize do
				table.insert(frameData.regularDamages, singleDamage)			
			end
		end
		
		if disarmDamage > 0 then
			if not frameData.disarmDamages then frameData.disarmDamages = {} end
			table.insert(frameData.disarmDamages, disarmDamage)
		end
		
		incData.frames:Upsert(targetFrame, frameData)
		
		incData.lastFrame = math.max(incData.lastFrame or 0, targetFrame)
	else
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = CallAsTeam(teamID, spGetUnitDefID, targetID)
		-- UnitDefID check is purely to check for type identification of the unit (either LOS or identified radar dot)
		-- Overkill prevention is not allowed to be smart for unidentified units.
		if unitDefID then
			local queueSize = spGetUnitCommands(unitID, 0)
			if queueSize == 1 then
				local queue = spGetUnitCommands(unitID, 1)
				local cmd = queue[1]
				if (cmd.id == CMD.ATTACK) and (cmd.options.internal) and (#cmd.params == 1 and cmd.params[1] == targetID) then
					--Spring.Echo("Removing auto-attack command")
					spGiveOrderToUnit(unitID, CMD.REMOVE, {cmd.tag}, {} )
					--Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {} )
				end
			else
				spSetUnitTarget(unitID, 0)
			end
			
			return true
		end
	end
	
	return false
end


function GG.OverkillPrevention_CheckBlockDisarm(unitID, targetID, damage, timeout, disarmTimer)
	if not units[unitID] then
		return false
	end
	
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		--CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, salvoSize, disarmDamage, disarmTimeout, timeout)
		return CheckBlockCommon(unitID, targetID, gameFrame, 0, 1, damage, disarmTimer, timeout)
	end
	return false
end

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout, troubleVsFast)
	return GG.OverkillPrevention_CheckBlockSalvo(unitID, targetID, damage, 1, timeout, troubleVsFast)
end

function GG.OverkillPrevention_CheckBlockSalvo(unitID, targetID, damage, salvoSize, timeout, troubleVsFast)
	if not units[unitID] then
		return false
	end	

	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		if troubleVsFast then
			local unitDefID = spGetUnitDefID(targetID)
			if fastUnitDefs[unitDefID] then
				damage = 0
			end
		end
		
		--CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, salvoSize, disarmDamage, disarmTimeout, timeout)
		return CheckBlockCommon(unitID, targetID, gameFrame, damage, salvoSize, 0, 0, timeout)		
	end
	return false
end

--------------------------------------------------------------------------------
-- Command Handling
local function PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_OVERKILL)
		
		if (cmdDescID) then
			preventOverkillCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, {params = preventOverkillCmdDesc.params})
		end
		if state == 1 then
			if not units[unitID] then
				units[unitID] = true
			end
		else
			if units[unitID] then
				units[unitID] = nil
			end
		end
	end
	
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[CMD_PREVENT_OVERKILL] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID ~= CMD_PREVENT_OVERKILL) then		
		return true  -- command was not used
	end	
	PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)  
	return false  -- command was used
end

function gadget:GameFrame(f)
	if f%16 == 4 then
		shieldCoveredUnits={} --empty array first
		
		for shID, _ in pairs(shields) do --this will iterate through shield unitIDs
			local xSh, _, zSh = spGetUnitPosition(shID)
			
			local shieldWeaponDef = shields[shID].shieldWeaponDefID --get shID's biggest shield		
			local unitShieldRadius = WeaponDefs[shieldWeaponDef].shieldRadius --get its radius
			
			local unitsAround = spGetUnitsInCylinder(xSh, zSh, unitShieldRadius + addSearchRadius)
			
			for _, uId in pairs(unitsAround) do				
				if not shieldCoveredUnits[uId] then --this unit has not been marked as covered by any shield yet
					shieldCoveredUnits[uId] = {}
				end
				
				--add shield unit ID(shID) as a cover for uId
				table.insert(shieldCoveredUnits[uId], shID)				
			end
		end
		
		--[[
		Spring.Echo("^^^^^^^^^FRAME^^^^^^^^^")
		for k,v in pairs(shieldCoveredUnits) do
			Spring.Echo("uId="..k.." is covered with "..#v.." shields")
		end
		]]--
	end
end


--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if HandledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {1})
	end
	
	local ud=UnitDefs[unitDefID]
	if ud.shieldWeaponDef then --unit has at least one shield. Apparently ZK has got rid of any unit with > 1 shield, so it's safe to assume shielded units carry exactly one shield.
	--[[ --it's safe to delete. All shielded ZK units have single shield.
		local shieldWeaponDefIDs = {}		
		for wId, weapon in pairs(ud.weapons) do
			local wdId = weapon.weaponDef
			local wDef = WeaponDefs[wdId]
			if wDef.isShield then
				table.insert(shieldWeaponDefIDs, wdId)
			end
		end

		shields[unitID] = {teamID = teamID, unitDefID = unitDefID, allyTeamID = spGetUnitAllyTeam(unitID),
							shieldWeaponDefIDs = shieldWeaponDefIDs, shieldWeaponDefID = UnitDefs[unitDefID].shieldWeaponDef, speed=ud.speed or 0}
	]]--
		shields[unitID] = {teamID = teamID, unitDefID = unitDefID, allyTeamID = spGetUnitAllyTeam(unitID),
							shieldWeaponDefID = UnitDefs[unitDefID].shieldWeaponDef, speed=ud.speed or 0}
	
	end	
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
	
	if incomingDamage[unitID] then
		incomingDamage[unitID] = nil
	end	
	
	if shields[unitID] then
		shields[unitID] = nil
	end	
	
	if shieldCoveredUnits[unitID] then
		shieldCoveredUnits[unitID] = nil
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)	
	gadget:UnitDestroyed(unitID)
	gadget:UnitCreated(unitID, unitDefID, newTeam)
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_OVERKILL)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = spGetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end