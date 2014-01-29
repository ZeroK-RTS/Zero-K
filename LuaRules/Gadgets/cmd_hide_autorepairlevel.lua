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

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, team)
	local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD.AUTOREPAIRLEVEL)
	if cmdDescID then
		Spring.EditUnitCmdDesc(unitID, cmdDescID, {hidden=true,})
	end
end
else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
end