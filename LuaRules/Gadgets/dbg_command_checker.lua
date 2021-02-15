
function gadget:GetInfo()
	return {
		name      = "Dev Command Checker",
		desc      = "Checks sent commands",
		author    = "GoogleFrog",
		date      = "11 Nov 2019",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge + 1,
		enabled   = true,  --  loaded by default?
		handler   = true,
	}
end


if (not gadgetHandler:IsSyncedCode()) then
	return
end

local spIsCheatingEnabled = Spring.IsCheatingEnabled

local lightCheckEnabled = false
local heavyCheckEnabled = false
local fullCheckEnabled = false
local commandsfromPlayerID = {}
local playerName = {}

local function LightCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	
	lightCheckEnabled = not lightCheckEnabled
	Spring.Echo("Light Command Checker " .. ((lightCheckEnabled and "Enabled.") or "Disabled."))
end

local function HeavyCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	
	if words[1] and tonumber(words[1]) then
		local frame = math.abs(tonumber(words[1]) or 1)
		heavyCheckEnabled = frame
		Spring.Echo("Heavy Command Checker set to frame " .. heavyCheckEnabled)
	else
		heavyCheckEnabled = false
		Spring.Echo("Heavy Command Checker Disabled (send frame parameter).")
	end
end

local function PlayerDetailedCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	
	if words[1] and tonumber(words[1]) then
		local frame = math.abs(tonumber(words[1]) or 1)
		fullCheckEnabled = frame
		Spring.Echo("Player Command Checker set to playerID " .. fullCheckEnabled)
	else
		fullCheckEnabled = false
		Spring.Echo("Player Command Checker Disabled (send playerID parameter).")
	end
end

local function ResetCheck(cmd, line, words, player)
	if not spIsCheatingEnabled() then
		return
	end
	commandsfromPlayerID = {}
	Spring.Echo("Checker count reset.")
end

local SIZE_LIMIT = 10^8
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, playerID, fromSynced, fromLua)
	if heavyCheckEnabled and Spring.GetGameFrame() >= heavyCheckEnabled then
		if not playerName[playerID] then
			playerName[playerID] = Spring.GetPlayerInfo(playerID) or ("playerID_" .. playerID)
		end
		Spring.Utilities.UnitEcho(unitID, cmdID)
		commandsfromPlayerID[playerID] = (commandsfromPlayerID[playerID] or 0) + 1
		Spring.Echo("T", teamID, "C", cmdID, "A", (cmdParams and #cmdParams) or 0, "P", playerName[playerID], "ID", playerID, "S", fromSynced, "L", fromLua, "N", commandsfromPlayerID[playerID])
		for i = 1, #cmdParams do
			Spring.Echo("Param", i, cmdParams[i], cmdParams[i] < -SIZE_LIMIT or cmdParams[i] > SIZE_LIMIT)
		end
		if fullCheckEnabled and playerID == fullCheckEnabled then
			Spring.Utilities.TableEcho(cmdOptions, "cmdOptions")
			if #cmdParams >= 3 then
				Spring.MarkerAddPoint(cmdParams[1], cmdParams[2], cmdParams[3], cmdID)
				local ux, uy, uz = Spring.GetUnitPosition(unitID)
				if ux then
					Spring.MarkerAddLine(ux, uy, uz, cmdParams[1], cmdParams[2], cmdParams[3])
				end
			end
		end
	elseif lightCheckEnabled then
		if not playerName[playerID] then
			playerName[playerID] = Spring.GetPlayerInfo(playerID) or ("playerID_" .. playerID)
		end
		commandsfromPlayerID[playerID] = (commandsfromPlayerID[playerID] or 0) + 1
		Spring.Echo("T", teamID, "C", cmdID, "A", cmdParams and #cmdParams, "P", playerName[playerID], "ID", playerID, "S", fromSynced, "L", fromLua, "N", commandsfromPlayerID[playerID])
	end
	return true
end

function gadget:Initialize()
	gadgetHandler.actionHandler.AddChatAction(self, "cmdl", LightCheck, "LightCheck")
	gadgetHandler.actionHandler.AddChatAction(self, "cmdh", HeavyCheck, "LightCheck")
	gadgetHandler.actionHandler.AddChatAction(self, "cmdp", PlayerDetailedCheck, "LightCheck")
	gadgetHandler.actionHandler.AddChatAction(self, "cmdr", ResetCheck, "LightCheck")
end
