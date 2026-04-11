--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Mid-game player join",
		desc      = "Handles spawning commanders for players who join mid-game as non-spectators.",
		author    = "Licho",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 1, -- After start_unit_setup (-1)
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Track which players have already been processed to avoid double-spawns
local processedPlayers = {}

function gadget:GameStart()
	-- Seed all players present at game start so we don't try to spawn comms for them
	local playerList = Spring.GetPlayerList()
	for i = 1, #playerList do
		processedPlayers[playerList[i]] = true
	end
end

function gadget:PlayerChanged(playerID)
	if processedPlayers[playerID] then
		return
	end

	-- Only act after game has started
	if Spring.GetGameFrame() < 1 then
		return
	end

	local name, _, spectator, teamID, allyTeamID = Spring.GetPlayerInfo(playerID, false)
	if spectator then
		return
	end

	-- This is a non-spectator player who appeared after game start — spawn their commander
	processedPlayers[playerID] = true

	-- Mark as initially playing (same as player_extra_information.lua does at frame 0)
	Spring.SetPlayerRulesParam(playerID, "initiallyPlayingPlayer", 1)

	-- Schedule spawn a few frames out to let the engine finish setting up the player
	local frame = Spring.GetGameFrame() + 3
	GG.ScheduleMidGameSpawn(frame, teamID, playerID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
