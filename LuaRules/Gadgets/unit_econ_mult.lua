
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

local RUN_TEST = false

local function GetLowerWinChance(first, second)
	return 1 / (1 + math.pow(10, math.abs(first - second) / 400))
end

local function GetWinChanceThresholdMod(first, second)
	local lowerElo = math.min(first, second)
	if lowerElo < 1500 then
		return 1, 0
	elseif lowerElo < 2000 then
		local prog = (lowerElo - 1500) / 500
		return 0.66 + 0.34 * (1 - prog), 0
	end
	if lowerElo < 2500 then
		local prog = (lowerElo - 2000) / 500
		return 0.66, -0.03 * prog
	end
	return 0.66, -0.03
end

local function GetAutoHandicapValue(firstAllyTeamMean, secondAllyTeamMean)
	local lowerWinChance = GetLowerWinChance(firstAllyTeamMean, secondAllyTeamMean)
	Spring.Echo("lowerWinChance", lowerWinChance)
	local thresholdMult, thresholdOffset = GetWinChanceThresholdMod(firstAllyTeamMean, secondAllyTeamMean)
	
	if lowerWinChance > (0.15 + thresholdOffset) * thresholdMult then
		return 1.1
	elseif lowerWinChance > (0.1 + thresholdOffset) * thresholdMult then
		return 1.15
	elseif lowerWinChance > (0.05 + thresholdOffset) * thresholdMult then
		return 1.2
	end
	return 1.25
end

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
		Spring.Echo("Setting up autohandicap")
		
		local players = Spring.GetPlayerList()
		local allyTeamEloSum = {}
		local allyTeamPlayers = {}
		for i = 1, #players do
			local playerID = players[i]
			local name, _, spectator, _, allyTeamID, _, _, _, _, customKeys = Spring.GetPlayerInfo(playerID)
			Spring.Echo(name, "spectator", spectator, "allyTeamID", allyTeamID, "customKeys.elo", customKeys, customKeys and customKeys.elo, customKeys and customKeys.real_elo)
			if allyTeamID and (not spectator) then
				local myElo = customKeys and (customKeys.real_elo or customKeys.elo)
				if myElo then
					allyTeamEloSum[allyTeamID] = allyTeamEloSum[allyTeamID] or 0
					allyTeamPlayers[allyTeamID] = allyTeamPlayers[allyTeamID] or 0
					allyTeamEloSum[allyTeamID] = allyTeamEloSum[allyTeamID] + myElo
					allyTeamPlayers[allyTeamID] = allyTeamPlayers[allyTeamID] + 1
				end
			end
		end
		--allyTeamPlayers[0] = 1
		--allyTeamPlayers[1] = 1
		--allyTeamEloSum[0] = 2500
		--allyTeamEloSum[1] = 2000
		Spring.Echo("Team 0", allyTeamPlayers[0], allyTeamEloSum[0])
		Spring.Echo("Team 1", allyTeamPlayers[1], allyTeamEloSum[1])
		
		if (allyTeamPlayers[0] or 0) > 0 and (allyTeamPlayers[1] or 0) > 0 then
			local firstAllyTeamMean = allyTeamEloSum[0] / allyTeamPlayers[0]
			local secondAllyTeamMean = allyTeamEloSum[1] / allyTeamPlayers[1]
			Spring.Echo("firstAllyTeamMean", firstAllyTeamMean)
			Spring.Echo("secondAllyTeamMean", secondAllyTeamMean)
			
			local handicapAllyTeamID = ((firstAllyTeamMean < secondAllyTeamMean) and 0) or 1
			autoHandicapValue = GetAutoHandicapValue(firstAllyTeamMean, secondAllyTeamMean)
			
			if autoHandicapValue then
				GG.allyTeamIncomeMult[handicapAllyTeamID] = autoHandicapValue
				gadgetInUse = true
			end
			Spring.Echo("autoHandicapValue", autoHandicapValue)
			Spring.SendCommands("wbynum 255 SPRINGIE:autoHandicapValue," .. autoHandicapValue)
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
	if RUN_TEST then
		for i = 1000, 2500, 250 do
			for j = i + 250, i + 500, 50 do
				Spring.Echo("P1:", i, "P2:", j, "handicap:", GetAutoHandicapValue(i, j))
			end
		end
	end

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
