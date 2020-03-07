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

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)

	if not attackerID or not spValidUnitID(attackerID)
	or spAreTeamsAllied(unitTeam, attackerTeam)
	or paralyzer -- requires a sensible formula
	then
		return
	end

	local canAttackerSeeTarget = spGetUnitLosState(unitID, allyTeamByTeam[attackerTeam], true)
	if canAttackerSeeTarget % 2 == 0 then
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

	spSetUnitExperience(attackerID, spGetUnitExperience(attackerID) + ((((hp > 0) and damage or (damage + hp)) / maxHP) * getCost(unitID, unitDefID) / getCost(attackerID, attackerDefID)))
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
