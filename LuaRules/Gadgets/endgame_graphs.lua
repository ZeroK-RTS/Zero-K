
if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name    = "Endgame Graphs",
		desc    = "Gathers misc stats",
		author  = "Sprung",
		date    = "2016-02-14",
		license = "PD",
		layer   = 999999,
		enabled = true,
	}
end

local unitCategoryDefs = VFS.Include("LuaRules/Configs/unit_category.lua")

local teamList = Spring.GetTeamList()
local gaiaTeamID = Spring.GetGaiaTeamID()
local allyTeamByTeam

local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitHealth = Spring.GetUnitHealth
local GetUnitCost = Spring.Utilities.GetUnitCost

local SetHiddenTeamRulesParam = Spring.Utilities.SetHiddenTeamRulesParam
local GetHiddenTeamRulesParam = Spring.Utilities.GetHiddenTeamRulesParam

local reclaimListByTeam = {}
local metalExcessByTeam = {}
local damageReceivedByTeam = {}

local unitValueByTeam = {}
local unitCategoryValueByTeam = {}
local unitValueLostByTeam = {}
local totalNanoValueByTeam = {}
local partialNanoValueByTeam = {}

-- hax disregards LoS. Mostly for gadget use (eg awards), users can see it only after game over. Mid-game they can only see nonhax.
local damageDealtByTeamHax = {}
local damageDealtByTeamNonhax = {}

local unitValueKilledByTeamHax = {}
local unitValueKilledByTeamNonhax = {}

local ALLIED_VISIBLE = {allied = true}

local spGetUnitPosition = Spring.GetUnitPosition
local spIsPosInLos = Spring.IsPosInLos
local function canTeamSeeUnit(teamID, unitID)
	local x, y, z = spGetUnitPosition(unitID)
	local allyTeamID = allyTeamByTeam[teamID]
	return spIsPosInLos(x, y, z, allyTeamID)
end

local dontCountUnits = {}
for unitDefID = 1, #UnitDefs do
	if UnitDefs[unitDefID].customParams.dontcount then
		dontCountUnits[unitDefID] = true
	end
end

local featureMetal = {}
for i = 1, #FeatureDefs do
	local featureDef = FeatureDefs[i]
	featureMetal[i] = featureDef.metal
end

function gadget:AllowFeatureBuildStep(builderID, builderTeam, featureID, featureDefID, part)
	if (part < 0) then
		reclaimListByTeam[builderTeam] = reclaimListByTeam[builderTeam] + (part * featureMetal[featureDefID])
	end
	return true
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if paralyzer then return end

	local hp, maxHP = spGetUnitHealth(unitID)
	if (hp < 0) then
		damage = damage + hp
	end

	local costdamage = (damage / maxHP) * GetUnitCost(unitID, unitDefID)

	if attackerTeam and not spAreTeamsAllied(attackerTeam, unitTeam) then
		damageDealtByTeamHax[attackerTeam] = damageDealtByTeamHax[attackerTeam] + costdamage

		if canTeamSeeUnit(attackerTeam, unitID) then
			damageDealtByTeamNonhax[attackerTeam] = damageDealtByTeamNonhax[attackerTeam] + costdamage
		end
	end
	damageReceivedByTeam[unitTeam] = damageReceivedByTeam[unitTeam] + costdamage
end

local nanoframeCount = 0
local nanoframes     = {} -- [index] = unitID
local nanoframeTeams = {} -- [index] = teamID
local nanoframeCosts = {} -- [index] = fullCost
local nanoframesByID = {} -- [unitID] = index

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if dontCountUnits[unitDefID] then
		return
	end

	local cost = GetUnitCost(unitID, unitDefID)
	nanoframeCount = nanoframeCount + 1
	nanoframeTeams[nanoframeCount] = teamID
	nanoframeCosts[nanoframeCount] = cost
	nanoframes[nanoframeCount] = unitID
	nanoframesByID[unitID] = nanoframeCount

	totalNanoValueByTeam[teamID] = totalNanoValueByTeam[teamID] + cost
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if dontCountUnits[unitDefID] then
		return
	end

	local index = nanoframesByID[unitID]
	local lastUnitID = nanoframes[nanoframeCount]
	local cost = nanoframeCosts[index]

	nanoframesByID[lastUnitID] = index
	nanoframesByID[unitID] = nil
	nanoframeTeams[index] = nanoframeTeams[nanoframeCount]
	nanoframeCosts[index] = nanoframeCosts[nanoframeCount]
	nanoframes[index] = lastUnitID
	nanoframeCount = nanoframeCount - 1

	unitValueByTeam[teamID] = unitValueByTeam[teamID] + cost
	totalNanoValueByTeam[teamID] = totalNanoValueByTeam[teamID] - cost
	
	local cat = unitCategoryDefs[unitDefID]
	if cat and unitCategoryValueByTeam[teamID][cat] then
		unitCategoryValueByTeam[teamID][cat] = unitCategoryValueByTeam[teamID][cat] + cost
	end
