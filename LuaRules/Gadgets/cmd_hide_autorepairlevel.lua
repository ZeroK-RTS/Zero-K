--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
  return {
    name      = "Hide Autorepairlevel Command",
    desc      = "Hide Autorepairlevel because airpad repair behaviour is handled by cmd_retreat.lua widget and unit_bomber_command.lua",
    author    = "xponen",
    date      = "29 Jan 2014",
    license   = "public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local spFindUnitCmdDesc = Spring.FindUnitCmdDesc
local spEditUnitCmdDesc = Spring.EditUnitCmdDesc
local CMD_AUTOREPAIRLEVEL = CMD.AUTOREPAIRLEVEL
local hideTable = {hidden = true}

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmdDescID = spFindUnitCmdDesc(unitID, CMD_AUTOREPAIRLEVEL)
	if cmdDescID then
		spEditUnitCmdDesc(unitID, cmdDescID, hideTable)
	end
end
