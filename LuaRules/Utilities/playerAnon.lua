Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.PlayerCanSeeOtherPlayerThroughAnon(seeingPlayerID, observedPlayerID)
	-- Players can only see members of their own allyteam (they cannot see specs)
	-- Spectators can see everyone
	return true -- Todo
end

function Spring.Utilities.GetAnonName(playerID)
	local _, _, spec = Spring.GetPlayerInfo(playerID)
	if spec then
		return "Spectator " .. playerID
	end
	return "Opponent " .. playerID
end