end

function gadget:UnitReverseBuilt(unitID, unitDefID, teamID)
	if dontCountUnits[unitDefID] then
		return
	end

	local cost = GetUnitCost(unitID, unitDefID)

	nanoframeCount = nanoframeCount + 1
	nanoframeTeams[nanoframeCount] = teamID
	nanoframeCosts[nanoframeCount] = cost
	nanoframes[nanoframeCount] = unitID
	nanoframesByID[unitID] = nanoframeCount

	totalNanoValueByTeam[teamID] = totalNanoValueByTeam[teamID] + cost
	unitValueByTeam[teamID] = unitValueByTeam[teamID] - cost
	
	local cat = unitCategoryDefs[unitDefID]
	if cat and unitCategoryValueByTeam[teamID][cat] then
		unitCategoryValueByTeam[teamID][cat] = unitCategoryValueByTeam[teamID][cat] - cost
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeam)
	if dontCountUnits[unitDefID] then
		return
	end

	local index = nanoframesByID[unitID]
	local cost
	if index then
		cost = nanoframeCosts[index]

		local lastUnitID = nanoframes[nanoframeCount]
		nanoframesByID[unitID] = nil
		nanoframesByID[lastUnitID] = index
		nanoframeTeams[index] = nanoframeTeams[nanoframeCount]
		nanoframeCosts[index] = nanoframeCosts[nanoframeCount]
		nanoframes[index] = nanoframes[nanoframeCount]
		nanoframeCount = nanoframeCount - 1

		totalNanoValueByTeam[teamID] = totalNanoValueByTeam[teamID] - cost

		local buildProgress = select(5, spGetUnitHealth(unitID))
		cost = cost * buildProgress
	else
		cost = GetUnitCost(unitID, unitDefID)
		unitValueByTeam[teamID] = unitValueByTeam[teamID] - cost
		local cat = unitCategoryDefs[unitDefID]
		if cat and unitCategoryValueByTeam[teamID][cat] then
			unitCategoryValueByTeam[teamID][cat] = unitCategoryValueByTeam[teamID][cat] - cost
		end
	end

	local morphed = Spring.GetUnitRulesParam(unitID, "wasMorphedTo")
	if morphed then
		return
	end

	unitValueLostByTeam [teamID] = unitValueLostByTeam [teamID] + cost
	if attackerTeam and not spAreTeamsAllied(attackerTeam, teamID) then
		unitValueKilledByTeamHax[attackerTeam] = unitValueKilledByTeamHax[attackerTeam] + cost
		if canTeamSeeUnit(attackerTeam, unitID) then
			unitValueKilledByTeamNonhax[attackerTeam] = unitValueKilledByTeamNonhax[attackerTeam] + cost
		end
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	if dontCountUnits[unitDefID] then
		return
	end

	local index = nanoframesByID[unitID]
	if index then
		local cost = nanoframeCosts[index]
		nanoframeTeams[index] = newTeam
		totalNanoValueByTeam[oldTeam] = totalNanoValueByTeam[oldTeam] - cost
		totalNanoValueByTeam[newTeam] = totalNanoValueByTeam[newTeam] + cost
	else
		local cost = GetUnitCost(unitID, unitDefID)
		unitValueByTeam[oldTeam] = unitValueByTeam[oldTeam] - cost
		unitValueByTeam[newTeam] = unitValueByTeam[newTeam] + cost
		
		local cat = unitCategoryDefs[unitDefID]
		if cat and unitCategoryValueByTeam[oldTeam][cat] and unitCategoryValueByTeam[newTeam][cat] then
			unitCategoryValueByTeam[oldTeam][cat] = unitCategoryValueByTeam[oldTeam][cat] - cost
			unitCategoryValueByTeam[newTeam][cat] = unitCategoryValueByTeam[newTeam][cat] + cost
		end
	end
