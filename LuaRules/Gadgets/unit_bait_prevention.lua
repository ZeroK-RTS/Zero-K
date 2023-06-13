--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Bait Prevention",
		desc      = "Prevents some units from Idle-firing or Move-firing at low value targets.",
		author    = "dyth68 and GoogleFrog",
		date      = "20 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = -1, -- vetoes targets, so is before ones that just modify priority
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spValidUnitID         = Spring.ValidUnitID
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitDefID        = Spring.GetUnitDefID

local debugBait = false

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Value is the default state of the command
local baitPreventionDefaults, targetBaitLevelDefs, targetBaitLevelArmorDefs, targetCostDefs, baitLevelCosts = include("LuaRules/Configs/bait_prevention_defs.lua")

local unitBaitLevel = {}

local CMD_PREVENT_BAIT = Spring.Utilities.CMD.PREVENT_BAIT

local preventChaffShootingCmdDesc = {
	id      = CMD_PREVENT_BAIT,
	type    = CMDTYPE.ICON_MODE,
	name    = "Prevent Bait.",
	action  = 'preventbait',
	tooltip = 'Enable to prevent units shooting at cheap targets.',
	params  = {0, 0, 35, 90, 240, 420}
}

function ChaffShootingBlock(unitID, targetID)
	if debugBait then
		Spring.Echo("==== BAIT CHECK ====", Spring.GetGameFrame(), unitID, targetID)
		Spring.Utilities.UnitEcho(unitID)
	end
	if not (unitID and targetID and unitBaitLevel[unitID] and unitBaitLevel[unitID] ~= 0) then
		return false
	end

	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local targetVisiblityState = GG.cache_GetUnitVisibility(targetID, Spring.GetUnitAllyTeam(unitID))
		--Spring.Utilities.UnitEcho(targetID, targetVisiblityState)
		local identified = (targetVisiblityState >= 1)
		if debugBait then
			Spring.Echo("identified", identified)
		end
		if not identified then
			-- Ignore radar dots at the 100 cost threshold.
			return (unitBaitLevel[unitID] >= 2)
		end
		local targetDefID = spGetUnitDefID(targetID)
		if not targetDefID then
			return false
		end
		if debugBait then
			Spring.Utilities.UnitEcho(unitID)
			Spring.Utilities.UnitEcho(targetID)
			Spring.Echo("targetDefID", targetDefID)
			Spring.Echo("unitBaitLevel", unitBaitLevel[unitID])
			Spring.Echo("targetBaitLevelDefs", targetBaitLevelDefs[targetDefID])
			Spring.Echo("targetBaitLevelArmorDefs", targetBaitLevelArmorDefs[targetDefID])
		end
		-- (targetBaitLevelDefs[targetDefID] == nil) is normal for units that cost more than 600.
		if targetBaitLevelDefs[targetDefID] and unitBaitLevel[unitID] >= targetBaitLevelDefs[targetDefID] then
			return true
		end
		if targetBaitLevelArmorDefs[targetDefID] and unitBaitLevel[unitID] >= targetBaitLevelArmorDefs[targetDefID] then
			local targetInLoS = (targetVisiblityState >= 2)
			if not targetInLoS then
				return true
			end
			local armored, armorMultiple = Spring.GetUnitArmored(targetID)
			return (armored and true) or false
		end
		local progress = GG.cache_GetUnitStunnedOrInBuild(targetID, true)
		if progress and progress < 1 then
			if targetCostDefs[targetDefID] * progress <= baitLevelCosts[unitBaitLevel[unitID]] then
				return true
			end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Command Handling

local function PreventFiringAtChaffToggleCommand(unitID, unitDefID, state, cmdOptions)
	if unitBaitLevel[unitID] then
		local state = state or 1
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_PREVENT_BAIT)
		if cmdOptions and cmdOptions.right then
			state = (state - 2)%5
		end
		if (cmdDescID) then
			preventChaffShootingCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, {params = preventChaffShootingCmdDesc.params})
		end
		
		unitBaitLevel[unitID] = state
	end
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_PREVENT_BAIT] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_PREVENT_BAIT) then
		PreventFiringAtChaffToggleCommand(unitID, unitDefID, cmdParams[1], cmdOptions)
		return false -- command was used
	end
	return true  -- command was not used
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if baitPreventionDefaults[unitDefID] then
		-- The gadget sets a default of zero for compatibility with AIs and other uncontrolled units.
		-- Widget space or the AI interface is responsible for turning this behaviour on.
		unitBaitLevel[unitID] = 0
		preventChaffShootingCmdDesc.params[1] = 0
		spInsertUnitCmdDesc(unitID, preventChaffShootingCmdDesc)
	end
end

function gadget:UnitDestroyed(unitID)
	unitBaitLevel[unitID] = nil
end

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	if ChaffShootingBlock(unitID, targetID) then
		return false, defPriority
	end
	return true, defPriority
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ToggleDebugBait(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	debugBait = not debugBait
	Spring.Echo("Debug Bait", debugBait)
end

local function PrintBait(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if targetBaitLevelDefs[unitDefID] then
			local ud = UnitDefs[unitDefID]
			local str = targetBaitLevelDefs[unitDefID]
			if ud.customParams.bait_level_target then
				str = str .. "(" .. ud.customParams.bait_level_target .. ")"
			end
			Spring.Utilities.UnitEcho(unitID, str)
		end
	end
end

function GG.baitPrevention_GetLevel(unitID)
	return unitID and unitBaitLevel[unitID]
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_PREVENT_BAIT)
	gadgetHandler:AddChatAction("debugbait", ToggleDebugBait, "")
	gadgetHandler:AddChatAction("printbait", PrintBait, "")

	GG.baitPrevention_ChaffShootingBlock = ChaffShootingBlock

	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
