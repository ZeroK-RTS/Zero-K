--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Solar Force Closed",
    desc      = "Forces Solars to stay closed when they are recently damaged.",
    author    = "Google Frog",
    date      = "2 June 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false
  }
end

local spGetUnitRulesParam = Spring.GetUnitRulesParam

local forceClosableUnitDefs = {}

for id, data in pairs(UnitDefs) do
	if data.customParams and data.customParams.force_close then
		forceClosableUnitDefs[id] = true
	end
end

local CMD_ONOFF = CMD.ONOFF

function gadget:AllowCommand_GetWantedCommand()
	return {[CMD_ONOFF] = true}
end
	
function gadget:AllowCommand_GetWantedUnitDefID()
	return forceClosableUnitDefs
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if unitID and cmdID == CMD_ONOFF and forceClosableUnitDefs[unitDefID] then
		local forceClosed = spGetUnitRulesParam(unitID, "force_close")
		if forceClosed and forceClosed == 1 then
			return false
		end
	end
	return true
end
