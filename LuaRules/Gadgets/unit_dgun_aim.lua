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

-- TODO: remove in 85.0
local cmd = CMD.MANUALFIRE or CMD.DGUN

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmd = spFindUnitCmdDesc(unitID, cmd)
	local desc = {
		type = CMDTYPE.ICON_UNIT_OR_MAP,
	}
	if cmd then spEditUnitCmdDesc(unitID, cmd, desc) end
end