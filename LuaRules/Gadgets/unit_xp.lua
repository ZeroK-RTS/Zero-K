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

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
	if (attackerID and spValidUnitID(attackerID) and (not Spring.AreTeamsAllied(unitTeam, attackerTeam))) then

		if paralyzer then return end -- for now, no XP for status effects. Figure out a sensible formula later.

		local parentID = Spring.GetUnitRulesParam(attackerID, "parent_unit_id")
		if parentID then
			if spValidUnitID(parentID) then
				attackerID = parentID
				attackerDefID = Spring.GetUnitDefID(parentID)
			else
				return
			end
		end

		local hp, maxHP = spGetUnitHealth(unitID)
		spSetUnitExperience(attackerID, spGetUnitExperience(attackerID) + ((((hp > 0) and damage or (damage + hp)) / maxHP) * getCost(unitID, unitDefID) / getCost(attackerID, attackerDefID)))
	end
end
