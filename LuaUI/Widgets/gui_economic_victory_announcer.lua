function widget:GetInfo()
	return {
		name      = "Economic Victory Announcer",
		desc      = "Announces when a team has won a victory simply by owning more stuff.",
		author    = "GoogleFrog",
		date      = "25 May, 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

VFS.Include("LuaRules/Utilities/unitDefReplacements.lua")

local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
local MAX_NAME_LENGTH = 20

local doesNotCountUnits = {}
for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.customParams.is_drone or ud.customParams.dontcount then
		doesNotCountUnits[unitDefID] = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget options

local enabled = false

options_path = 'Settings/Interface/Spectating/Econ. Announcer'

options_order = {
	'enable',
	'sayResult',
	'firstCall',
	'secondCall',
	'econMultiplier',
}
 
options = {
	enable = {
		name  = "Enable economic victory announcer",
		type  = "bool",
		value = false,
		OnChange = function(self)
			enabled = self.value
			if enabled then
				widgetHandler:UpdateCallIn("GameFrame")
			else
				widgetHandler:RemoveCallIn("GameFrame")
			end
		end,
		noHotkey = true,
		desc = "Announces the total assets of the teams at set times. For use with a manually run economic victory condition."
	},
	sayResult = {
		name  = "Say results publicly (adjudicators only)",
		type  = "bool",
		value = false,
		noHotkey = true,
		desc = "Enable to say the result of the match publicly. Only for adjudicators."
	},
	firstCall = {
		name  = "First check time",
		type  = "number",
		value = 25, min = 0, max = 90, step = 1,
	},
	secondCall = {
		name  = "Second check time",
		type  = "number",
		value = 30, min = 0, max = 90, step = 1,
	},
	econMultiplier = {
		name  = "Economy multiplier",
		desc  = "A team wins if it has this times more value than any other team.",
		type  = "number",
		value = 2, min = 1, max = 5, step = 0.1,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Resource Window Management

local function GetUnitValue(unitID)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if doesNotCountUnits[unitDefID] then
		return 0
	end
	local cost = Spring.Utilities.GetUnitCost(unitID, unitDefID)
	local progress = select(5, Spring.GetUnitHealth(unitID))
	
	return cost*progress
end

local function GetTotalAssets()
	local units = Spring.GetAllUnits()

	local assets = {}
	for i = 1, #units do
		local unitID = units[i]
		local value = GetUnitValue(unitID)
		if value then
			local allyTeamID = Spring.GetUnitAllyTeam(unitID)
			if allyTeamID ~= gaiaAllyTeamID then
				assets[allyTeamID] = (assets[allyTeamID] or 0) + value
			end
		end
	end
	
	return assets
end

local function GetWinningAllyTeam(requiredMultiplier)
	local assets = GetTotalAssets()
	
	local winner = false
	local winnerAssets = 0
	
	for allyTeamID, assets in pairs(assets) do
		if assets >= winnerAssets*requiredMultiplier then
			winner = allyTeamID
			winnerAssets = assets
		elseif assets*requiredMultiplier >= winnerAssets then
			winner = false
		end
	end
	
	return winner, assets
end

local function GetAllyteamName(allyTeamID)
	local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID) or ("Team " .. allyTeamID)
	if string.len(name) > MAX_NAME_LENGTH then
		return Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID) or ("Team " .. allyTeamID)
	end
	return name
end

local function SaySomething(thingToSay)
	if options.sayResult.value then
		Spring.SendCommands("say " .. thingToSay)
	else
		Spring.Echo("game_message:" .. thingToSay)
	end
end

local function CheckAndReportWinner(requiredMultiplier)
	local spec, specFull = Spring.GetSpectatingState()
	if not spec then
		return -- not immediately salvageable, /spectator is synced and takes a round trip
	end
	if not specFull then
		Spring.SendCommands("specfullview 3")
	end

	local winner, assets = GetWinningAllyTeam(requiredMultiplier)
	if winner then
		SaySomething(GetAllyteamName(winner) .. " (team " .. winner .. ") wins!")
		for allyTeamID, assets in pairs(assets) do
			SaySomething(GetAllyteamName(allyTeamID) .. " has a total of " .. string.format("%i", assets) .. " metal.")
		end
	else
		SaySomething("No winner yet.")
		for allyTeamID, assets in pairs(assets) do
			Spring.Echo("game_message:" .. GetAllyteamName(allyTeamID) .. " has a total of " .. string.format("%i", assets) .. " metal.")
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:GameFrame(n)
	if n == (options.firstCall.value*1800) or n == (options.secondCall.value*1800) then
		CheckAndReportWinner(options.econMultiplier.value)
	end
end

function widget:Initialize()
	if enabled then
		widgetHandler:UpdateCallIn("GameFrame")
	else
		widgetHandler:RemoveCallIn("GameFrame")
	end
end
