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
local spGetCommandQueue     = Spring.GetCommandQueue
local spGiveOrderToUnit     = Spring.GiveOrderToUnit
local spGetUnitShieldState  = Spring.GetUnitShieldState

local pmap = VFS.Include("LuaRules/Utilities/pmap.lua")

local DECAY_FRAMES = 1200 -- time in frames it takes to decay 100% para to 0 (taken from unit_boolean_disable.lua)
local HEALTH_FRAME_TIMEOUT = 300 -- 10 seconds.

local FAST_SPEED = 5.5*30 -- Speed which is considered fast.
local fastUnitDefs = {}
for i, ud in pairs(UnitDefs) do
	if ud.speed > FAST_SPEED then
		fastUnitDefs[i] = true
	end
end

local canHandleUnit = {}
local units = {}
local lastShot = {} -- List of the last targets, to stop target switching
local lastHealth = {}
local lastHealthFrame = {}
local lastGain = {}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local handledUnitDefIDs = include("LuaRules/Configs/overkill_prevention_defs.lua")

local shieldPowerDef = {}
local shieldRegenDef = {}
local maxEffectiveHealth = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.customParams.shield_power then
		shieldPowerDef[i] = ud.customParams.shield_power
		shieldRegenDef[i] = ud.customParams.shield_rate/30
	end
	maxEffectiveHealth[i] = (ud.health / ud.armoredMultiple + (shieldPowerDef[i] or 0))
end

include("LuaRules/Configs/customcmds.h.lua")

