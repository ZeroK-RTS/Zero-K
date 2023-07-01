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


-- Global Variables
local CMD_LOADUNITS_SELECTED = Spring.Utilities.CMD.LOADUNITS_SELECTED
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

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc
local CMD_LOAD_UNITS = CMD.LOAD_UNITS

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_LOAD_UNITS)
	if cmdDescID then
		spInsertUnitCmdDesc(unitID, 502, loadSelectedCmd)
	end
end

function gadget:Initialize()
	gadgetHandler:RegisterCMDID(CMD_LOADUNITS_SELECTED)
    for _, unitID in ipairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID)
    end
end
