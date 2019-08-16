--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Gunship Strafe Control",
      desc      = "Adds toggle for strafe, enables propper hold position control",
      author    = "Google Frog",
      date      = "15 Dec 2010",
      license   = "GNU GPL, v2 or later",
      layer     = 0,
      enabled   = true
   }
end

local things = "STUFFF"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end
---------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local spMoveCtrlGetTag = Spring.MoveCtrl.GetTag

local airStrafeCmdDesc = {
	id      = CMD_AIR_STRAFE,
	type    = CMDTYPE.ICON_MODE,
	name    = 'Strafe',
	action  = 'airstrafe',
	tooltip	= 'Toggles air strafing for gunships',
	params 	= {0, 'Strafe Off','Strafe On'}
}

local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local spFindUnitCmdDesc   = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc   = Spring.EditUnitCmdDesc

local strafeUnitDefs = {}

for id, data in pairs(UnitDefs) do
	if data.customParams and data.customParams.airstrafecontrol then
		strafeUnitDefs[id] = true
	end
end

local unitState = {}

--------------------------------------------------------------------------------
-- Command Handling
local function ToggleCommand(unitID, cmdParams, unitDefID)
	if unitState[unitID] and strafeUnitDefs[unitDefID] then
		local state = cmdParams[1]
		local cmdDescID = spFindUnitCmdDesc(unitID, CMD_AIR_STRAFE)
		
		if (cmdDescID) then
			airStrafeCmdDesc.params[1] = state
			spEditUnitCmdDesc(unitID, cmdDescID, { params = airStrafeCmdDesc.params})
		end
		unitState[unitID].active = (state == 1)
        Spring.MoveCtrl.SetGunshipMoveTypeData(unitID, {airStrafe = unitState[unitID].active})
	end
	
end

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_AIR_STRAFE] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	
	if (cmdID ~= CMD_AIR_STRAFE) then
		return true  -- command was not used
	end
	if spMoveCtrlGetTag(unitID) == nil then
		ToggleCommand(unitID, cmdParams, unitDefID)
	end
	return false  -- command was used
end

--------------------------------------------------------------------------------
-- Unit adding/removal

function gadget:Initialize()
	-- register command
	gadgetHandler:RegisterCMDID(CMD_AIR_STRAFE)
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    local ud = UnitDefs[unitDefID]
    if ud and strafeUnitDefs[unitDefID] then
        unitState[unitID] = {active = ud.airStrafe}
        spInsertUnitCmdDesc(unitID, airStrafeCmdDesc)
        if unitState[unitID].active then
            ToggleCommand(unitID, {1}, unitDefID)
        end
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
    unitState[unitID] = nil
end