local preventOverkillCmdDesc = {
	id      = CMD_PREVENT_OVERKILL,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Overkill.",
	action  = 'preventoverkill',
	tooltip	= 'Enable to prevent units shooting at units which are already going to die.',
	params 	= {0, "Fire at anything", "Prevent Overkill"}
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

function GG.OverkillPrevention_GetLastShot(unitID)
	return lastShot[unitID]
end

function GG.OverkillPrevention_IsDisarmExpected(targetID)
	if incomingDamage[targetID] then
		local gameFrame = spGetGameFrame()
		local lastFrame = incomingDamage[targetID].lastFrame or 0
		return (gameFrame <= lastFrame and incomingDamage[targetID].disarmed)
	end
	return false
end

function GG.OverkillPrevention_GetHealthThreshold(targetID, realDamage, fudgeDamage)
	-- Don't do this on unidentified radar dots
	local _, maxHealth = Spring.GetUnitHealth(targetID)
	if not maxHealth then
		return fudgeDamage
	end
	if maxHealth <= realDamage then
		return realDamage
	end
	return fudgeDamage
end

local function IsUnitIdentifiedStructure(identified, unitID)
	if not identified then
		return false
	end
	local unitDefID = spGetUnitDefID(unitID)
	if not (unitDefID and UnitDefs[unitDefID]) then
		return false
	end
	return not Spring.Utilities.getMovetype(UnitDefs[unitDefID])
end

local function GetRepairModifiedHealth(targetID, health, gameFrame, timeout)
	if lastHealthFrame[targetID] and (gameFrame - lastHealthFrame[targetID]) > HEALTH_FRAME_TIMEOUT then
		lastHealth[targetID] = false
		lastHealthFrame[targetID] = false
		lastGain[targetID] = false
	end

	if not lastHealth[targetID] then
		lastHealth[targetID] = health
		lastHealthFrame[targetID] = gameFrame
		return health
	end

	local lastHealthAge = (gameFrame - lastHealthFrame[targetID])
	local gain = health - lastHealth[targetID]

	if lastHealthAge > 2 then
		lastHealth[targetID] = health
		lastHealthFrame[targetID] = gameFrame
	end

	if (lastGain[targetID] or 0)/2 + gain > 0.01 then
		health = health + timeout*(gain + (lastGain[targetID] or 0))/(lastHealthAge + 2)
		lastGain[targetID] = (lastGain[targetID] or 0)/2 + gain
	end
	return health
end

--[[
	unitID, targetID - unit IDs. Self explainatory
	fullDamage - regular damage of salvo
	disarmDamage - disarming damage
	disarmTimeout - for how long in frames unit projectile may cause unit disarm state (it's a cap for "disarmframe" unit param)
	timeout -- percieved projectile travel time from unitID to targetID in frames
	fastMult -- Multiplier to timeout if the target is fast
	radarMult -- Multiplier to timeout if the taget is a radar dot
	staticOnly -- Only against static targets
	noFire -- The unit is just testing whether it would be blocked. It is not neccessarily creating a projectile frrom this test.
]]--
local function CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, disarmDamage, disarmTimeout, timeout, fastMult, radarMult, staticOnly, noFire)
	-- Testing
	--Spring.Utilities.UnitEcho(unitID, timeout + gameFrame)

	-- Modify timeout based on unit speed and fastMult
	local unitDefID = spGetUnitDefID(targetID)
	if fastMult and fastMult ~= 1 then
		if fastUnitDefs[unitDefID] then
			timeout = timeout * (fastMult or 1)
		end
	end

	-- Get unit health and status effects. An unseen unit is assumed to be fully healthy and armored.
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)

	local targetVisiblityState = Spring.GetUnitLosState(targetID, allyTeamID, true)
	local targetInLoS = (targetVisiblityState == 15)
	local targetIdentified = targetInLoS or (math.floor(targetVisiblityState / 4) % 4 == 3)

	-- When true, the projectile damage will be added to the damage to be taken by the unit.
	-- When false, it will only check whether the shot should be blocked.
	local addToIncomingDamage = not noFire
	if staticOnly and not noFire then
		addToIncomingDamage = IsUnitIdentifiedStructure(targetIdentified, targetID)
	end

	local adjHealth, disarmFrame
	if targetInLoS then
		local armored, armorMultiple = Spring.GetUnitArmored(targetID)
		local armor = ((armored and armorMultiple) or 1)
		adjHealth = GetRepairModifiedHealth(targetID, spGetUnitHealth(targetID), gameFrame, timeout)/armor

		if shieldPowerDef[unitDefID] then
			local shieldEnabled, currentPower = spGetUnitShieldState(targetID)
			if shieldEnabled and currentPower then
				adjHealth = adjHealth + currentPower + shieldRegenDef[unitDefID]*timeout
			end
		end

		disarmFrame = spGetUnitRulesParam(targetID, "disarmframe") or -1
		if disarmFrame == -1 then
			disarmFrame = gameFrame
		end
	else
		timeout = timeout * (radarMult or 1)
		adjHealth = (targetIdentified and maxEffectiveHealth[unitDefID]) or false
		disarmFrame = (targetIdentified and gameFrame) or false
	end

	local incData = incomingDamage[targetID]
	local targetFrame = gameFrame + timeout
	local block = false

	if incData then -- seen this target
		if adjHealth and disarmFrame then
			local startIndex, endIndex = incData.frames:GetIdxs()
			for i = startIndex, endIndex do
				local keyValue = incData.frames:GetKV(i)
				local frame, data = keyValue[1], keyValue[2]
				--Spring.Echo(frame)
				if frame < gameFrame then
					incData.frames:TrimFront() --frames should come in ascending order, so it's safe to trim front of array one by one
				else
					local disarmExtra = math.floor(data.disarmDamage/adjHealth*DECAY_FRAMES)
					adjHealth = adjHealth - data.fullDamage

					disarmFrame = disarmFrame + disarmExtra
					if disarmFrame > frame + DECAY_FRAMES + disarmTimeout then
						disarmFrame = frame + DECAY_FRAMES + disarmTimeout
					end
				end
			end
		end
	else --new target
		if not addToIncomingDamage then
			lastShot[unitID] = targetID
			return false
		end
		incomingDamage[targetID] = {frames = pmap()}
		incData = incomingDamage[targetID]
	end

	local doomed = targetIdentified and adjHealth and (adjHealth < 0) and (fullDamage > 0) --for regular projectile
	local disarmed = targetIdentified and disarmFrame and (disarmFrame - gameFrame - timeout >= DECAY_FRAMES) and (disarmDamage > 0) --for disarming projectile

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
			local queueSize = spGetCommandQueue(unitID, 0)
			if queueSize == 1 then
				local cmdID, cmdOpts, cmdTag, cp_1, cp_2 = Spring.GetUnitCurrentCommand(unitID)
				if cmdID == CMD.ATTACK and Spring.Utilities.CheckBit(gadget:GetInfo().name, cmdOpts, CMD.OPT_INTERNAL) and cp_1 and (not cp_2) and cp_1 == targetID then
					--Spring.Echo("Removing auto-attack command")
					GG.recursion_GiveOrderToUnit = true
					spGiveOrderToUnit(unitID, CMD.REMOVE, cmdTag, 0)
					GG.recursion_GiveOrderToUnit = false
				end
			else
				spSetUnitTarget(unitID, 0)
			end

			return true
		end
	end

	if not noFire then
		lastShot[unitID] = targetID
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

function GG.OverkillPrevention_CheckBlockNoFire(unitID, targetID, damage, timeout, fastMult, radarMult, staticOnly)
	if not (unitID and targetID and units[unitID]) then
		return false
	end

	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		--CheckBlockCommon(unitID, targetID, gameFrame, fullDamage, disarmDamage, disarmTimeout, timeout)
		return CheckBlockCommon(unitID, targetID, gameFrame, damage, 0, 0, timeout, fastMult, radarMult, staticOnly, true)
	end
	return false
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

-- Testing
--function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer,  weaponID, attackerID, attackerDefID, attackerTeam)
--    Spring.Utilities.UnitEcho(unitID, Spring.GetGameFrame())
--end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if handledUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventOverkillCmdDesc)
		canHandleUnit[unitID] = true
		PreventOverkillToggleCommand(unitID, {handledUnitDefIDs[unitDefID]})
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if units[unitID] then
			units[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
	incomingDamage[unitID] = nil
	lastHealth[unitID] = nil
	lastHealthFrame[unitID] = nil
	lastGain[unitID] = nil
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_OVERKILL)
	GG.IsUnitIdentifiedStructure = IsUnitIdentifiedStructure
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
