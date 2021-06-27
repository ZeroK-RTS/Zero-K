
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
local autoHandicapValue = false

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
		Spring.Echo("Setting up autohandicap")
		for i = 1, #players do
			local playerID = players[i]
			local name, _, spectator, _, allyTeamID, _, _, _, _, customKeys = Spring.GetPlayerInfo(playerID)
			Spring.Echo(name, "spectator", spectator, "allyTeamID", allyTeamID, "customKeys.elo", customKeys, customKeys and customKeys.elo)
			if (not spectator) and customKeys and customKeys.elo then
				allyTeamEloSum[allyTeamID] = allyTeamID[allyTeamID] or {}
				allyTeamPlayers[allyTeamID] = allyTeamPlayers[allyTeamID] or {}
				allyTeamEloSum[allyTeamID] = allyTeamEloSum[allyTeamID] + customKeys.elo
				allyTeamPlayers[allyTeamID] = allyTeamPlayers[allyTeamID] + 1
			end
		end
		Spring.Echo("Team 0", allyTeamPlayers[0], allyTeamEloSum[0])
		Spring.Echo("Team 1", allyTeamPlayers[1], allyTeamEloSum[1])
		
		if (allyTeamPlayers[0] or 0) > 0 and (allyTeamPlayers[1] or 0) > 0 then
			local firstAllyTeamMean = allyTeamEloSum[0] / allyTeamPlayers[0]
			local secondAllyTeamMean = allyTeamEloSum[1] / allyTeamPlayers[1]
			Spring.Echo("firstAllyTeamMean", firstAllyTeamMean)
			Spring.Echo("secondAllyTeamMean", secondAllyTeamMean)
			
			local lowerWinChance = GetLowerWinChance(firstAllyTeamMean, secondAllyTeamMean)
			Spring.Echo("lowerWinChance", lowerWinChance)
			
			local handicapAllyTeamID = ((firstAllyTeamMean < secondAllyTeamMean) and 0) or 1
			if lowerWinChance > 0.20 then
				autoHandicapValue = 1.05
			elseif lowerWinChance > 0.15 then
				autoHandicapValue = 1.1
			elseif lowerWinChance > 0.1 then
				autoHandicapValue = 1.15
			elseif lowerWinChance > 0.05 then
				autoHandicapValue = 1.2
			else
				autoHandicapValue = 1.25
			end
			if autoHandicapValue then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = autoHandicapValue
				gadgetInUse = true
			end
			Spring.Echo("autoHandicapValue", autoHandicapValue)
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
	if autoHandicapValue then
		Spring.SetGameRulesParam("econ_mult_auto_value", autoHandicapValue)
	end
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
end
