--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Galaxy Battle Handler",
		desc      = "Reports outcome of galaxy battle.",
		author    = "GoogleFrog",
		date      = "7 February 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		alwaysStart = true,
		hidden    = true,
	}
end

local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid
if not campaignBattleID then
	return
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables/config

local Chili

local WIN_MESSAGE = "Campaign_PlanetBattleWon"
local LOST_MESSAGE = "Campaign_PlanetBattleLost"
local myAllyTeamID = Spring.GetMyAllyTeamID()

local SUCCESS_ICON = LUAUI_DIRNAME .. "images/tick.png"
local FAILURE_ICON = LUAUI_DIRNAME .. "images/cross.png"

local objectiveList, bonusObjectiveList, mainObjectiveBlock, bonusObjectiveBlock

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function CustomKeyToUsefulTable(dataRaw)
	if not dataRaw then
		return
	end
	if not (dataRaw and type(dataRaw) == 'string') then
		if dataRaw then
			Spring.Echo("Customkey data error for team", teamID)
		end
	else
		dataRaw = string.gsub(dataRaw, '_', '=')
		dataRaw = Spring.Utilities.Base64Decode(dataRaw)
		local dataFunc, err = loadstring("return " .. dataRaw)
		if dataFunc then 
			local success, usefulTable = pcall(dataFunc)
			if success then
				if collectgarbage then
					collectgarbage("collect")
				end
				return usefulTable
			end
		end
		if err then
			Spring.Echo("Customkey error", err)
		end
	end
	if collectgarbage then
		collectgarbage("collect")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Objectives Handler

local function GetObjectivesBlock(holderWindow, name, position, items, gameRulesParam)
	
	local missionsLabel = Chili.Label:New{
		x = 8,
		y = position,
		width = "100%",
		height = 18,
		align = "left",
		valign = "top",
		caption = name,
		font = {size = 18},
		parent = holderWindow,
	}
	position = position + 22
	
	local objectives = {}
	
	for i = 1, #items do
		local label = Chili.Label:New{
			x = 22,
			y = position,
			width = "100%",
			height = 18,
			align = "left",
			valign = "top",
			caption = items[i].description,
			font = {size = 14},
			parent = holderWindow,
		}
		objectives[i] = {
			position = position,
			label = label,
		}
		position = position + 16
	end
	
	local function UpdateSuccess(index)
		if objectives[index].terminated then
			return
		end
		local newSuccess = Spring.GetGameRulesParam(gameRulesParam .. index)
		if not newSuccess then
			return
		end
		
		local image = Chili.Image:New{
			x = 4,
			y = objectives[index].position,
			width = 16,
			height = 16,
			file = (newSuccess == 1 and SUCCESS_ICON) or FAILURE_ICON,
			parent = holderWindow,
		}
		
		objectives[index].terminated = true
		objectives[index].image = image
	end
	
	local function UpdateObjectiveSuccess()
		if gameRulesParam then
			for i = 1, #objectives do
				UpdateSuccess(i)
			end
		end
	end
	
	UpdateObjectiveSuccess()
	
	local externalFunctions = {}
	
	function externalFunctions.Update()
		UpdateObjectiveSuccess()
	end
	
	return externalFunctions, position
end

local function InitializeBonusObjectives()
	objectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().objectiveconfig) or {}
	bonusObjectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().bonusobjectiveconfig) or {}
	
	local holderHeight = 20 + 16*(#objectiveList)
	if bonusObjectiveList and #bonusObjectiveList > 0 then
		holderHeight = holderHeight + 52 + 16*(#bonusObjectiveList)
	end
	
	local holderWindow = Chili.Window:New{
		classname = "main_window_small",
		name = 'mission_galaxy_objectives',
		x = 2,
		y = 50,
		width = 320,
		height = holderHeight,
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		parent = Chili.Screen0,
	}
	
	local position = 4
	mainObjectiveBlock, position = GetObjectivesBlock(holderWindow, "Main Objectives", position, objectiveList)
	if #bonusObjectiveList > 0 then
		position = position + 8
		bonusObjectiveBlock, position = GetObjectivesBlock(holderWindow, "Bonus Objectives", position, bonusObjectiveList, "bonusObjectiveSuccess_")
	end
	
	if WG.GlobalCommandBar then
		local function ToggleWindow()
			if holderWindow then
				holderWindow:SetVisibility(not holderWindow.visible)
			end
		end
		WG.GlobalCommandBar.AddCommand(LUAUI_DIRNAME .. "images/advplayerslist/random.png", "Toggle mission objectives.", ToggleWindow)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili
	InitializeBonusObjectives()
end

function widget:GameFrame(n)
	if n%30 == 0 then
		if bonusObjectiveBlock then
			bonusObjectiveBlock.Update()
		end
	end
end

local function SendVictoryToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(WIN_MESSAGE .. planetID)
	end
end

local function SendDefeatToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(LOST_MESSAGE .. planetID)
	end
end

function widget:GameOver(winners)
	for i = 1, #winners do
		if winners[i] == myAllyTeamID then
			SendVictoryToLuaMenu(campaignBattleID)
			return
		end
	end
	SendDefeatToLuaMenu(campaignBattleID)
end
