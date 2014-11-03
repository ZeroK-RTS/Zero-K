function gadget:GetInfo() return {
	name      = "Ranks API",
	desc      = "Handles unit ranks",
	author    = "jK, rewritten by Sprung",
	date      = "Nov 2014", -- "Dec 19, 2007",
	license   = "GNU GPL, v2 or later",
	layer     = -math.huge,
	enabled   = true,
} end

if not gadgetHandler:IsSyncedCode() then return end

local floor = math.floor
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam

local XP_PER_RANK = 0.2 -- change to 0.1 once lasthit bonus gets removed

Spring.SetExperienceGrade (0.0005) -- how often UnitExperience() is called (less is more often)
Spring.SetGameRulesParam ("xp_per_rank", XP_PER_RANK) 

GG.UnitRankUp = {}

function gadget:UnitCreated (unitID)
	spSetUnitRulesParam (unitID, "rank", 0)
end

function gadget:UnitExperience (unitID, unitDefID, unitTeam, newxp, oldxp)
	-- convert xp to rank
	newxp = floor (newxp / XP_PER_RANK)
	oldxp = floor (newxp / XP_PER_RANK)

	if (newxp ~= oldxp) then
		spSetUnitRulesParam (unitID, "rank", newxp)

		for _,f in pairs (GG.UnitRankUp) do
			f (unitID, unitDefID, unitTeam, newxp, oldxp)
		end
	end
end
