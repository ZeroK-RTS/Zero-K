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

-- Protocol. <payload> is the initial queue widget's own format:
-- "1|unitDefID|x|y|z|face" (insert at front), "3|..." (append), "4|..."
-- (replace the queue with this item), "6|...|index" (insert at the 1-based
-- index), "2|index" (remove the 1-based index) or "5" (clear the queue).
-- Synced code parses every payload it receives and passes on only a copy
-- rebuilt from the parsed numbers (SanitizePayload); anything else is dropped.
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
local IsValidPosition = Spring.Utilities.IsValidPosition
local ExplodeString = Spring.Utilities.ExplodeString

local MAX_PAYLOAD_LENGTH = 64 -- real payloads are under 40 characters
local MAX_QUEUE_INDEX = 100 -- the widget keeps at most 30 items (its MAX_QUEUE)

local aiAllyTeam = {} -- [teamID] = allyTeamID, for each Skirmish AI team
do
	local teams = Spring.GetTeamList()
	for i = 1, #teams do
		local _, _, _, isAI, _, allyTeamID = spGetTeamInfo(teams[i], false)
		if isAI then
			aiAllyTeam[teams[i]] = allyTeamID
		end
	end
end

local function IsQueueIndex(n)
	return n and n >= 1 and n <= MAX_QUEUE_INDEX and n % 1 == 0
end

-- Returns the payload rebuilt from its parsed fields, or nil unless it is a
-- well-formed queue message: a known type, an existing unit def, a position on
-- the map, a facing of 0-3 and a whole queue index.
local function SanitizePayload(payload)
	if #payload > MAX_PAYLOAD_LENGTH then
		return
	end
	local fields = ExplodeString("|", payload)
	local kind = tonumber(fields[1])
	if kind == 5 then
		return "5"
	elseif kind == 2 then
		local index = tonumber(fields[2])
		return IsQueueIndex(index) and ("2|" .. index) or nil
	elseif kind ~= 1 and kind ~= 3 and kind ~= 4 and kind ~= 6 then
		return
	end
	local unitDefID, x, y, z, face = tonumber(fields[2]), tonumber(fields[3]), tonumber(fields[4]), tonumber(fields[5]), tonumber(fields[6])
	if not (unitDefID and UnitDefs[unitDefID] and IsValidPosition(x, z) and y and math.abs(y) < 100000
			and (face == 0 or face == 1 or face == 2 or face == 3)) then
		return
	end
	local msg = string.format("%d|%d|%d|%d|%d|%d", kind, unitDefID, x, y, z, face)
	if kind == 6 then
		local index = tonumber(fields[7])
		if not IsQueueIndex(index) then
			return
		end
		msg = msg .. "|" .. index
	end
	return msg
end

local function RelayPlayerQueue(msg, playerID)
	local _, _, spectator, teamID, allyTeamID = spGetPlayerInfo(playerID, false)
	if spectator or not teamID or not allyTeamID then
		return
	end
	local payload = SanitizePayload(msg:sub(#PLAYER_PREFIX + 1))
	if payload then
		SendToUnsynced("IQ_ToAI", teamID, allyTeamID, payload)
	end
end

local function RelayAIQueue(msg, playerID)
	-- "IQAI|<aiTeamID>|<payload>", sent by the AI's hosting player
	local rest = msg:sub(#AI_PREFIX + 1)
	local sep = rest:find("|", 1, true)
	if not sep then
		return
	end
	local aiTeam = tonumber(rest:sub(1, sep - 1))
	local allyTeamID = aiTeam and aiAllyTeam[aiTeam]
	local payload = SanitizePayload(rest:sub(sep + 1))
	if not (allyTeamID and payload) then
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
	local payload = SanitizePayload(dataStr:sub(#PLAYER_PREFIX + 1))
	if not payload then
		return
	end
	if payload == "5" then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "AI team " .. aiTeam .. " is reporting its initial queue")
	end
	Spring.SendLuaRulesMsg(AI_PREFIX .. aiTeam .. "|" .. payload)
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
			spSendSkirmishAIMessage(teamID, msg)
		end
	end
end

local function SendToWidget(_, aiTeam, allyTeamID, payload)
	if not (Spring.GetSpectatingState() or Spring.GetMyAllyTeamID() == allyTeamID) then
		return
	end
	Script.LuaUI.IQ_FromAI(aiTeam, payload) -- a no-op when the widget is off
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
