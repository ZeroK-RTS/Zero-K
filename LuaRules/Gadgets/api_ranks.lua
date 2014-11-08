function gadget:GetInfo() return {
	name      = "Ranks API",
	desc      = "Handles unit ranks",
	author    = "jK, rewritten by Sprung",
	date      = "Nov 2014", -- original: Dec 19, 2007
	license   = "GNU GPL, v2 or later",
	layer     = -math.huge,
	enabled   = true,
} end

local XP_PER_RANK = 0.2 -- change to 0.1 once lasthit bonus gets removed

local floor = math.floor

if gadgetHandler:IsSyncedCode() then

	local spSetUnitRulesParam = Spring.SetUnitRulesParam

	Spring.SetExperienceGrade (0.0005) -- UnitExperience call frequency (less = more often)
	Spring.SetGameRulesParam ("xp_per_rank", XP_PER_RANK)

	GG.UnitRankUp = {}

	local access_table = { inlos = true }

	function gadget:UnitCreated (unitID)
		spSetUnitRulesParam (unitID, "rank", 0, access_table)
	end

	function gadget:UnitExperience (unitID, unitDefID, unitTeam, newxp, oldxp)
		newxp = floor (newxp / XP_PER_RANK)
		oldxp = floor (oldxp / XP_PER_RANK)

		if (newxp ~= oldxp) then
			spSetUnitRulesParam (unitID, "rank", newxp, access_table)

			for _,f in pairs (GG.UnitRankUp) do
				f (unitID, unitDefID, unitTeam, newxp, oldxp)
			end
		end
	end

else

	local spGetUnitLosState = Spring.GetUnitLosState
	local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
	local spGetSpectatingState = Spring.GetSpectatingState

	function gadget:UnitExperience (unitID, unitDefID, unitTeam, newxp, oldxp)
		newxp = floor (newxp / XP_PER_RANK)
		oldxp = floor (oldxp / XP_PER_RANK)

		if (newxp ~= oldxp) then
			local spec, specFullView = spGetSpectatingState()
			local isInLos = spGetUnitLosState (unitID, spGetMyAllyTeamID()).los
			if (Script.LuaUI.UnitRankUp and ((spec and specFullView) or isInLos)) then
				Script.LuaUI.UnitRankUp (unitID)
			end
		end
	end
end
