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

local bringToFrontWait = 2

local LOADOUT_ICON_SIZE = 64
local MAIN_TITLE_HEIGHT = 22

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local Chili
local screen0

local rewardButtons = {}
local currentLoadout = {}

local blackBackground
local loadoutDisplay 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utils

local function AddItemToLoadout(reward)
	local targetTable
	local itemType, itemTypeIndex
	if reward.factory then
		targetTable = currentLoadout.factories[reward.factory].units
		itemType = "factory"
		itemTypeIndex = reward.factory
	elseif reward.structure then
		targetTable = currentLoadout.structures
		itemType = "structure"
	end
	targetTable[#targetTable + 1] = reward
	loadoutDisplay.AddToLoadoutDisplay(reward)
end

local function SendLoadout()
	local encoded = UsefulTableToCustomKey(currentLoadout)
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

local function ClickFirstEnabledButton()
	for i = 1, #rewardButtons do
		if not rewardButtons[i].IsDisabled() then
			ClickRewardCategoryButton(i)
			return
		end
	end
end

local function SelectReward(buttonID, rewardID, rewardName)
	local reward = rewardDefs.flatRewards[rewardName]
	Spring.SendLuaRulesMsg("rk_selected_reward " .. rewardID)
	AddItemToLoadout(reward)
	SendLoadout()
	DisableRewardCategoryButton(buttonID)
	ClickFirstEnabledButton()
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
	do
		local rewardID = 1
		local found = Spring.GetTeamRulesParam(teamID, "rk_reward_name_" .. rewardID)
		while found do
			rewards[rewardID] = found
			rewardID = rewardID + 1
			found = Spring.GetTeamRulesParam(teamID, "rk_reward_name_" .. rewardID)
		end
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
		if Spring.GetTeamRulesParam(teamID, "rk_reward_used_" .. i) == 1 then
			rewardButtons[buttonID].SetDisabled(true)
		end
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

local function GetIconPosition(index, iconsAcross, paragraphOffset)
	if index%iconsAcross == 0 then
		paragraphOffset = paragraphOffset + (LOADOUT_ICON_SIZE + 4)
	end

	local x = index%iconsAcross*(LOADOUT_ICON_SIZE + 4)
	local y = paragraphOffset - LOADOUT_ICON_SIZE - 4
	return x, y, paragraphOffset
end

local function MakeRewardList(holder, name, leftBound, rightBound, itemList)
	local rewardsHolder = Chili.Control:New {
		x = leftBound,
		y = 0,
		right = rightBound,
		height = 10,
		padding = {0, 0, 0, 0},
		parent = holder,
	}
	local posIndex = 0
	local paragraphOffset = 0
	local iconsAcross = math.floor(rewardsHolder.width/(LOADOUT_ICON_SIZE + 4))

	if name then
		Chili.TextBox:New {
			x = 1,
			y = paragraphOffset + 5,
			right = 4,
			height = 30,
			text = name,
			font = {size = 16},
			parent = rewardsHolder
		}
		paragraphOffset = MAIN_TITLE_HEIGHT
	end

	local itemControls = {}
	local externalFunctions = {}
	
	function externalFunctions.AddItem(item)
		x, y, paragraphOffset = GetIconPosition(posIndex, iconsAcross, paragraphOffset)
		local rawTooltip = item.name
		local imageControl = Chili.Image:New{
			x = x,
			y = y,
			width = LOADOUT_ICON_SIZE,
			height = LOADOUT_ICON_SIZE,
			keepAspect = true,
			color = color,
			tooltip = item.name,
			file = 'unitpics/' .. item.name .. '.png',
			parent = rewardsHolder,
		}
		local text = Chili.TextBox:New{
			text = item.humanName or item.name,
			parent = imageControl,
		}
		itemControls[#itemControls + 1] = {
			image = imageControl,
		}
		posIndex = posIndex + 1
	end

	for i = 1, #itemList do
		externalFunctions.AddItem(itemList[i])
	end
	
	function externalFunctions.ResizeFunction(xSize)
		iconsAcross = math.floor(xSize/(LOADOUT_ICON_SIZE + 4))
		paragraphOffset = (name and MAIN_TITLE_HEIGHT) or 0
		posIndex = 0
		for i = 1, #itemControls do
			x, y, paragraphOffset = GetIconPosition(posIndex, iconsAcross, paragraphOffset)
			itemControls[i].image:SetPos(x, y)

			posIndex = posIndex + 1
		end
	end

	function externalFunctions.SetPosition(position)
		rewardsHolder:SetPos(nil, position, nil, paragraphOffset)
		return position + paragraphOffset + 4
	end

	return externalFunctions
end


local function SetupLoadoutPanel(bottomPanel)
	local teamID = Spring.GetMyTeamID()
	if not currentLoadout then
		return
	end
	
	local structures
	local factories = {}
	local function ResizeLoadout(xSize)
		local offset = 5
		if structures then
			structures.ResizeFunction(xSize / 2)
			offset = structures.SetPosition(offset)
		end
		
		offset = 5
		for i = 1, #factories do
			factories[i].ResizeFunction(xSize / 2)
			offset = factories[i].SetPosition(offset)
		end
	end

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
		OnResize = {
			function(self, xSize, ySize)
				ResizeLoadout(xSize)
			end
		},
	}
	
	structures = MakeRewardList(loadoutPanel, "Structures", "50%", 12, currentLoadout.structures)
	for i = 1, #currentLoadout.factories do
		factories[i] = MakeRewardList(loadoutPanel, "Factory " .. i, 12, "50%", currentLoadout.factories[i].units)
	end
	ResizeLoadout(loadoutPanel.width)
	
	local externalFuncs = {}
	
	function externalFuncs.AddToLoadoutDisplay(item)
		if item.factory then
			factories[item.factory].AddItem(item)
		elseif item.structure then
			structures.AddItem(item)
		end
		ResizeLoadout(loadoutPanel.width)
	end
	
	return externalFuncs
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakePostgamePanel()
	WG.SetMinimapVisibility(false)
	blackBackground = Chili.Window:New{
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
		parent = blackBackground,
		classname = "main_window_opaque",
		name = "RogueRewards",
		caption = "",
		x = '16%',
		y = '7%',
		right  = '16%',
		bottom = '5%',
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
		bottom = '40%',
	}
	local bottomPanel = Chili.Control:New{
		parent = window,
		x = 0,
		y = '60%',
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
	SetupRewardList(rewardListPanel, mainDisplay)
	loadoutDisplay = SetupLoadoutPanel(bottomPanel)
	blackBackground:BringToFront()
end

local function InitializeRewardSelection()
	local teamID = Spring.GetMyTeamID()
	local encoded = Spring.GetTeamRulesParam(teamID, "rk_loadout")
	currentLoadout = CustomKeyToUsefulTable(encoded)
	
	MakePostgamePanel()
	ClickFirstEnabledButton()
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

function widget:Update(dt)
	if blackBackground and bringToFrontWait then
		bringToFrontWait = bringToFrontWait - dt
		if bringToFrontWait <= 0 then
			blackBackground:BringToFront()
			bringToFrontWait = false
		end
	end
end
