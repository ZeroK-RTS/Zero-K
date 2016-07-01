--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name = "Disallow unit for command targeting",
		desc = "Forbid all commands from targeting specific units",
		author = "Anarchid",
		date = "1.07.2016",
		license = "Public domain",
		layer = 21,
		enabled = true
	}
end

function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
    if(#cmdParams == 1) then
        local id = cmdParams[1]
        if Spring.ValidUnitID(id) and Spring.GetUnitRulesParam(id,"untargetable") == 1 then
            return false
        end
    end
    return true;
end
