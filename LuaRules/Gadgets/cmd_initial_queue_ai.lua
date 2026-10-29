function gadget:GetInfo()
	return {
		name      = "Initial Queue AI relay",
		desc      = "Relays pregame initial queue messages between players and allied Skirmish AIs",
		author    = "Anarchid",
		date      = "October 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

-- Protocol. <payload> is the initial queue widget's own format, forwarded
-- verbatim: "1|unitDefID|x|y|z|face" (insert at front), "3|..." (append),
-- "4|..." (replace the queue with this item), "2|index" (remove the 1-based
-- index) or "5" (clear the queue).
--   widget -> LuaRules   "IQ|<payload>"                (Spring.SendLuaRulesMsg)
--   LuaRules -> AI       "IQ|<teamID>|<payload>"       (Spring.SendSkirmishAIMessage, allied AIs only;
--                                                       teamID is the player's, or an allied AI's, team)
--   AI -> LuaRules       "IQ|<payload>"                (AI's callLuaRules; the AI sends "5" then "3|..." per item)
--   LuaRules -> LuaRules "IQAI|<aiTeamID>|<payload>"   (rebroadcast by the AI's host so every client sees it)
--   LuaRules -> widget   IQ_FromAI(aiTeamID, payload)  (allies and spectators only)
--
-- The engine creates AIs while the game loads, before the pregame, so they
-- hear players' queue messages live and nothing needs replaying at GameStart.

local PLAYER_PREFIX = "IQ|"
local AI_PREFIX = "IQAI|"

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then

local spGetPlayerInfo = Spring.GetPlayerInfo
local spGetTeamInfo = Spring.GetTeamInfo
local spGetAIInfo = Spring.GetAIInfo

local function RelayPlayerQueue(msg, playerID)
	local _, _, spectator, teamID, allyTeamID = spGetPlayerInfo(playerID, false)
	if spectator or not teamID or not allyTeamID then
		return
	end
	SendToUnsynced("IQ_ToAI", teamID, allyTeamID, msg:sub(#PLAYER_PREFIX + 1))
end

local function RelayAIQueue(msg, playerID)
	-- "IQAI|<aiTeamID>|<payload>", sent by the AI's hosting player
	local rest = msg:sub(#AI_PREFIX + 1)
	local sep = rest:find("|", 1, true)
	if not sep then
		return
	end
	local aiTeam = tonumber(rest:sub(1, sep - 1))
	local payload = rest:sub(sep + 1)
	if not aiTeam or payload == "" then
		return
	end
	local _, _, _, isAI, _, allyTeamID = spGetTeamInfo(aiTeam, false)
	if not isAI then
		return
	end
	local _, _, hostPlayerID = spGetAIInfo(aiTeam)
	if hostPlayerID ~= playerID then
		return
	end
	if payload == "5" then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "relaying AI team " .. aiTeam .. "'s initial queue to its allies")
	end
	SendToUnsynced("IQ_FromAI", aiTeam, allyTeamID, payload)
	SendToUnsynced("IQ_ToAI", aiTeam, allyTeamID, payload) -- other allied AIs see it too
end

function gadget:RecvLuaMsg(msg, playerID)
	if type(msg) ~= "string" then
		return
	end
	if msg:sub(1, #PLAYER_PREFIX) == PLAYER_PREFIX then
		RelayPlayerQueue(msg, playerID)
	elseif msg:sub(1, #AI_PREFIX) == AI_PREFIX then
		RelayAIQueue(msg, playerID)
	end
end

function gadget:RecvSkirmishAIMessage(aiTeam, dataStr)
	-- Only the AI's host receives this; rebroadcast so every client gets it.
	if type(dataStr) ~= "string" or dataStr:sub(1, #PLAYER_PREFIX) ~= PLAYER_PREFIX then
		return
	end
	local payload = dataStr:sub(#PLAYER_PREFIX + 1)
	if payload == "" then
		return
	end
	if payload == "5" then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "AI team " .. aiTeam .. " is reporting its initial queue")
	end
	CallAsTeam(aiTeam, function()
		Spring.SendLuaRulesMsg(AI_PREFIX .. aiTeam .. "|" .. payload)
	end)
end

--------------------------------------------------------------------------------
else  -- UNSYNCED
--------------------------------------------------------------------------------

local spGetTeamList = Spring.GetTeamList
local spGetTeamInfo = Spring.GetTeamInfo
local spSendSkirmishAIMessage = Spring.SendSkirmishAIMessage

local function SendToAlliedAIs(_, sourceTeamID, allyTeamID, payload)
	-- Delivery only reaches AIs hosted on this client; the engine drops the rest.
	local teams = spGetTeamList(allyTeamID)
	if not teams then
		return
	end
	local msg = PLAYER_PREFIX .. sourceTeamID .. "|" .. payload
	for i = 1, #teams do
		local teamID = teams[i]
		if teamID ~= sourceTeamID and select(4, spGetTeamInfo(teamID, false)) then
			pcall(spSendSkirmishAIMessage, teamID, msg)
		end
	end
end

local function SendToWidget(_, aiTeam, allyTeamID, payload)
	if not (Spring.GetSpectatingState() or Spring.GetMyAllyTeamID() == allyTeamID) then
		return
	end
	if Script.LuaUI("IQ_FromAI") then
		local ok, err = pcall(Script.LuaUI.IQ_FromAI, aiTeam, payload)
		if not ok then
			Spring.Log(gadget:GetInfo().name, LOG.WARNING, "IQ_FromAI failed: " .. tostring(err))
		end
	end
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("IQ_ToAI", SendToAlliedAIs)
	gadgetHandler:AddSyncAction("IQ_FromAI", SendToWidget)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("IQ_ToAI")
	gadgetHandler:RemoveSyncAction("IQ_FromAI")
end

end
