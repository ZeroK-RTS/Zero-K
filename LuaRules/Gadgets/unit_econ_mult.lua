
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
	local modoptions = Spring.GetModOptions()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		GG.allyTeamIncomeMult[allyTeamID] = math.max(0.01, math.min(100, modoptions["team_" .. (allyTeamID + 1) .. "_econ"] or 1))
		if GG.allyTeamIncomeMult[allyTeamID]~= 1 then
			gadgetInUse = true
		end
	end
	
	if (tonumber(modoptions.autohandicap) == 1) then
		local function GetLowerWinChance(first, second)
			return 1 / (1 + math.pow(10, math.abs(first - second) / 400))
		end
		
		local players = Spring.GetPlayerList()
		local allyTeamEloSum = {}
		local allyTeamPlayers = {}
		for i = 1, #players do
			local playerID = players[i]
			local _, _, spectator, _, allyTeamID, _, _, _, _, customKeys = Spring.GetPlayerInfo(playerID)
			if (not spectator) and customKeys and customKeys.elo then
				allyTeamEloSum[allyTeamID] = allyTeamID or {}
				allyTeamPlayers[allyTeamID] = allyTeamPlayers or {}
				allyTeamEloSum[allyTeamID] = allyTeamEloSum[allyTeamID] + customKeys.elo
				allyTeamPlayers[allyTeamID] = allyTeamPlayers[allyTeamID] + 1
			end
		end
		if (allyTeamPlayers[0] or 0) > 0 and (allyTeamPlayers[1] or 0) > 0 then
			local firstAllyTeamMean = allyTeamEloSum[0] / allyTeamPlayers[0]
			local secondAllyTeamMean = allyTeamEloSum[1] / allyTeamPlayers[1]
			local lowerWinChance = GetLowerWinChance(firstAllyTeamMean, secondAllyTeamMean)
			local handicapAllyTeamID = ((firstAllyTeamMean < secondAllyTeamMean) and 0) or 1
			if lowerWinChance < 0.15 then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = 1.1
				gadgetInUse = true
			elseif lowerWinChance < 0.10 then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = 1.15
				gadgetInUse = true
			elseif lowerWinChance < 0.07 then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = 1.2
				gadgetInUse = true
			elseif lowerWinChance < 0.04 then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = 1.25
				gadgetInUse = true
			end
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
