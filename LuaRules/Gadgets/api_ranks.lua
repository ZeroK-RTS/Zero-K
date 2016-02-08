if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Ranks API",
	desc    = "Handles unit ranks",
	author  = "jK, rewritten by Sprung",
	date    = "Nov 2014", -- original: Dec 19, 2007
	license = "GNU GPL, v2 or later",
	layer   = -math.huge,
	enabled = true,
} end

local spValidUnitID = Spring.ValidUnitID

local penalties = {}
local workToDo = false

function gadget:UnitDestroyed (unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	if (not attackerID) or Spring.AreTeamsAllied(attackerTeam, unitTeam) then 
		return 
	end
	local penalty = UnitDefs[unitDefID].power / UnitDefs[attackerDefID].power
	local xp = Spring.GetUnitExperience(attackerID) - penalty
	if xp < 0 then
		penalties[attackerID] = (penalties[attackerID] or 0) + penalty
		workToDo = true
	else
		Spring.SetUnitExperience(attackerID, xp)
	end
end

function gadget:GameFrame (n)
	if workToDo then
		for unitID, penalty in pairs(penalties) do
			if unitID and penalty and spValidUnitID(unitID) then
				Spring.SetUnitExperience(unitID, Spring.GetUnitExperience(unitID) - penalty)
				penalties[unitID] = nil
			end
		end
		workToDo = false
	end
end

function gadget:Initialize()
	Spring.SetExperienceGrade(0.0005)
end
