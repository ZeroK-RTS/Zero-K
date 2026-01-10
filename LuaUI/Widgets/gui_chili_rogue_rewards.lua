--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Rogue-K Rewards",
    desc      = "Select Rogue-K upgrades and prepare for the next battle.",
    author    = "GoogleFrog",
    date      = "9 January 2026",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_DISABLE_COLOR = {0.1, 0.1, 0.1, 0.85}
local BUTTON_DISABLE_FOCUS_COLOR = {0.1, 0.1, 0.1, 0.85}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR
local BUTTON_BORDER_COLOR

local CustomKeyToUsefulTable = Spring.Utilities.CustomKeyToUsefulTable
local UsefulTableToCustomKey = Spring.Utilities.UsefulTableToCustomKey


local modOptions = Spring.GetModOptions() or {}
local rewardDefs = VFS.Include("LuaRules/Configs/RogueK/reward_defs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local Chili
local screen0

local rewardButtons = {}
local loadout = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utils

local function SendLoadout()
	local encoded = UsefulTableToCustomKey(loadout)
	Spring.SendLuaRulesMsg("rk_loadout " .. encoded)
end

local function ClickRewardCategoryButton(buttonID)
	for i = 1, #rewardButtons do
		rewardButtons[i].SetSelection(buttonID == i)
	end
	rewardButtons[buttonID].ShowReward()
end

local function DisableRewardCategoryButton(buttonID)
	rewardButtons[buttonID].SetDisabled(true)
end

local function SelectReward(buttonID, rewardID, rewardName)
	local reward = rewardDefs.flatRewards[rewardName]
	local targetTable
	if reward.factory then
		targetTable = loadout.factories[reward.factory].units
	elseif reward.structure then
		targetTable = loadout.structures
	end
	targetTable[#targetTable + 1] = {
		name = rewardName
	}
	
	SendLoadout()
	DisableRewardCategoryButton(buttonID)
	for i = 1, #rewardButtons do
		if not rewardButtons[i].IsDisabled() then
			ClickRewardCategoryButton(i)
			return
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Galaxy Map

local function SetupGalaxyMap(parent)
	
	local externalFuncs = {}
	function externalFuncs.Show()
	
	end
	function externalFuncs.Hide()
	
	end
	
	return externalFuncs
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reward selection area

local function SetupRewardSelectionView(parent)
	local teamID = Spring.GetMyTeamID()
	local rewardID, buttonID = false, false
	local rewardOptions = false
	
	local holder = Chili.Control:New{
		parent = parent,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {10, 10, 10, 10},
	}
	holder:SetVisibility(false)
	
	local buttons = {}
	
	local externalFuncs = {}
	function externalFuncs.ShowRewards(newButtonID, newRewardID)
		buttonID = newButtonID
		rewardID = newRewardID
		local optionsShown = Spring.GetTeamRulesParam(teamID, "rk_reward_display_count_" .. rewardID)
		local rewardOptions = {}
		Spring.Echo("optionsShown", optionsShown, rewardID)
		for i = 1, optionsShown do
			rewardOptions[i] = Spring.GetTeamRulesParam(teamID, "rk_reward_option_" .. rewardID .. "_" .. i)
		end
		holder:SetVisibility(true)
	
		for i = 1, math.max(#buttons, #rewardOptions) do
			if not rewardOptions[i] then
				buttons[i]:SetVisibility(false)
			end
			if not buttons[i] then
				buttons[i] = Chili.Button:New{
					parent = holder,
					OnClick = {},
					x = 20,
					width = 200,
					y = 20 + i * 50,
					height = 45,
				}
			end
			local rewardName = rewardOptions[i]
			buttons[i]:SetCaption(rewardDefs.flatRewards[rewardName].humanName)
			buttons[i].OnClick[1] = function ()
				SelectReward(buttonID, rewardID, rewardName)
			end
		end
	end
	
	function externalFuncs.Hide()
		holder:SetVisibility(false)
	end
	
	return externalFuncs
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reward list

local function NewRewardListButton(parent, rewardSelectionView, galaxyMap, pos, height, reward, buttonID, rewardID)
	local isSelected = false
	local isDisabled = false
	local oldFont = WG.GetSpecialFont(14, "internal_white", {outlineColor = {0, 0, 0, 1}, color = {1, 1, 1, 1}})
	
	local button = Chili.Button:New{
		parent = parent,
		caption = reward.humanName,
		OnClick = {function () ClickRewardCategoryButton(buttonID) end},
		x = 20,
		right = 20,
		y = pos,
		height = height,
	}
	button.font = oldFont
	
	if not BUTTON_COLOR then
		BUTTON_COLOR = button.backgroundColor
	end
	if not BUTTON_FOCUS_COLOR then
		BUTTON_FOCUS_COLOR = button.focusColor
	end
	if not BUTTON_BORDER_COLOR then
		BUTTON_BORDER_COLOR = button.borderColor
	end
	
	local externalFuncs = {}
	function externalFuncs.SetDisabled(newDisabled)
		if newDisabled == isDisabled then
			return
		end
		isDisabled = newDisabled
		if isDisabled then
			button.backgroundColor = BUTTON_DISABLE_COLOR
			button.focusColor = BUTTON_DISABLE_FOCUS_COLOR
			button.borderColor = BUTTON_DISABLE_FOCUS_COLOR
			function button:HitTest(x,y) return false end
			button.font = WG.GetSpecialFont(14, "integral_grey", {outlineColor = {0, 0, 0, 1}, color = {0.6, 0.6, 0.6, 1}})
		else
			button.backgroundColor = BUTTON_COLOR
			button.focusColor = BUTTON_FOCUS_COLOR
			button.borderColor = BUTTON_BORDER_COLOR
			button.font = oldFont
			function button:HitTest(x,y) return self end
		end
		button:Invalidate()
	end
	
	function externalFuncs.SetSelection(newIsSelected)
		if isSelected == newIsSelected then
			return
		end
		isSelected = newIsSelected
		if isSelected then
			button.backgroundColor = SELECT_BUTTON_COLOR
			button.focusColor = SELECT_BUTTON_FOCUS_COLOR
		else
			button.backgroundColor = BUTTON_COLOR
			button.focusColor = BUTTON_FOCUS_COLOR
		end
		button:Invalidate()
	end
	
	function externalFuncs.ShowReward()
		if not rewardID then
			rewardSelectionView.Hide()
			galaxyMap.Show()
			return
		end
		galaxyMap.Hide()
		rewardSelectionView.ShowRewards(buttonID, rewardID)
	end
	
	function externalFuncs.IsDisabled()
		return isDisabled
	end
	
	return externalFuncs
end

local function SetupRewardList(leftPanel, rightPanel)
	local teamID = Spring.GetMyTeamID()
	local rewards = {}
	local rewardID = 1
	local found = Spring.GetTeamRulesParam(teamID, "rk_reward_name_" .. rewardID)
	while found do
		rewards[rewardID] = found
		rewardID = rewardID + 1
		found = Spring.GetTeamRulesParam(teamID, "rk_reward_name_" .. rewardID)
	end
	
	local rewardSelectionView = SetupRewardSelectionView(rightPanel)
	local galaxyMap = SetupGalaxyMap(rightPanel)
	
	local pos = 10
	local SIZE = 46
	local SPACING = 8
	for i = #rewards, 1, -1 do
		local reward = rewardDefs.categories[rewards[i]]
		local buttonID = #rewardButtons + 1
		rewardButtons[buttonID] = NewRewardListButton(leftPanel, rewardSelectionView, galaxyMap, pos, SIZE, reward, buttonID, i)
		pos = pos + SIZE + SPACING
	end
	
	local galaxyViewButton = {
		humanName = "Galaxy Map",
		isGalaxyMap = true,
	}
	pos = pos + SIZE + SPACING
	local buttonID = #rewardButtons + 1
	rewardButtons[buttonID] = NewRewardListButton(leftPanel, rewardSelectionView, galaxyMap, pos, SIZE, galaxyViewButton, buttonID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakePostgamePanel()
	WG.SetMinimapVisibility(false)
	local black = Chili.Window:New{
		parent = screen0,
		classname = "window_black",
		name = "RogueRewards",
		caption = "",
		color = {0, 0, 0, 0.7}, -- Transparent for debug
		x = 0,
		y = 0,
		right  = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
	}
	local window = Chili.Window:New{
		parent = black,
		classname = "main_window_opaque",
		name = "RogueRewards",
		caption = "",
		x = '16%',
		y = '10%',
		right  = '16%',
		bottom = '10%',
		minWidth  = 500,
		minHeight = 400,
		draggable = false,
		resizable = false,
	}
	
	local topPanel = Chili.Control:New{
		parent = window,
		x = 0,
		y = 0,
		right  = 0,
		bottom = '34%',
	}
	local bottomPanel = Chili.Control:New{
		parent = window,
		x = 0,
		y = '66%',
		right  = 0,
		bottom = 0,
	}
	
	local rewardListPanel = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = topPanel,
			x = 0,
			y = 0,
			right = '72%',
			bottom = 0,
			padding = {10, 10, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
	}
	local mainDisplay = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = topPanel,
			x = '28%',
			y = 0,
			right = 0,
			bottom = 0,
			padding = {10, 10, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		verticalScrollbar   = true,
		horizontalScrollbar = true,
	}
	local loadoutPanel = Chili.ScrollPanel:New {
		parent = Chili.Control:New{
			parent = bottomPanel,
			x = 0,
			y = 0,
			right = 0,
			bottom = 0,
			padding = {10, 0, 10, 10},
		},
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
	}
	SetupRewardList(rewardListPanel, mainDisplay)
end

local function InitializeRewardSelection()

	local teamID = Spring.GetMyTeamID()
	local _,_,_,_,_,_, customKeys = Spring.GetTeamInfo(teamID, true)
	loadout = CustomKeyToUsefulTable(customKeys.rk_loadout)
	
	MakePostgamePanel()
	ClickRewardCategoryButton(1)
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	if tonumber(modOptions.rk_enabled or 0) ~= 1 then
		widgetHandler:RemoveWidget()
		return
	end
	Chili = WG.Chili
	screen0 = Chili.Screen0
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	if tonumber(modOptions.rk_post_game_only or 0) == 1 then
		InitializeRewardSelection()
	end
end
