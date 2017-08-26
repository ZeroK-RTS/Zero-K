function gadget:GetInfo()
	return {
		name    = "Command Transfer Unit",
		desc    = "Adds a command to transfer units between teams.",
		author  = "GoogleFrog",
		date    = "8 September 2017",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true,
	}
end
include("LuaRules/Configs/customcmds.h.lua")

if gadgetHandler:IsSyncedCode() then

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Speedups

local spInsertUnitCmdDesc = Spring.InsertUnitCmdDesc

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Configuration

local transferCmdDesc = {
	id      = CMD_TRANSFER_UNIT,
	type    = CMDTYPE.NUMBER,
	name    = 'Transfer Unit',
	action  = 'transferunit',
	hidden  = true,
}

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
-- Command Handling

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions) -- Only calls for custom commands
	if not (cmdID == CMD_TRANSFER_UNIT) then
		return false
	end
	local newTeamID = cmdParams and cmdParams[1]
	if newTeamID and (teamID ~= newTeamID) and (Spring.AreTeamsAllied(teamID, newTeamID) or (teamID == Spring.GetGaiaTeamID())) then
		Spring.TransferUnit(unitID, newTeamID, teamID ~= Spring.GetGaiaTeamID())
	end
	return true, true
end

function gadget:Initialize()
	for _, unitID in pairs(Spring.GetAllUnits()) do
		gadget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	spInsertUnitCmdDesc(unitID, transferCmdDesc)
end

end
