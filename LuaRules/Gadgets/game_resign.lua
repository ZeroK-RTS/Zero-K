--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Resign Gadget",
		desc      = "Resign stuff",
		author    = "KingRaptor",
		date      = "2012.5.1",
		license   = "Public domain",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- synced
--------------------------------------------------------------------------------

function gadget:RecvLuaMsg(msg, playerID)
	if msg == "forceresign" then
		local team = select(4, Spring.GetPlayerInfo(playerID))
		Spring.KillTeam(team)
		Spring.SetTeamRulesParam(team, "WasKilled", 1)
	end
end

else
--------------------------------------------------------------------------------
-- unsynced
--------------------------------------------------------------------------------

local function Resign(_, name)
	local playerID = Spring.GetMyPlayerID()
	local myName = Spring.GetPlayerInfo(playerID)
	if name == myName then
		--Spring.SendCommands('spectator')
		Spring.SendLuaRulesMsg("forceresign")
	end
end

function gadget:Initialize()
	gadgetHandler:AddChatAction('resignteam', Resign, " resigns the player with the specified name")
end

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
