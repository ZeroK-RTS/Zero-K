--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Transport Selected Load",
    desc      = "Adds the command for transport selection load.",
    author    = "GoogleFrog",
    date      = "8 May 2016",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include "LuaRules/Configs/customcmds.h.lua"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Global Variables

local loadSelectedCmd = {
    id      = CMD_LOADUNITS_SELECTED,
    name    = "Load Selected",
    action  = "loadselected",
	cursor  = 'LoadUnits',
    type    = CMDTYPE.ICON,
	tooltip = "Load selected units.",
	hidden	= true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD.LOAD_UNITS)
    if cmdDescID then
		Spring.InsertUnitCmdDesc(unitID, 502, loadSelectedCmd)
    end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_LOADUNITS_SELECTED)
    for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID)
    end
end