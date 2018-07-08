if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name     = "Backup allyteam names",
	layer    = math.huge, -- last so that we only cover up holes; actual names are set by startbox handler (MP) or mission handlers (SP)
	enabled  = true,
} end

function gadget:Initialize()
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		if not Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID) then
			Spring.SetGameRulesParam("allyteam_short_name_" .. allyTeamID, "Team " .. allyTeamID)
			Spring.SetGameRulesParam("allyteam_long_name_"  .. allyTeamID, "Team " .. allyTeamID)
		end
	end
end
