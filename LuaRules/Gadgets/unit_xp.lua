if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Experience",
	desc    = "Handles unit XP",
	author  = "Sprung",
	date    = "2016",
	license = "PD",
	layer   = 0,
	enabled = true,
} end

local spGetUnitHealth = Spring.GetUnitHealth
local spValidUnitID = Spring.ValidUnitID
local spSetUnitExperience = Spring.SetUnitExperience
local spGetUnitExperience = Spring.GetUnitExperience
local getCost = Spring.Utilities.GetUnitCost
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitLosState = Spring.GetUnitLosState
local allyTeamByTeam = {}

local noXpCache = {}
local function NoXpFromUnit(unitDefID)
	if not noXpCache[unitDefID] then
		local ud = UnitDefs[unitDefID]
		noXpCache[unitDefID] = (ud.customParams.no_xp and 1) or 0
	end
	return (noXpCache[unitDefID] == 1)
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if not attackerID or not spValidUnitID(attackerID)
			or spAreTeamsAllied(unitTeam, attackerTeam)
			or paralyzer -- requires a sensible formula
			or not damage then
		return
	end

	local canAttackerSeeTarget = spGetUnitLosState(unitID, allyTeamByTeam[attackerTeam], true)
	if canAttackerSeeTarget % 2 == 0 then
		return
	end

	if NoXpFromUnit(unitDefID) then
		return
	end

	local parentID = spGetUnitRulesParam(attackerID, "parent_unit_id")
	if parentID then
		if not spValidUnitID(parentID) then
			return
		end

		attackerID = parentID
		attackerDefID = spGetUnitDefID(parentID)
	end

	local hp, maxHP = spGetUnitHealth(unitID)

	local percentageDamage = ((hp > 0) and damage or (damage + hp)) / maxHP
	local targetCost = getCost(unitID, unitDefID) * (GG.att_CostMult[unitID] or 1)
	local attackerCost = getCost(attackerID, attackerDefID)  * (GG.att_CostMult[attackerID] or 1)
	spSetUnitExperience(attackerID, spGetUnitExperience(attackerID) + percentageDamage * targetCost / attackerCost)
end

function gadget:Initialize()
	Spring.SetExperienceGrade(1.0)

	local teams = Spring.GetTeamList()
	for i = 1, #teams do
		local teamID = teams[i]
		local allyTeamID = select(6, Spring.GetTeamInfo(teamID, false))
		allyTeamByTeam[teamID] = allyTeamID
	end
end