end

local function RegenerateNanoframeValues()
	for i = 1, #teamList do
		local teamID = teamList[i]
		partialNanoValueByTeam[teamID] = 0
	end

	for i = 1, nanoframeCount do
		local unitID = nanoframes[i]
		local teamID = nanoframeTeams[i]
		local fullCost = nanoframeCosts[i]

		local buildProgress = select(5, spGetUnitHealth(unitID))
		if buildProgress then
			local cost = fullCost * buildProgress
			partialNanoValueByTeam[teamID] = partialNanoValueByTeam[teamID] + cost
		end
	end
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
local mTotalOverdrive = {}

function gadget:GameFrame(n)
	if (n % 30) ~= 0 then
		return
	end

	sum_count = sum_count + 1
	local isSpringStatsHistoryFrame = ((n % 450) == 0)
	RegenerateNanoframeValues()
	for i = 1, #teamList do
		local teamID = teamList[i]
		mIncome[teamID] = mIncome[teamID] + GetMetalIncome  (teamID)
		eIncome[teamID] = eIncome[teamID] + GetEnergyIncome (teamID)
		mIncomeBase     [teamID] = mIncomeBase     [teamID] + (Spring.GetTeamRulesParam(teamID, "OD_metalBase"     ) or 0)
		mIncomeOverdrive[teamID] = mIncomeOverdrive[teamID] + (Spring.GetTeamRulesParam(teamID, "OD_metalOverdrive") or 0)
		mTotalOverdrive[teamID] = mTotalOverdrive[teamID] + (Spring.GetTeamRulesParam(teamID, "OD_metalOverdrive") or 0)

		SetHiddenTeamRulesParam(teamID, "stats_history_damage_dealt_current", damageDealtByTeamHax[teamID])
		SetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_current", unitValueKilledByTeamHax[teamID])
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_current", damageDealtByTeamNonhax[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_current", damageReceivedByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_overdrive_current", mTotalOverdrive[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_current", -reclaimListByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_current", metalExcessByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_current", unitValueByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_army_current", unitCategoryValueByTeam[teamID].army, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_def_current", unitCategoryValueByTeam[teamID].def, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_econ_current", unitCategoryValueByTeam[teamID].econ, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_other_current", unitCategoryValueByTeam[teamID].other, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_killed_current", unitValueKilledByTeamNonhax[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_lost_current", unitValueLostByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_current", partialNanoValueByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_current", totalNanoValueByTeam[teamID], ALLIED_VISIBLE)
		
		if isSpringStatsHistoryFrame then
			SetHiddenTeamRulesParam(teamID, "stats_history_damage_dealt_"    .. stats_index, damageDealtByTeamHax[teamID])
			SetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_"    .. stats_index, unitValueKilledByTeamHax[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_"    .. stats_index, damageDealtByTeamNonhax[teamID])
			Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_" .. stats_index, damageReceivedByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_overdrive_" .. stats_index, mTotalOverdrive[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_" .. stats_index, -reclaimListByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_" .. stats_index, metalExcessByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_"  .. stats_index, mIncome[teamID] / sum_count, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_base_"  .. stats_index, mIncomeBase[teamID] / sum_count, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_od_"  .. stats_index, mIncomeOverdrive[teamID] / sum_count, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_" .. stats_index, eIncome[teamID] / sum_count, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_killed_" .. stats_index, unitValueKilledByTeamNonhax[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_lost_" .. stats_index, unitValueLostByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_" .. stats_index, unitValueByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_army_" .. stats_index, unitCategoryValueByTeam[teamID].army, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_def_" .. stats_index, unitCategoryValueByTeam[teamID].def, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_econ_" .. stats_index, unitCategoryValueByTeam[teamID].econ, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_other_" .. stats_index, unitCategoryValueByTeam[teamID].other, ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_" .. stats_index, partialNanoValueByTeam[teamID], ALLIED_VISIBLE)
			Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_" .. stats_index, totalNanoValueByTeam[teamID], ALLIED_VISIBLE)

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

