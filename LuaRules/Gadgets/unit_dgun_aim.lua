--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "D-Gun Aim Fix",
    desc      = 'Makes d-guns aim at units instead of the ground',
    author    = "KingRaptor",
    date      = "10 April 2011",
    license   = "Public Domain",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local CMD_MANUALFIRE = CMD.MANUALFIRE
local descIconUnitOrMap = { type = CMDTYPE.ICON_UNIT_OR_MAP }

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmd = spFindUnitCmdDesc(unitID, CMD_MANUALFIRE)
	if cmd then spEditUnitCmdDesc(unitID, cmd, descIconUnitOrMap) end
end
