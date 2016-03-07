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

local function GetTotalUnitValue (teamID)
	local totalValue = 0
	local teamUnits = Spring.GetTeamUnits(teamID)
	for i = 1, #teamUnits do
		local unitID = teamUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if not UnitDefs[unitDefID].customParams.dontcount then
			totalValue = totalValue + (Spring.Utilities.GetUnitCost(unitID, unitDefID) * select(5, Spring.GetUnitHealth(unitID)))
		end
	end
	return totalValue
end

local function GetEnergyIncome (teamID)
	return (Spring.GetTeamRulesParam(teamID, "OD_energyIncome") or 0)
end

local function GetMetalIncome (teamID)
	return (Spring.GetTeamRulesParam(teamID, "OD_metalBase") or 0)
		+ (Spring.GetTeamRulesParam(teamID, "OD_metalOverdrive") or 0)
		+ (Spring.GetTeamRulesParam(teamID, "OD_metalMisc") or 0)
end

local stats_index
local sum_count
local mIncome = {}
local eIncome = {}

function gadget:GameFrame(n)
	if ((n % 30) == 0) then
		for i = 1, #teamList do
			local teamID = teamList[i]
			mIncome[teamID] = mIncome[teamID] + GetMetalIncome  (teamID)
			eIncome[teamID] = eIncome[teamID] + GetEnergyIncome (teamID)
		end
		sum_count = sum_count + 1

		if ((n % 450) == 30) then -- Spring stats history frames
			for i = 1, #teamList do
				local teamID = teamList[i]
				Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_" .. stats_index, -reclaimListByTeam[teamID])
				Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_" .. stats_index, GetTotalUnitValue(teamID))
				Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_"  .. stats_index, mIncome[teamID] / sum_count)
				Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_" .. stats_index, eIncome[teamID] / sum_count)
				mIncome[teamID] = 0
				eIncome[teamID] = 0
			end
			sum_count = 0
			stats_index = stats_index + 1
		end
	end
end

function gadget:Initialize()
	stats_index = math.floor((Spring.GetGameFrame() + 870) / 450)
	sum_count = 0

	for i = 1, #teamList do
		local teamID = teamList[i]

		mIncome[teamID] = 0
		eIncome[teamID] = 0
		reclaimListByTeam[teamID] = -(Spring.GetTeamRulesParam(teamID, "stats_history_metal_reclaim_" .. (stats_index - 1)) or 0)

		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_0", 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_0", 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_0", 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_0", 0)
	end
end
