
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Economy Multiplier Handicap",
		desc      = "Handles allyteams recieving multiplied income and BP.",
		author    = "GoogleFrog",
		date      = "26 June 2021",
		license   = "GNU GPL, v2 or later",
		layer     = 100, -- After unit attributes
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

GG.unit_handicap = {}
GG.allyTeamIncomeMult = {}

local teamMults = {}
local gadgetInUse = false

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		GG.allyTeamIncomeMult[allyTeamID] = Spring.GetModOptions()["team_" .. (allyTeamID + 1) .. "_econ"] or 1
		if GG.allyTeamIncomeMult[allyTeamID]~= 1 then
			gadgetInUse = true
		end
	end
end

function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
	if not teamMults[teamID] then
		local _, _, _, _, _,allyTeamID = Spring.GetTeamInfo(teamID)
		teamMults[teamID] = GG.allyTeamIncomeMult[allyTeamID] or 1
	end
	if GG.unit_handicap[unitID] or (teamMults[teamID] ~= 1) then
		GG.unit_handicap[unitID] = teamMults[teamID]
		GG.UpdateUnitAttributes(unitID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if not teamMults[teamID] then
		local _, _, _, _, _,allyTeamID = Spring.GetTeamInfo(teamID)
		teamMults[teamID] = GG.allyTeamIncomeMult[allyTeamID] or 1
	end
	if teamMults[teamID] ~= 1 then
		GG.unit_handicap[unitID] = teamMults[teamID]
		GG.UpdateUnitAttributes(unitID)
	end
end

function gadget:Initialize()
	if not gadgetInUse then
		GG.allyTeamIncomeMult = nil
		gadgetHandler:RemoveGadget()
		return
	end
	
	-- AllyTeamIDs are not guaranteed to be reasonably arranged.
	for allyTeamID, value in pairs(GG.allyTeamIncomeMult) do
		Spring.SetGameRulesParam("econ_mult_" .. allyTeamID, GG.allyTeamIncomeMult[allyTeamID])
	end
	Spring.SetGameRulesParam("econ_mult_enabled", 1)
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
