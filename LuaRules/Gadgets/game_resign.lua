function gadget:GetInfo() return {
	name    = "Resign Gadget",
	desc    = "Resign stuff",
	author  = "KingRaptor",
	date    = "2012.5.1",
	license = "Public domain",
	layer   = 0,
	enabled = true,
} end

if (not gadgetHandler:IsSyncedCode()) then 
	return 
end

local spGetPlayerInfo = Spring.GetPlayerInfo
local spKillTeam = Spring.KillTeam
local spSetTeamRulesParam = Spring.SetTeamRulesParam
local spGetPlayerList = Spring.GetPlayerList

local function ResignTeam(teamID)
	spKillTeam(teamID)
	spSetTeamRulesParam(teamID, "WasKilled", 1)
end

local function ResignAllyTeam(allyTeamID)
	for i, teamID in pairs (Spring.GetTeamList(allyTeamID)) do
		ResignTeam (teamID)
	end
end

function gadget:Initialize()
	GG.ResignTeam = ResignTeam
	GG.ResignAllyTeam = ResignAllyTeam
end

function gadget:RecvLuaMsg (msg, playerID)
	if msg ~= "forceresign"
	or Spring.GetGameFrame() <= 0 -- causes dedi server to think the game is over (apparently)
	or Spring.GetPlayerRulesParam(playerID, "initiallyPlayingPlayer") ~= 1
	then
		return
	end

	local _, _, spec, teamID = spGetPlayerInfo(playerID, false)
	if spec or #spGetPlayerList(teamID) > 1 then -- don't kill the entire squad until the last member resigns
		return
	end

	ResignTeam(teamID)
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
			local nick, _, isSpectator, teamID = spGetPlayerInfo(personID, false)
			if target == nick and not isSpectator then
				local commshareID = Spring.GetPlayerRulesParam(personID, "commshare_orig_teamid")
				if commshareID then -- we're commshared.
					--Spring.Echo("Unmerging squaddie")
					GG.UnmergePlayerFromCommshare(personID)
					ResignTeam(commshareID)
				elseif #Spring.GetPlayerList(teamID) > 1 then -- check to make sure there aren't other people on the team.
					GG.UnmergePlayerFromCommshare(personID) -- this can happen if we're the team leader.
					ResignTeam(teamID)
				else -- we're a nobody, just resign us.
					ResignTeam (teamID)
				end
				return
			elseif target == nick and isSpectator then
				--Spring.Echo("Attempted to force resign a spectator!")
				return
			end
		end
	end
end
