if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name     = "Backup allyteam names",
		layer    = math.huge, -- last so that we only cover up holes; actual names are set by startbox handler (MP) or mission handlers (SP)
		enabled  = true,
	}
end

local PUBLIC_VISIBLE = {public = true}

function gadget:Initialize()
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		if not Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID) then
			Spring.SetGameRulesParam("allyteam_short_name_" .. allyTeamID, "Team " .. allyTeamID)
			Spring.SetGameRulesParam("allyteam_long_name_"  .. allyTeamID, "Team " .. allyTeamID)
		end
	end
	
	if Spring.GetGameFrame() < 1 then
		local teamList = Spring.GetTeamList()
		for i = 1, #teamList do
			local teamID = teamList[i]
			local _, leaderID, isDead, isAiTeam, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
			if leaderID >= 0 then
				leaderID = Spring.SetTeamRulesParam(teamID, "initLeaderID", leaderID, PUBLIC_VISIBLE)
			end
		end
	end
end
