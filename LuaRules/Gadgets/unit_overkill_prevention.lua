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

local pmap = VFS.Include("LuaRules/Utilities/pmap.lua")

local DECAY_FRAMES = 1200 -- time in frames it takes to decay 100% para to 0 (taken from unit_boolean_disable.lua)

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end

local canHandleUnit = {}
local units = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local HandledUnitDefIDs = {
	[UnitDefNames["corrl"].id] = true,
	[UnitDefNames["armcir"].id] = true,
	[UnitDefNames["nsaclash"].id] = true,
	[UnitDefNames["missiletower"].id] = true,
	[UnitDefNames["screamer"].id] = true,
	[UnitDefNames["amphaa"].id] = true,
	[UnitDefNames["puppy"].id] = true,
	[UnitDefNames["fighter"].id] = true,
	[UnitDefNames["hoveraa"].id] = true,
	[UnitDefNames["spideraa"].id] = true,
	[UnitDefNames["vehaa"].id] = true,
	[UnitDefNames["gunshipaa"].id] = true,
	[UnitDefNames["gunshipsupport"].id] = true,
	[UnitDefNames["armsnipe"].id] = true,
	[UnitDefNames["amphraider3"].id] = true,
	[UnitDefNames["amphriot"].id] = true,
	[UnitDefNames["subarty"].id] = true,
	[UnitDefNames["subraider"].id] = true,
	[UnitDefNames["corcrash"].id] = true,
	[UnitDefNames["cormist"].id] = true,
	[UnitDefNames["tawf114"].id] = true, --HT's banisher
	[UnitDefNames["shieldarty"].id] = true, --Shields's racketeer
	-- Static only OKP below
	[UnitDefNames["amphfloater"].id] = true,
	[UnitDefNames["armmerl"].id] = true,
	[UnitDefNames["reef"].id] = true,
	[UnitDefNames["armorco"].id] = true,
	[UnitDefNames["corstorm"].id] = true,
	[UnitDefNames["corthud"].id] = true,
	[UnitDefNames["spiderassault"].id] = true,
	[UnitDefNames["armrock"].id] = true,
	-- Needs LUS
	--[UnitDefNames["correap"].id] = true,
	--[UnitDefNames["corraid"].id] = true,
	--[UnitDefNames["corgol"].id] = true,
	--[UnitDefNames["armham"].id] = true,
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

local function IsUnitIdentifiedStructure(identified, inLOS, unitID)
	if not identified then
		return false
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not (unitDefID and UnitDefs[unitDefID]) then
		return false
	end
	
	if (Spring.Utilities.getMovetype(UnitDefs[unitDefID])) then
		--for units
		if (inLOS) then
			local vx, vy, vz, vl = Spring.GetUnitVelocity(unitID)
			local isNotMoving = (vx == 0 and vy == 0 and vz == 0 and vl == 0)
			if isNotMoving then
				return true
			end
		end
		return false
	else
		--for buildings
		return true
	end
end

--[[
	unitID, targetID - unit IDs. Self explainatory
	fullDamage - regular damage of salvo
	disarmDamage - disarming damage
	disarmTimeout - for how long in frames unit projectile may cause unit disarm state (it's a cap for "disarmframe" unit param)
	timeout -- percieved projectile travel time from unitID to targetID in frames
	fastMult -- Multiplier to timeout if the target is fast
	radarMult -- Multiplier to timeout if the taget is a radar dot
]]--
local function CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, disarmDamage, disarmTimeout, timeout, fastMult, radarMult, staticOnly)
	
	-- Modify timeout based on unit speed and fastMult
	local unitDefID
	if fastMult and fastMult ~= 1 then
		unitDefID = Spring.GetUnitDefID(targetID)
		if fastUnitDefs[unitDefID] then
			timeout = timeout * (fastMult or 1)
		end
	end
	
	-- Get unit health and status effects. An unseen unit is assumed to be fully healthy and armored.
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	
	local targetVisiblityState = Spring.GetUnitLosState(targetID, allyTeamID, true)
	local targetInLoS = (targetVisiblityState == 15)
	local targetIdentified = (targetVisiblityState > 2)
	
	-- When true, the projectile damage will be added to the damage to be taken by the unit.
	-- When false, it will only check whether the shot should be blocked.
	local addToIncomingDamage = true
	
	if staticOnly then
		addToIncomingDamage = IsUnitIdentifiedStructure(targetIdentified, targetInLoS, targetID)
	end
	
	local adjHealth, disarmFrame
	if targetInLoS then
		local armor = select(2,Spring.GetUnitArmored(targetID)) or 1
		adjHealth = spGetUnitHealth(targetID)/armor -- adjusted health after incoming damage is dealt
		
		disarmFrame = spGetUnitRulesParam(targetID, "disarmframe") or -1
		if disarmFrame == -1 then
			--no disarm damage on targetID yet(already)
			disarmFrame = gameFrame 
		end 	
	else
		timeout = timeout * (radarMult or 1)
		
		unitDefID = unitDefID or Spring.GetUnitDefID(targetID)
		local ud = UnitDefs[unitDefID]
		adjHealth = ud.health/ud.armoredMultiple
		disarmFrame = -1
	end

	local incData = incomingDamage[targetID]
	local targetFrame = gameFrame + timeout
	local block = false
	
	if incData then --seen this target
		local startIndex, endIndex = incData.frames:GetIdxs()
		for i = startIndex, endIndex do
			local keyValue = incData.frames:GetKV(i)
			local frame, data = keyValue[1], keyValue[2]
			--Spring.Echo(frame)
			if frame < gameFrame then
				incData.frames:TrimFront() --frames should come in ascending order, so it's safe to trim front of array one by one
			else
				local disarmDamage = data.disarmDamage
				local fullDamage = data.fullDamage
				
				local disarmExtra = math.floor(disarmDamage/adjHealth*DECAY_FRAMES)
				adjHealth = adjHealth - fullDamage
				
				disarmFrame = disarmFrame + disarmExtra
				if disarmFrame > frame + DECAY_FRAMES + disarmTimeout then 
					disarmFrame = frame + DECAY_FRAMES + disarmTimeout 
				end
			end
		end
	else --new targe
		if not addToIncomingDamage then
			return false
		end
		incomingDamage[targetID] = {frames = pmap()}
		incData = incomingDamage[targetID]
	end
	
	local doomed = targetIdentified and (adjHealth < 0) and (fullDamage > 0) --for regular projectile
	local disarmed = targetIdentified and (disarmFrame - gameFrame - timeout >= DECAY_FRAMES) and (disarmDamage > 0) --for disarming projectile
	
	incomingDamage[targetID].doomed = doomed
	incomingDamage[targetID].disarmed = disarmed
	
	block = doomed or disarmed --assume function is not called with both regular and disarming damage types	
	
	if not block then
		--Spring.Echo("^^^^SHOT^^^^")
		if addToIncomingDamage then
			local frameData = incData.frames:Get(targetFrame)
			if frameData then 
				-- here we have a rare case when few different projectiles (from different attack units) 
				-- are arriving to the target at the same frame. Their powers must be accumulated/harmonized
				frameData.fullDamage = frameData.fullDamage + fullDamage
				frameData.disarmDamage = frameData.disarmDamage + disarmDamage
				incData.frames:Upsert(targetFrame, frameData)
			else --this case is much more common: such frame does not exist in incData.frames
				incData.frames:Insert(targetFrame, {fullDamage = fullDamage, disarmDamage = disarmDamage})
			end
			incData.lastFrame = math.max(incData.lastFrame or 0, targetFrame)
		end
	else
		local teamID = spGetUnitTeam(unitID)
		-- Overkill prevention does not prevent firing at unidentified radar dots.
		-- Although, it still remembers what has been fired at a radar dot.
		if targetIdentified then
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


function GG.OverkillPrevention_CheckBlockDisarm(unitID, targetID, damage, timeout, disarmTimer, fastMult, radarMult, staticOnly)
	if not (unitID and targetID and units[unitID]) then
		return false
	end
	
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		--CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, disarmDamage, disarmTimeout, timeout)
		return CheckBlockCommon(unitID, targetID, gameFrame, 0, damage, disarmTimer, timeout, fastMult, radarMult, staticOnly)
	end
end

function GG.OverkillPrevention_CheckBlock(unitID, targetID, damage, timeout, fastMult, radarMult, staticOnly)
	if not (unitID and targetID and units[unitID]) then
		return false
	end
	
	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		--CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, disarmDamage, disarmTimeout, timeout)
		return CheckBlockCommon(unitID, targetID, gameFrame, damage, 0, 0, timeout, fastMult, radarMult, staticOnly)		
	end
	return false
end

function gadget:UnitDestroyed(unitID)
	if incomingDamage[unitID] then
		incomingDamage[unitID] = nil
	end
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
		return false
	end
	return true
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
	return PreventOverkillToggleCommand(unitID, cmdParams, cmdOptions)  
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if HandledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {1})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_OVERKILL)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end