function gadget:GameOver()
	gadget:GameFrame(450) -- fake history frame to snapshot end state

	Spring.SetGameRulesParam("gameover_frame", Spring.GetGameFrame())
	Spring.SetGameRulesParam("gameover_second", math.floor(Spring.GetGameSeconds()))
	Spring.SetGameRulesParam("gameover_historyframe", stats_index - 1)
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
		unitValueByTeam[teamID] = 0
		totalNanoValueByTeam[teamID] = 0
		unitCategoryValueByTeam[teamID] = {
			army = 0,
			def = 0,
			econ = 0,
			other = 0,
		}
	end

	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, unitTeam)
		local isNanoframe = select(3, Spring.GetUnitIsStunned(unitID))
		if not isNanoframe then
			gadget:UnitFinished(unitID, unitDefID, unitTeam)
		end
	end

	RegenerateNanoframeValues()

	allyTeamByTeam = {}
	for i = 1, #teamList do
		local teamID = teamList[i]
		allyTeamByTeam[teamID] = select(6, Spring.GetTeamInfo(teamID, false))

		mIncome         [teamID] = 0
		mIncomeBase     [teamID] = 0
		mIncomeOverdrive[teamID] = 0
		eIncome         [teamID] = 0

		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_current", Spring.GetTeamRulesParam(teamID, "stats_history_metal_reclaim_current") or 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_current", Spring.GetTeamRulesParam(teamID, "stats_history_metal_excess_current") or 0, ALLIED_VISIBLE)
		SetHiddenTeamRulesParam(teamID, "stats_history_damage_dealt_current", GetHiddenTeamRulesParam(teamID, "stats_history_damage_dealt_current") or 0)
		SetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_current", GetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_current") or 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_current", Spring.GetTeamRulesParam(teamID, "stats_history_damage_dealt_current") or 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_current", Spring.GetTeamRulesParam(teamID, "stats_history_damage_received_current") or 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_lost_current", Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_lost_current") or 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_killed_current", Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_killed_current") or 0, ALLIED_VISIBLE)

		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_current", unitValueByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_army_current", unitCategoryValueByTeam[teamID].army, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_def_current", unitCategoryValueByTeam[teamID].def, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_econ_current", unitCategoryValueByTeam[teamID].econ, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_other_current", unitCategoryValueByTeam[teamID].other, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_current", partialNanoValueByTeam[teamID], ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_current", totalNanoValueByTeam[teamID], ALLIED_VISIBLE)

		SetHiddenTeamRulesParam (teamID, "stats_history_damage_dealt_0"     , 0)
		SetHiddenTeamRulesParam (teamID, "stats_history_unit_value_killed_0", 0)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_dealt_0"     , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_damage_received_0"  , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_reclaim_0"    , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_excess_0"     , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_0"     , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_base_0", 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_metal_income_od_0"  , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_energy_income_0"    , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_0"       , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_army_0"  , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_def_0"   , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_econ_0"  , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_other_0" , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_killed_0", 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_unit_value_lost_0"  , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_partial_0"     , 0, ALLIED_VISIBLE)
		Spring.SetTeamRulesParam(teamID, "stats_history_nano_total_0"       , 0, ALLIED_VISIBLE)

		mTotalOverdrive     [teamID] = Spring.GetTeamRulesParam(teamID, "stats_history_metal_overdrive_current") or 0
		reclaimListByTeam   [teamID] = -Spring.GetTeamRulesParam(teamID, "stats_history_metal_reclaim_current") or 0
		metalExcessByTeam   [teamID] = Spring.GetTeamRulesParam(teamID, "stats_history_metal_excess_current") or 0
		damageDealtByTeamHax[teamID] =  GetHiddenTeamRulesParam(teamID, "stats_history_damage_dealt_current") or 0
		damageDealtByTeamNonhax[teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_damage_dealt_current") or 0
		unitValueKilledByTeamHax[teamID] =  GetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_current") or 0
		unitValueKilledByTeamNonhax[teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_killed_current") or 0
		unitValueLostByTeam[teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_unit_value_lost_current") or 0
		damageReceivedByTeam[teamID] =  Spring.GetTeamRulesParam(teamID, "stats_history_damage_received_current") or 0
	end
end
