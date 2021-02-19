--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Unit Metal Targetting",
    desc      = "Prevents some units from firing at units that cost less than.",
    author    = "dyth68",
    date      = "20 April 2020",
    license   = "GNU GPL, v2 or later",
    layer     = -1, -- vetoes targets, so is before ones that just modify priority
    enabled   = true  --  loaded by default?
 }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spValidUnitID         = Spring.ValidUnitID
local spGetGameFrame        = Spring.GetGameFrame
local spFindUnitCmdDesc     = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc     = Spring.EditUnitCmdDesc
local spInsertUnitCmdDesc   = Spring.InsertUnitCmdDesc
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitLosState     = Spring.GetUnitLosState



local canHandleUnit = {}
local minMetalMsg = "setMinMetalForTargetting"

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Value is the default state of the command
local metalThreshholdsByUnitDefIDs = include("LuaRules/Configs/unit_targetting_metal_limit_defs.lua")

local unitMetalMin = {}
local unitDefCost = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	unitDefCost[i] = ud.cost
end

function printThing(theKey, theTable, indent)
	if indent == nil then
		indent = ""
	end
	if (type(theTable) == "table") then
		Spring.Echo(indent .. theKey .. ":")
		for a, b in pairs(theTable) do
			printThing(tostring(a), b, indent .. "  ")
		end
	else
		Spring.Echo(indent .. theKey .. ": " .. tostring(theTable))
	end
end

include("LuaRules/Configs/customcmds.h.lua")

local preventChaffShootingCmdDesc = {
	id      = CMD_MIN_METAL_TO_TARGET,
	type    = CMDTYPE.ICON_MODE,
	name    = "Min metal for kill.",
	action  = 'preventchaffshootingmetallimit',
	tooltip	= 'Enable to prevent units shooting at units which are very cheap.',
	params 	= {0, 0, 100, 300, 1000}
}

function ChaffShootingPrevention_CheckMinMetal(unitID, targetID, damage)
	Spring.Echo("Min metal check " .. tostring(Spring.GetGameFrame()))
	if not (unitID and targetID and unitMetalMin[unitID]) then
		return false
	end

	if spValidUnitID(unitID) and spValidUnitID(targetID) then
		local gameFrame = spGetGameFrame()
		local targetVisiblityState = spGetUnitLosState(targetID, Spring.GetUnitTeam(unitID), true)
		local identified = (targetVisiblityState > 2)
		Spring.Echo("testing")
		if not identified then
			Spring.Echo("Unidentified")
			return unitMetalMin[unitID] > 0
		end
		local unitDefID = spGetUnitDefID(targetID)
		Spring.Echo("testing2")
		Spring.Echo("unitID" .. tostring(unitID))
		Spring.Echo("unitDefIDAsKnown" .. tostring(unitDefIDAsKnown))
		Spring.Echo("unitDefID" .. tostring(unitDefID))
		Spring.Echo("unitMetalMin" .. tostring(unitMetalMin[unitID]))
		Spring.Echo("unitDefCost" .. tostring(unitDefCost[unitDefIDAsKnown]))
		if unitMetalMin[unitID] and unitMetalMin[unitID] > unitDefCost[unitDefID] then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Command Handling 
local function PreventFiringAtChaffToggleCommand(unitID, unitDefID, cmdParams, cmdOptions)
	if canHandleUnit[unitID] then
		local state = cmdParams[1] or 1
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_MIN_METAL_TO_TARGET)

		local newParams = {}
		if (cmdDescID) then
			for k,v in pairs(metalThreshholdsByUnitDefIDs[unitDefID]) do newParams[k] = v end
			newParams[1] = state
			preventChaffShootingCmdDesc.params = newParams
			spEditUnitCmdDesc(unitID, cmdDescID, {params = preventChaffShootingCmdDesc.params})
		end
		unitMetalMin[unitID] = metalThreshholdsByUnitDefIDs[unitDefID][state + 2]
		return false
	end
	return true
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_MIN_METAL_TO_TARGET] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if (cmdID == CMD_MIN_METAL_TO_TARGET) then
		return PreventFiringAtChaffToggleCommand(unitID, unitDefID, cmdParams, cmdOptions)
	else
		return true  -- command was not used
	end
end

--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if metalThreshholdsByUnitDefIDs[unitDefID] then
		spInsertUnitCmdDesc(unitID, preventChaffShootingCmdDesc)
		canHandleUnit[unitID] = true
		PreventFiringAtChaffToggleCommand(unitID, unitDefID, metalThreshholdsByUnitDefIDs[unitDefID])
	end
end

function gadget:UnitDestroyed(unitID)
	if canHandleUnit[unitID] then
		if unitMetalMin[unitID] then
			unitMetalMin[unitID] = nil
		end
		canHandleUnit[unitID] = nil
	end
end

function gadget:AllowWeaponTarget(unitID, targetID, attackerWeaponNum, attackerWeaponDefID, defPriority)
	if ChaffShootingPrevention_CheckMinMetal(unitID, targetID) then
		return false, defPriority
	end
	return true, defPriority
end

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_MIN_METAL_TO_TARGET)
	GG.IsUnitIdentifiedStructure = IsUnitIdentifiedStructure
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
