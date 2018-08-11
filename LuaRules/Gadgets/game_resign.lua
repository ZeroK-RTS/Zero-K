function gadget:GetInfo() return {
	name    = "Resign Gadget",
	desc    = "Resign stuff",
	author  = "KingRaptor",
	date    = "2012.5.1",
	license = "Public domain",
	layer   = 0,
	enabled = true,
} end

if (not gadgetHandler:IsSyncedCode()) then return end

local spGetPlayerInfo = Spring.GetPlayerInfo
local spKillTeam = Spring.KillTeam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetPlayerList = Spring.GetPlayerList

function gadget:RecvLuaMsg (msg, playerID)
	if msg ~= "forceresign"
	or Spring.GetGameFrame() <= 0 -- causes dedi server to think the game is over (apparently)
	or Spring.GetPlayerRulesParam(playerID, "initiallyPlayingPlayer") ~= 1
	then
		return
	end

	local _, _, spec, teamID = spGetPlayerInfo(playerID)
	if spec or #spGetPlayerList(teamID) > 1 then -- don't kill the entire squad until the last member resigns
		return
	end

	spKillTeam(teamID)
	spSetTeamRulesParam(teamID, "WasKilled", 1)
end

function gadget:GotChatMsg (msg, senderID)
	if Spring.GetGameFrame() <= 0 then
		return
	end
	if (string.find(msg, "resignteam") == 1) then

		local allowed = false
		if (senderID == 255) then -- Springie
			allowed = true
		else
			local playerkeys = select (10, spGetPlayerInfo(senderID))
			if (playerkeys and playerkeys.admin and (playerkeys.admin == "1")) then
				allowed = true
			end
		end
		if not allowed then return end

		local target = string.sub(msg, 12)
		local people = spGetPlayerList()
		for i = 1, #people do
			local personID = people[i]
			local nick, _, _, teamID = spGetPlayerInfo(personID)
			if (target == nick) then
				spKillTeam (teamID)
				spSetTeamRulesParam (teamID, "WasKilled", 1)
				return
			end
		end
	end
end
