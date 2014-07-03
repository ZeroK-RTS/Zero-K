function gadget:GetInfo()
  return {
    name      = "I Hate CMD.SET_WANTED_MAX_SPEED",
    desc      = "It ruins everything.",
    author    = "Google Frog",
    date      = "1 Sep 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = Game.version:find("91.0")  --  loaded by default?
  }
end

if not gadgetHandler:IsSyncedCode() then
	return
end

local thingsThatCMD_SET_WANTED_MAX_SPEEDBuggers = {}

for i=1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.canFly and (ud.isFighter or ud.isBomber) then
		thingsThatCMD_SET_WANTED_MAX_SPEEDBuggers[i] = true
	end
end

function gadget:AllowCommand_GetWantedCommand()	
	return {[70] = true}
end
	
function gadget:AllowCommand_GetWantedUnitDefID()	
	return true
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	--GG.UnitEcho(unitID, cmdID)
	if cmdID == 70 and thingsThatCMD_SET_WANTED_MAX_SPEEDBuggers[unitDefID] then
		return false
	end
	return true
end