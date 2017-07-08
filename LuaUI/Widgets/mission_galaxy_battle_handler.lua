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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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
local LOAD_CAMPAIGN_MESSAGE = "Campaign_LoadCampaign"
local myAllyTeamID = Spring.GetMyAllyTeamID()

local SUCCESS_ICON = LUAUI_DIRNAME .. "images/tick.png"
local FAILURE_ICON = LUAUI_DIRNAME .. "images/cross.png"
local OBJECTIVE_ICON = LUAUI_DIRNAME .. "images/bullet.png"

local mainObjectiveBlock, bonusObjectiveBlock
local globalCommandButton

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

local function GetObjectivesBlock(holderWindow, position, items, gameRulesParam)
	
	local missionsLabel = Chili.Label:New{
		x = 8,
		y = position,
		width = "100%",
		height = 18,
		align = "left",
		valign = "top",
		caption = "",
		fontsize = 18,
		parent = holderWindow,
	}
	position = position + 26
	
	local objectives = {}
	
	for i = 1, #items do
		local label = Chili.TextBox:New{
			x = 22,
			y = position,
			right = 4,
			height = 18,
			align = "left",
			valign = "top",
			text = items[i].description,
			fontsize = 14,
			parent = holderWindow,
		}
		local image = Chili.Image:New{
			x = 4,
			y = position - 3,
			width = 16,
			height = 16,
			file = OBJECTIVE_ICON,
			parent = holderWindow,
		}
		objectives[i] = {
			position = position,
			label = label,
			image = image,
		}
		position = position + (#label.physicalLines)*16
	end
	
	local function UpdateSuccess(index)
		if objectives[index].terminated then
			return
		end
		local newSuccess = Spring.GetGameRulesParam(gameRulesParam .. index)
		if not newSuccess then
			return
		end
		
		objectives[index].image.file = (newSuccess == 1 and SUCCESS_ICON) or FAILURE_ICON
		objectives[index].image:Invalidate()
		
		objectives[index].success = (newSuccess == 1)
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
	function externalFunctions.UpdateTooltip(text)
		missionsLabel:SetCaption(text)
	end
	
	function externalFunctions.MakeObjectivesString()
		local objectivesString = ""
		for i = 1, #objectives do
			if objectives[i].success then
				objectivesString = objectivesString .. "1"
			else
				objectivesString = objectivesString .. "0"
			end
		end
		return objectivesString
	end
	
	return externalFunctions, position
end

local function InitializeBonusObjectives()
	local objectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().objectiveconfig) or {}
	local bonusObjectiveList = CustomKeyToUsefulTable(Spring.GetModOptions().bonusobjectiveconfig) or {}
	
	local holderHeight = 22 + 16*(#objectiveList)
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
	mainObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, objectiveList,  "objectiveSuccess_")
	if #bonusObjectiveList > 0 then
		position = position + 8
		bonusObjectiveBlock, position = GetObjectivesBlock(holderWindow, position, bonusObjectiveList, "bonusObjectiveSuccess_")
	end
	
	if WG.GlobalCommandBar then
		local function ToggleWindow()
			if holderWindow then
				holderWindow:SetVisibility(not holderWindow.visible)
			end
		end
		globalCommandButton = WG.GlobalCommandBar.AddCommand(LUAUI_DIRNAME .. "images/advplayerslist/random.png", "", ToggleWindow)
	end
	
	holderWindow:SetPos(nil, nil, nil, position + holderWindow.padding[2] + holderWindow.padding[4] + 3)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function languageChanged ()
	if globalCommandButton then
		globalCommandButton.tooltip = WG.Translate("interface", "toggle_mission_objectives_name") .. "\n\n" .. WG.Translate("interface", "toggle_mission_objectives_desc")
		globalCommandButton:Invalidate()
	end
	if mainObjectiveBlock then
		mainObjectiveBlock.UpdateTooltip(WG.Translate("interface", "main_objectives"))
	end
	if bonusObjectiveBlock then
		bonusObjectiveBlock.UpdateTooltip(WG.Translate("interface", "bonus_objectives"))
	end
end

function widget:Initialize()
	Chili = WG.Chili
	InitializeBonusObjectives()
	WG.InitializeTranslation (languageChanged, GetInfo().name)
end

function widget:GameFrame(n)
	if n%30 == 0 then
		if mainObjectiveBlock then
			mainObjectiveBlock.Update()
		end
		if bonusObjectiveBlock then
			bonusObjectiveBlock.Update()
		end
	end
end

local function SendVictoryToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		local bonusObjectiveString = bonusObjectiveBlock and bonusObjectiveBlock.MakeObjectivesString()
		Spring.SendLuaMenuMsg(WIN_MESSAGE .. planetID .. " " .. (bonusObjectiveString or ""))
	end
end

local function SendDefeatToLuaMenu(planetID)
	local luaMenu = Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()
	if luaMenu then
		Spring.SendLuaMenuMsg(LOST_MESSAGE .. planetID)
	end
end

function widget:GameOver(winners)
	if Spring.IsReplay() then
		return
	end
	
	local campaignSaveName = Spring.GetModOptions().singleplayercampaignsavename
	if campaignSaveName and campaignSaveName ~= "" then
		Spring.SendLuaMenuMsg(LOAD_CAMPAIGN_MESSAGE .. campaignSaveName)
	end
	
	if bonusObjectiveBlock then
		bonusObjectiveBlock.Update()
	end
	
	for i = 1, #winners do
		if winners[i] == myAllyTeamID then
			SendVictoryToLuaMenu(campaignBattleID)
			return
		end
	end
	SendDefeatToLuaMenu(campaignBattleID)
end
