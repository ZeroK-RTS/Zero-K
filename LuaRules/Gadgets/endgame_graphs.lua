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
local gaiaTeamID = Spring.GetGaiaTeamID()

local AreTeamsAllied = Spring.AreTeamsAllied
local GetUnitHealth = Spring.GetUnitHealth
local GetUnitCost = Spring.Utilities.GetUnitCost

local reclaimListByTeam = {}
local damageDealtByTeam = {}
local metalExcessByTeam = {}
local damageReceivedByTeam = {}

local dontCountUnits = {}
for unitDefID = 1, #UnitDefs do
	if UnitDefs[unitDefID].customParams.dontcount then
		dontCountUnits[unitDefID] = true
	end
end

function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	if (part < 0) then
		reclaimListByTeam[builderTeam] = reclaimListByTeam[builderTeam] + (part * FeatureDefs[featureDefID].metal)
	end
	return true
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then return end

	local hp, maxHP = GetUnitHealth(unitID)
	if (hp < 0) then
		damage = damage + hp
	end

	local costdamage = (damage / maxHP) * GetUnitCost(unitID, unitDefID)

	if attackerTeam and not AreTeamsAllied(attackerTeam, unitTeam) then
		damageDealtByTeam[attackerTeam] = damageDealtByTeam[attackerTeam] + costdamage
	end
	damageReceivedByTeam[unitTeam] = damageReceivedByTeam[unitTeam] + costdamage
end

local finishedUnits = {}
function gadget:UnitFinished(unitID)
	finishedUnits[unitID] = true
end
function gadget:UnitReverseBuilt(unitID)
	finishedUnits[unitID] = nil
end
function gadget:UnitDestroyed(unitID)
	finishedUnits[unitID] = nil
end

local function GetTotalUnitValue (teamID)
	local finished, nanoPartial, nanoTotal = 0, 0, 0
	local teamUnits = Spring.GetTeamUnits(teamID)
	for i = 1, #teamUnits do
		local unitID = teamUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if not dontCountUnits[unitDefID] then
			local cost = Spring.Utilities.GetUnitCost(unitID, unitDefID)
			if finishedUnits[unitID] then
				finished = finished + cost
			else
				local buildProgress = select(5, Spring.GetUnitHealth(unitID))
				nanoPartial = nanoPartial + cost * buildProgress
				nanoTotal = nanoTotal + cost
			end
		end
	end

	-- things to consider: handle stockpile, morph, facplop?

	return finished, nanoPartial, nanoTotal
end

local function GetEnergyIncome (teamID)
	return (select(4, Spring.GetTeamResources(teamID, "energy")) or 0) + 
		(Spring.GetTeamRulesParam(teamID, "OD_energyIncome") or 0) - 
		math.max(0, (Spring.GetTeamRulesParam(teamID, "OD_energyChange") or 0))
end

local function GetMetalIncome (teamID)
	return (select(4, Spring.GetTeamResources(teamID, "metal")) or 0)
end

local stats_index
local sum_count
local mIncome = {}
local eIncome = {}
local mIncomeBase = {}
local mIncomeOverdrive = {}

function gadget:GameFrame(n)
	if (n % 30) ~= 0 then
		return
	end

	sum_count = sum_count + 1
	local isSpringStatsHistoryFrame = ((n % 450) == 0)
	for i = 1, #teamList do
		local teamID = teamList[i]
		mIncome[teamID] = mIncome[teamID] + GetMetalIncome  (teamID)
		eIncome[teamID] = eIncome[teamID] + GetEnergyIncome (teamID)
		mIncomeBase     [teamID] = mIncomeBase     [teamID] + (Spring.GetTeamRulesParam(teamID, "OD_metalBase"     ) or 0)
		mIncomeOverdrive[teamID] = mIncomeOverdrive[teamID] + (Spring.GetTeamRulesParam(teamID, "OD_metalOverdrive") or 0)
		local liveValue, nanoPartial, nanoTotal = GetTotalUnitValue(teamID)

		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_current", damageDealtByTeam[teamID])
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_current", damageReceivedByTeam[teamID])
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_current", -reclaimListByTeam[teamID])
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_current", metalExcessByTeam[teamID])
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_current", liveValue)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_current", nanoPartial)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_current", nanoTotal)
		
		if isSpringStatsHistoryFrame then
			Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_"    .. stats_index, damageDealtByTeam[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_" .. stats_index, damageReceivedByTeam[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_" .. stats_index, -reclaimListByTeam[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_" .. stats_index, metalExcessByTeam[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_"  .. stats_index, mIncome[teamID] / sum_count)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_base_"  .. stats_index, mIncomeBase[teamID] / sum_count)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_od_"  .. stats_index, mIncomeOverdrive[teamID] / sum_count)
			Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_" .. stats_index, eIncome[teamID] / sum_count)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_" .. stats_index, liveValue)
			Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_" .. stats_index, nanoPartial)
			Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_" .. stats_index, nanoTotal)

			mIncome         [teamID] = 0
			mIncomeBase     [teamID] = 0
			mIncomeOverdrive[teamID] = 0
			eIncome         [teamID] = 0
		end
	end

	if isSpringStatsHistoryFrame then
		sum_count = 0
		stats_index = stats_index + 1
	end
end


local externalFunctions = {}

function externalFunctions.AddTeamMetalExcess(teamID, metalExcess)
	metalExcessByTeam[teamID] = metalExcessByTeam[teamID] + metalExcess
end

function gadget:Initialize()
	stats_index = math.ceil(Spring.GetGameFrame() / 450) + 1
	sum_count = 0
	
	GG.EndgameGraphs = externalFunctions

	for i = 1, #teamList do
		local teamID = teamList[i]

		mIncome         [teamID] = 0
		mIncomeBase     [teamID] = 0
		mIncomeOverdrive[teamID] = 0
		eIncome         [teamID] = 0

		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_current", Spring.GetTeamRulesParam(teamID, "stats_history_metal_reclaim_current") or 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_current", Spring.GetTeamRulesParam(teamID, "stats_history_metal_excess_current") or 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_current", Spring.GetTeamRulesParam(teamID, "stats_history_damage_dealt_current") or 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_current", Spring.GetTeamRulesParam(teamID, "stats_history_damage_received_current") or 0)
		
		local liveValue, nanoPartial, nanoTotal = GetTotalUnitValue(teamID)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_current", liveValue)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_current", nanoPartial)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_current", nanoTotal)

		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_0"     , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_0"  , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_0"    , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_0"     , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_0"     , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_base_0", 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_od_0"  , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_0"    , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_0"       , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_0"     , 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_0"       , 0)

		reclaimListByTeam   [teamID] = -Spring.GetTeamRulesParam(teamID, "stats_history_metal_reclaim_current")
		metalExcessByTeam   [teamID] = Spring.GetTeamRulesParam(teamID, "stats_history_metal_excess_current")
		damageDealtByTeam   [teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_damage_dealt_current")
		damageReceivedByTeam[teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_damage_received_current")
	end
end
