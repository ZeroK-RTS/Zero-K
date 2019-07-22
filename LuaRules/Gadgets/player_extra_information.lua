--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Player extra information",
		desc      = "Provides some extra information about players.",
		author    = "GoogleFrog",
		date      = "10 July 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GameFrame(n)
	local playerlist = Spring.GetPlayerList()
	if n == 0 then
		for i = 1, #playerlist do
			local playerID = playerlist[i]
			local name, active, spectator, teamID, allyTeamID = Spring.GetPlayerInfo(playerID, false)
			
			-- Widgets have trouble telling between spectators and the resigned non-spectator who was playing with teamID 0.
			if not spectator then
				Spring.SetPlayerRulesParam(playerID, "initiallyPlayingPlayer", 1)
			end
		end
	end
	gadgetHandler:RemoveGadget()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
