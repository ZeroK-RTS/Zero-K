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

local CMD_INSERT = CMD.INSERT
local spValidUnitID = Spring.ValidUnitID
local spGetUnitRulesParam = Spring.GetUnitRulesParam
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)

	local numParams = #cmdParams
	if cmdID == CMD_INSERT then
		numParams = numParams - 3
		cmdParams[1] = cmdParams[4]
	end

	if numParams ~= 1 then
		return true
	end

	local targetID = cmdParams[1]
	if not spValidUnitID(targetID) or spGetUnitRulesParam(targetID, "untargetable") ~= 1 then
		return true
	end

	return false
end
