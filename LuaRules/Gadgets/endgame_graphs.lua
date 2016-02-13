if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Endgame Graphs",
	desc    = "Gathers misc stats",
	author  = "Sprung",
	date    = "2016-02-14",
	license = "PD",
	layer   = 999999,
	enabled = true,
} end

local teamList = Spring.GetTeamList()
local reclaimListByTeam = {}

function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	if (part < 0) then
		reclaimListByTeam[builderTeam] = reclaimListByTeam[builderTeam] + (part * FeatureDefs[featureDefID].metal)
	end
	return true
end

local stats_index = 1
function gadget:GameFrame(n)
	if ((n % 450) == 30) then -- Spring stats history frames
		local reclaimStr = "stats_history_reclaim_" .. stats_index
		for i = 1, #teamList do
			local team = teamList[i]
			Spring.SetTeamRulesParam(team, reclaimStr, -reclaimListByTeam[team])
		end
		stats_index = stats_index + 1
	end
end

function gadget:Initialize()
	for i = 1, #teamList do
		local team = teamList[i]
		reclaimListByTeam[team] = 0
		Spring.SetTeamRulesParam(team, "stats_history_reclaim_0", 0)
	end
end
