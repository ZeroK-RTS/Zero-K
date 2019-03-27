--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Commander Upgrade",
    desc      = "Interface for commander upgrade selection.",
    author    = "GoogleFrog",
    date      = "29 December 2015",
    license   = "GNU GPL, v2 or later",
	handler   = true,
    layer     = -10,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")

local Chili
local Button
local Label
local Window
local Panel
local StackPanel
local LayoutPanel
local Image
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Most things are local to their own code block. These blocks are (in order)
-- * Replacement Button Handler. This creates and keeps track of buttons
--   which appear in the replacement window.
-- * Replacement Window Handler. This creates and updates the window which holds
--   the replacement buttons.
-- * Current Module Tracker. This does not directly control Chili. This block of
--   code keeps track of the data behind the modules system. This includes a
--   list of current modules and functions for getting the replacementSet and
--   whether a module choice is still valid.
-- * Main Button Handler. This updates the module selection buttons and keeps
--   click functions and restrictions.
-- * Main Window Handler. This handles the main chili window. Will handle
--   acceptance and rejection of the current module setup.
-- * Command Handling. Handles command displaying and issuing to the upgradable
--   units.
-- * Callins. This block handles widget callins. Does barely anything.

-- Module config
local moduleDefs, chassisDefs, upgradeUtilities, LEVEL_BOUND, _, moduleDefNames = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")

VFS.Include("LuaRules/Configs/customcmds.h.lua")

-- This command is entirely internal. Does not hit gadget land.
local CMD_UPGRADE_UNIT = 11432

-- Configurable things, possible to add to Epic Menu later.
local BUTTON_SIZE = 55
local ROW_COUNT = 6

-- Index of module which is selected for the purposes of replacement.
local activeSlotIndex

-- Whether already owned modules are shown
local alreadyOwnedShown = false

-- StackPanel containing the buttons for the current list of modules
local currentModuleList

-- Button for viewing owned modules
local viewAlreadyOwnedButton

local moduleTextColor = {.8,.8,.8,.9}

local commanderUnitDefID = {}
for i = 1, #UnitDefs do
	if UnitDefs[i].customParams.dynamic_comm then
		commanderUnitDefID[i] = true
	end
end

local UPGRADE_CMD_DESC = {
	id      = CMD_UPGRADE_UNIT,
	type    = CMDTYPE.ICON,
	tooltip = 'Upgrade Commander',
	cursor  = 'Repair',
	action  = 'upgradecomm',
	params  = {}, 
	texture = 'LuaUI/Images/commands/Bold/upgrade.png',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- New Module Selection Button Handling

local newButtons = {}

local function AddNewSelectonButton(buttonIndex, moduleDefID)
	local moduleData = moduleDefs[moduleDefID]
	local newButton = Button:New{
		caption = "",
		width = BUTTON_SIZE,
		minHeight = BUTTON_SIZE,
		padding = {0, 0, 0, 0},
		OnClick = { 
			function(self) 
				SelectNewModule(self.moduleDefID)
			end 
		},
		backgroundColor = {0.5,0.5,0.5,0.1},
		color = {1,1,1,0.1},
		tooltip = moduleData.description
	}

	Image:New{
		x = 0,
		right = 0,
		y = 0,
		bottom = 0,
		keepAspect = true,
		file = moduleData.image,
		parent = newButton,
	}
	
	newButton.moduleDefID = moduleDefID
	
	newButtons[buttonIndex] = newButton
end

local function UpdateNewSelectionButton(buttonIndex, moduleDefID)
	local moduleData = moduleDefs[moduleDefID]
	local button = newButtons[buttonIndex]
	button.tooltip = moduleData.description
	button.moduleDefID = moduleDefID
	button.children[1].file = moduleData.image
	button.children[1]:Invalidate()
	return button
end

local function GetNewSelectionButton(buttonIndex, moduleDefID)
	if newButtons[buttonIndex] then
		UpdateNewSelectionButton(buttonIndex, moduleDefID)
	else
		AddNewSelectonButton(buttonIndex, moduleDefID)
	end
	return newButtons[buttonIndex]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection Window Handling

local selectionWindow

local function CreateModuleSelectionWindow()
	local selectionButtonPanel = LayoutPanel:New{
		x = 0,
		y = 0,
		right = 0,
		orientation = "vertical",
		columns = 7,
		--width  = "100%",
		height = "100%",
		backgroundColor = {1,1,1,1},
		color = {1,1,1,1},
		--children = buttons,
		itemPadding = {0,0,0,0},
		itemMargin  = {0,0,0,0},
		resizeItems = false,
		centerItems = false,
		autosize = true,
	}
	
	local fakeSelectionWindow = Panel:New{
		x = 0,  
		width = 20,
		y = 0, 
		height = 20,
		padding = {0, 0, 0, 0},	
		backgroundColor = {1, 1, 1, 0.8},
		children = {selectionButtonPanel}
	}
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local minimapHeight = screenWidth/6 + 45
	
	local selectionWindowMain = Window:New{
		name = "ModuleSelectionWindow",
		fontsize = 20,
		x = 200,  
		y = minimapHeight,
		clientWidth = 500,
		clientHeight = 500,
		minWidth = 0,
		minHeight = 0,
		padding = {0, 0, 0, 0},	
		resizable = false,
		draggable = false,
		dockable = true,
		dockableSavePositionOnly = true,
		dockableNoResize = true,
		tweakDraggable = true,
		tweakResizable = true,
		color = {0,0,0,0},
		children = {fakeSelectionWindow}
	}

	return {
		window = selectionWindowMain,
		fakeWindow = fakeSelectionWindow,
		panel = selectionButtonPanel,
		windowShown = false,
	}
end

local function HideModuleSelection()
	if selectionWindow and selectionWindow.windowShown then
		selectionWindow.windowShown = false
		screen0:RemoveChild(selectionWindow.window)
	end
end

local function ShowModuleSelection(moduleSet, supressButton)
	if not selectionWindow then
		selectionWindow = CreateModuleSelectionWindow()
	end
	
	local panel = selectionWindow.panel
	local fakeWindow = selectionWindow.fakeWindow
	local window = selectionWindow.window
	
	-- The number of modules which need to be displayed.
	local moduleCount = #moduleSet
	
	if moduleCount == 0 then
		HideModuleSelection()
		return
	end
	
	-- Update buttons
	if moduleCount < #panel.children then
		-- Remove buttons if there are too many
		for i = #panel.children, moduleCount + 1, -1  do
			panel:RemoveChild(panel.children[i])
		end
	else
		-- Add buttons if there are too few
		for i = #panel.children + 1, moduleCount do
			local button = GetNewSelectionButton(i, moduleSet[i])
			panel:AddChild(button)
			button.supressButtonReaction = supressButton
		end
	end
	
	-- Update buttons which were not added or removed.
	local forLimit = math.min(moduleCount, #panel.children)
	for i = 1, forLimit do
		local button = UpdateNewSelectionButton(i, moduleSet[i])
		button.supressButtonReaction = supressButton
	end
	
	-- Resize window to fit module count
	local rows, columns
	if moduleCount < 3*ROW_COUNT then
		columns = math.min(moduleCount, 3)
		rows = math.ceil(moduleCount/3)
	else
		columns = math.ceil(moduleCount/ROW_COUNT)
		rows = math.ceil(moduleCount/columns)
	end
	
	-- Column updating works without Invalidate
	panel.columns = columns
	window:Resize(columns*BUTTON_SIZE + 10, rows*BUTTON_SIZE + 10)
	fakeWindow:Resize(columns*BUTTON_SIZE + 10, rows*BUTTON_SIZE + 10)
	
	-- Display window if not already shown
	if not selectionWindow.windowShown then
		selectionWindow.windowShown = true
		screen0:AddChild(window)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Keep track of the current modules and generate restrictions

local alreadyOwnedModules = {}
local alreadyOwnedModulesByDefID = {}

local currentModulesBySlot = {}
local currentModulesByDefID = {}

local function ResetCurrentModules(newAlreadyOwned)
	currentModulesBySlot = {}
    currentModulesByDefID = {}
	alreadyOwnedModules = newAlreadyOwned
	alreadyOwnedModulesByDefID = upgradeUtilities.ModuleListToByDefID(newAlreadyOwned)
end

local function GetCurrentModules()
	return currentModulesBySlot
end

local function GetAlreadyOwned()
	return alreadyOwnedModules
end

local function GetSlotModule(slot, emptyModule)
	return currentModulesBySlot[slot] or emptyModule
end

local function UpdateSlotModule(slot, moduleDefID)
	if currentModulesBySlot[slot] then
		local oldID = currentModulesBySlot[slot]
		local count = currentModulesByDefID[oldID]
		if count and count > 1 then
			currentModulesByDefID[oldID] = count - 1
		else
			currentModulesByDefID[oldID] = nil
		end
	end
	
	currentModulesBySlot[slot] = moduleDefID
	currentModulesByDefID[moduleDefID] = (currentModulesByDefID[moduleDefID] or 0) + 1
end

local function ModuleIsValid(level, chassis, slotAllows, slotIndex)
	local moduleDefID = currentModulesBySlot[slotIndex]
	return upgradeUtilities.ModuleIsValid(level, chassis, slotAllows, moduleDefID, alreadyOwnedModulesByDefID, currentModulesByDefID)
end

local function GetNewReplacementSet(level, chassis, slotAllows, ignoreSlot)
	local replacementSet = {}
	local haveEmpty = false
	for i = 1, #moduleDefs do
		local data = moduleDefs[i]
		if slotAllows[data.slotType] and (data.requireLevel or 0) <= level and 
				((not data.requireChassis) or data.requireChassis[chassis]) and not data.unequipable then
			local accepted = true
			
			-- Check whether required modules are present, not counting ignored slot
			if data.requireOneOf then
				local foundRequirement = false
				for j = 1, #data.requireOneOf do
					local req = data.requireOneOf[j]
					if (alreadyOwnedModulesByDefID[req] or 
						(currentModulesByDefID[req] and 
							(currentModulesBySlot[ignoreSlot] ~= req or 
							currentModulesByDefID[req] > 1))) then
						
						foundRequirement = true
						break
					end
				end
				if not foundRequirement then
					accepted = false
				end
			end
			
			-- Check whether prohibited modules are present, not counting ignored slot
			if accepted and data.prohibitingModules then
				for j = 1, #data.prohibitingModules do
					local prohibit = data.prohibitingModules[j]
					if (alreadyOwnedModulesByDefID[prohibit] or 
						(currentModulesByDefID[prohibit] and 
							(currentModulesBySlot[ignoreSlot] ~= prohibit or 
							currentModulesByDefID[prohibit] > 1))) then
						
						accepted = false
						break
					end
				end
			end

			-- cheapass hack to prevent cremcom dual wielding same weapon (not supported atm)
			-- proper solution: make the second instance of a weapon apply projectiles x2 or reloadtime x0.5 and get cremcoms unit script to work with that
			local limit = data.limit
			if chassis == 5 and data.slotType == "basic_weapon" and limit == 2 then
				limit = 1
			end

			-- Check against module limit, not counting ignored slot
			if accepted and limit and (currentModulesByDefID[i] or alreadyOwnedModulesByDefID[i]) then
				local count = (currentModulesByDefID[i] or 0) + (alreadyOwnedModulesByDefID[i] or 0) 
				if currentModulesBySlot[ignoreSlot] == i then
					count = count - 1
				end
				if count >= limit then
					accepted = false
				end
			end
			
			-- Only put one empty module in the accepted set (for the case of slots which allow two or more types)
			if accepted and data.emptyModule then
				if haveEmpty then
					accepted = false
				else
					haveEmpty = true
				end
			end
			
			-- Add the module once accepted
			if accepted then
				replacementSet[#replacementSet + 1] = i
			end
		end
	end
	return replacementSet
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Current Module Button Handling

-- Two seperate lists because buttons are stored, module data is not and
-- may change size between invocations of the window.
local currentModuleData = {}
local currentModuleButton = {}

local function ResetCurrentModuleData()
	currentModuleData = {}
end

local function ClearActiveButton()
	if alreadyOwnedShown then
		viewAlreadyOwnedButton.backgroundColor = {0.5,0.5,0.5,0.5}
		viewAlreadyOwnedButton:Invalidate()
		alreadyOwnedShown = false
	end
	if activeSlotIndex then
		currentModuleButton[activeSlotIndex].backgroundColor = {0.5,0.5,0.5,0.5}
		currentModuleButton[activeSlotIndex]:Invalidate()
	end
	alreadyOwnedShown = false
	activeSlotIndex = false
end

local function CurrentModuleClick(self, slotIndex)
	if (not activeSlotIndex) or activeSlotIndex ~= slotIndex then
		ClearActiveButton()
		self.backgroundColor = {0,1,0,1}
		activeSlotIndex = slotIndex
		ShowModuleSelection(currentModuleData[slotIndex].replacementSet)
	else
		self.backgroundColor = {0.5,0.5,0.5,0.5}
		activeSlotIndex = false
		HideModuleSelection()
	end
end

local function AlreadyOwnedModuleClick(self)
	if not alreadyOwnedShown then
		ClearActiveButton()
		self.backgroundColor = {0,1,0,1}
		alreadyOwnedShown = true
		ShowModuleSelection(GetAlreadyOwned(), true)
	else
		self.backgroundColor = {0.5,0.5,0.5,0.5}
		alreadyOwnedShown = false
		HideModuleSelection()
	end
end

local function AddCurrentModuleButton(slotIndex, moduleDefID)
	local moduleData = moduleDefs[moduleDefID]
	local newButton = Button:New{
		caption = "",
		x = 0,
		y = 0,
		right = 0,
		minHeight = BUTTON_SIZE,
		height = BUTTON_SIZE,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function(self)
				CurrentModuleClick(self, slotIndex)
			end
		},
		tooltip = moduleData.description
	}

	Image:New{
		x = 0,
		y = 0,
		bottom = 0,
		keepAspect = true,
		file = moduleData.image,
		parent = newButton,
	}
	
	local textBox = Chili.TextBox:New{
		x      = 64,
		y      = 10,
		right  = 8,
		bottom = 8,
		valign = "left",
		text   = moduleData.humanName,
		font   = {size = 16, outline = true, color = moduleTextColor, outlineWidth = 2, outlineWeight = 2},
		parent = newButton,
	}
	
	currentModuleButton[slotIndex] = newButton
end

-- This type of module replacement updates the button as well.
-- UpdateSlotModule only updates module tracking. This function
-- does not update replacementSet.
local function ModuleReplacmentWithButton(slotIndex, moduleDefID)
	local moduleData = moduleDefs[moduleDefID]
	local button = currentModuleButton[slotIndex]
	button.tooltip = moduleData.description
	button.children[1].file = moduleData.image
	button.children[1]:Invalidate()
	button.children[2]:SetText(moduleData.humanName)
	UpdateSlotModule(slotIndex, moduleDefID)
end

local function GetCurrentModuleButton(moduleDefID, slotIndex, level, chassis, slotAllows, empty)
	if not currentModuleButton[slotIndex] then
		AddCurrentModuleButton(slotIndex, moduleDefID)
	end
	
	currentModuleData[slotIndex] = currentModuleData[slotIndex] or {}
	local current = currentModuleData[slotIndex]
	
	current.level = level
	current.chassis = chassis
	current.slotAllows = slotAllows
	current.empty = empty
	current.replacementSet = GetNewReplacementSet(level, chassis, slotAllows, slotIndex)

	ModuleReplacmentWithButton(slotIndex, moduleDefID)
	
	return currentModuleButton[slotIndex]
end

function SelectNewModule(moduleDefID)
	if (not activeSlotIndex) or alreadyOwnedShown then
		return
	end
	
	ModuleReplacmentWithButton(activeSlotIndex, moduleDefID)
	
	-- Check whether module choices are still valid
	local requireUpdate = true
	local newCost = 0
	for repeatBreak = 1, 2 * #currentModuleData do
		newCost = 0
		requireUpdate = false
		for i = 1, #currentModuleData do
			local data = currentModuleData[i]
			if ModuleIsValid(data.level, data.chassis, data.slotAllows, i) then
				newCost = newCost + moduleDefs[GetSlotModule(i, data.empty)].cost
			else
				requireUpdate = true
				ModuleReplacmentWithButton(i, data.empty)
			end
		end
		if not requireUpdate then
			break
		end
	end
	
	UpdateMorphCost(newCost)
	
	-- Update each replacement set
	for i = 1, #currentModuleData do
		local data = currentModuleData[i]
		data.replacementSet = GetNewReplacementSet(data.level, data.chassis, data.slotAllows, i)
	end
	
	ShowModuleSelection(currentModuleData[activeSlotIndex].replacementSet)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Main Module Window Handling

local mainWindowShown = false
local mainWindow, timeLabel, costLabel, morphBuildPower

function UpdateMorphCost(newCost)
	newCost = (newCost or 0) + morphBaseCost
	costLabel:SetCaption(math.floor(newCost))
	timeLabel:SetCaption(math.floor(newCost/morphBuildPower))
end

local function HideMainWindow()
	if mainWindowShown then
		SaveModuleLoadout()
		screen0:RemoveChild(mainWindow)
		mainWindowShown = false
	end
	HideModuleSelection()
end

local function CreateMainWindow()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local minimapHeight = screenWidth/6 + 45
	
	local mainHeight = math.min(420, math.max(325, screenHeight - 450))
	
	mainWindow = Window:New{
		classname = "main_window_small_tall",
		name = "CommanderUpgradeWindow",
		fontsize = 20,
		x = 0,  
		y = minimapHeight, 
		width = 201,
		height = 332,
		minWidth = 201,
		minHeight = 332,
		resizable = false,
		draggable = false,
		dockable = true,
		dockableSavePositionOnly = true,
		tweakDraggable = true,
		tweakResizable = true,
		parent = screen0,
	}
	
	mainWindowShown = true

	-- The rest of the window is organized top to bottom
	local topLabel = Chili.Label:New{
		x      = 0,
		right  = 0,
		y      = 0,
		height = 35,
		valign = "center",
		align  = "center",
		caption = "Modules",
		autosize = false,
		font   = {size = 20, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
		parent = mainWindow,
	}
	
	currentModuleList = StackPanel:New{  
		x = 3,  
		right = 2,
		y = 36, 
		bottom = 0,
		padding = {0, 0, 0, 0},	
		itemPadding = {2,2,2,2},
		itemMargin  = {0,0,0,0},
		backgroundColor = {1, 1, 1, 0.8},
		resizeItems = false,
		centerItems = false,
		parent = mainWindow,
	}
	
	local cyan = {0,1,1,1}
	
	local timeImage = Image:New{
		x = 15,
		bottom  = 75,
		file ='LuaUI/images/clock.png',
		height = 24,
		width = 24, 
		keepAspect = true,
		parent = mainWindow,
	}
	
	timeLabel = Chili.Label:New{
		x = 42,
		right  = 0,
		bottom  = 80,
		valign = "top",
		align  = "left",
		caption = 0,
		autosize = false,
		font    = {size = 24, outline = true, color = cyan, outlineWidth = 2, outlineWeight = 2},
		parent = mainWindow,
	}
	
	local costImage = Image:New{
		x = 92,
		bottom  = 75,
		file ='LuaUI/images/costIcon.png',
		height = 24,
		width = 24, 
		keepAspect = true,
		parent = mainWindow,
	}
	
	costLabel = Chili.Label:New{
		x = 118,
		right  = 0,
		bottom  = 80,
		valign = "top",
		align  = "left",
		caption = 0,
		autosize = false,
		font     = {size = 24, outline = true, color = cyan, outlineWidth = 2, outlineWeight = 2},
		parent = mainWindow,
	}
	
	local acceptButton = Button:New{
		caption = "",
		x = 4,
		bottom = 5,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		tooltip = "Start upgrade",
		OnClick = {
			function()
				if mainWindowShown then
					SendUpgradeCommand(GetCurrentModules())
				end
			end
		},
		parent = mainWindow,
	}
	
	viewAlreadyOwnedButton = Button:New{
		caption = "",
		x = 63,
		bottom = 5,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		tooltip = "View current modules",
		OnClick = {
			function(self)
				AlreadyOwnedModuleClick(self)
			end
		},
		parent = mainWindow,
	}
	
	local cancelButton = Button:New{
		caption = "",
		x = 121,
		bottom = 5,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		tooltip = "Cancel module selection",
		OnClick = {
			function()
				--Spring.Echo("Upgrade UI Debug - Cancel Clicked")
				HideMainWindow()
			end
		},
		parent = mainWindow,
	}
	
	Image:New{
		x = 2,
		right = 2,
		y = 0,
		bottom = 0,
		keepAspect = true,
		file = "LuaUI/Images/dynamic_comm_menu/tick.png",
		parent = acceptButton,
	}
	
	Image:New{
		x = 2,
		right = 2,
		y = 0,
		bottom = 0,
		keepAspect = true,
		file = "LuaUI/Images/dynamic_comm_menu/eye.png",
		parent = viewAlreadyOwnedButton,
	}
	
	Image:New{
		x = 2,
		right = 2,
		y = 0,
		bottom = 0,
		keepAspect = true,
		file = "LuaUI/Images/commands/Bold/cancel.png",
		parent = cancelButton,
	}
end

local function ShowModuleListWindow(slotDefaults, level, chassis, alreadyOwnedModules)
	if not currentModuleList then
		CreateMainWindow()
	end
	
	if level > chassisDefs[chassis].maxNormalLevel then
		morphBaseCost = chassisDefs[chassis].extraLevelCostFunction(level)
		level = chassisDefs[chassis].maxNormalLevel
		morphBuildPower = chassisDefs[chassis].levelDefs[level].morphBuildPower
	else
		morphBaseCost = chassisDefs[chassis].levelDefs[level].morphBaseCost
		morphBuildPower = chassisDefs[chassis].levelDefs[level].morphBuildPower
	end
	
	local slots = chassisDefs[chassis].levelDefs[level].upgradeSlots

	if not mainWindowShown then
		screen0:AddChild(mainWindow)
		mainWindowShown = true
	end
	
	-- Removes all previous children
	for i = #currentModuleList.children, 1, -1  do
		currentModuleList:RemoveChild(currentModuleList.children[i])
	end
	
	ClearActiveButton()
	HideModuleSelection()
	ResetCurrentModuleData()
	ResetCurrentModules(alreadyOwnedModules)
	
	-- Data is added here to generate reasonable replacementSets in actual adding.
	for i = 1, #slots do
		local slotData = slots[i]
		UpdateSlotModule(i, (slotDefaults and slotDefaults[i]) or slotData.defaultModule)
	end
	
	-- Check that the module in each slot is valid
	local requireUpdate = true
	local newCost = 0
	for repeatBreak = 1, 2 * #slots do
		requireUpdate = false
		newCost = 0
		for i = 1, #slots do
			local slotData = slots[i]
			if ModuleIsValid(level, chassis, slotData.slotAllows, i) then
				newCost = newCost + moduleDefs[GetSlotModule(i, slotData.empty)].cost
			else
				requireUpdate = true
				UpdateSlotModule(i, slotData.empty)
			end
		end
		if not requireUpdate then
			break
		end
	end
	
	UpdateMorphCost(newCost)
	
	-- Actually add the default modules and slot data
	for i = 1, #slots do
		local slotData = slots[i]
		currentModuleList:AddChild(GetCurrentModuleButton(GetSlotModule(i, slotData.empty), i, level, chassis, slotData.slotAllows, slotData.empty))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local upgradeSignature = {}
local savedSlotLoadout = {}

function SendUpgradeCommand(newModules)
	table.sort(upgradeSignature.alreadyOwned)

	-- Find selected eligible units
	local units = Spring.GetSelectedUnits()
	local upgradableUnits = {}
	for i = 1, #units do
		local unitID = units[i]
		local level = Spring.GetUnitRulesParam(unitID, "comm_level")
		local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
		if level == upgradeSignature.level and chassis == upgradeSignature.chassis then
			local alreadyOwned = {}
			local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
			for i = 1, moduleCount do
				local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
				alreadyOwned[#alreadyOwned + 1] = module
			end
			
			table.sort(alreadyOwned)
			
			if upgradeUtilities.ModuleSetsAreIdentical(alreadyOwned, upgradeSignature.alreadyOwned) then
				upgradableUnits[#upgradableUnits + 1] = unitID
			end
		end
	end
	
	-- Create upgrade command params and issue it to units.
	if #upgradableUnits > 0 then
		local params = {}
		params[1] = upgradeSignature.level
		params[2] = upgradeSignature.chassis
		params[3] = #upgradeSignature.alreadyOwned
		params[4] = #newModules
		
		local index = 5
		for j = 1,  #upgradeSignature.alreadyOwned do
			params[index] = upgradeSignature.alreadyOwned[j]
			index = index + 1
		end
		for j = 1,  #newModules do
			params[index] = newModules[j]
			index = index + 1
		end
		Spring.GiveOrderToUnitArray(upgradableUnits, CMD_MORPH_UPGRADE_INTERNAL, params, 0)
	end
	
	-- Remove main window
	--Spring.Echo("Upgrade UI Debug - Upgrade Command Sent")
	HideMainWindow()
end

function SaveModuleLoadout()
	local currentModules = GetCurrentModules()
	if not (upgradeSignature and currentModules) then
		return
	end
	local profileID = upgradeSignature.profileID
	local level = upgradeSignature.level
	if not (profileID and level) then
		return
	end
	savedSlotLoadout[profileID] = savedSlotLoadout[profileID] or {}
	savedSlotLoadout[profileID][level] = GetCurrentModules()
end

local function CreateModuleListWindowFromUnit(unitID)
	local level = Spring.GetUnitRulesParam(unitID, "comm_level")
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	local profileID = Spring.GetUnitRulesParam(unitID, "comm_profileID")
	
	if not (chassisDefs[chassis] and chassisDefs[chassis].levelDefs[math.min(chassisDefs[chassis].maxNormalLevel, level+1)]) then
		return
	end
	
	-- Find the modules which are already owned
	local alreadyOwned = {}
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	for i = 1, moduleCount do
		local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
		alreadyOwned[#alreadyOwned + 1] = module
	end
	
	-- Record the signature of the morphing unit for later application.
	upgradeSignature.level = level
	upgradeSignature.chassis = chassis
	upgradeSignature.profileID = profileID
	upgradeSignature.alreadyOwned = alreadyOwned
	
	-- Load default loadout
	local slotDefaults = {}
	if profileID and level then
		if savedSlotLoadout[profileID] and savedSlotLoadout[profileID][level] then
			slotDefaults = savedSlotLoadout[profileID][level]
		else
			local commProfileInfo = WG.ModularCommAPI.GetCommProfileInfo(profileID)
			if commProfileInfo and commProfileInfo.modules and commProfileInfo.modules[level + 1] then
				local defData = commProfileInfo.modules[level + 1]
				for i = 1, #defData do
					slotDefaults[i] = moduleDefNames[defData[i]]
				end
			end
		end
	end
	
	-- Create the window
	ShowModuleListWindow(slotDefaults, level + 1, chassis, alreadyOwned)
end

local function GetCommanderUpgradeAttributes(unitID, cullMorphing)
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not commanderUnitDefID[unitDefID] then
		return false
	end
	if cullMorphing and Spring.GetUnitRulesParam(unitID, "morphing") == 1 then
		return false
	end
	local level = Spring.GetUnitRulesParam(unitID, "comm_level")
	if not level then
		return false
	end
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	local staticLevel = Spring.GetUnitRulesParam(unitID, "comm_staticLevel")
	return level, chassis, staticLevel
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_UPGRADE_UNIT then
		return false
	end
	
	local units = Spring.GetSelectedUnits()
	local upgradeID = false
	for i = 1, #units do
		local unitID = units[i]
		local level, chassis, staticLevel = GetCommanderUpgradeAttributes(unitID, true)
		if level and (not staticLevel) and chassis and (not LEVEL_BOUND or level < LEVEL_BOUND) then
			upgradeID = unitID
			break
		end
	end
	
	if not upgradeID then
		return true
	end
	
	CreateModuleListWindowFromUnit(upgradeID)
	return true
end

local cachedSelectedUnits
function widget:SelectionChanged(selectedUnits)
	cachedSelectedUnits = selectedUnits
end

function widget:CommandsChanged()
	local units = cachedSelectedUnits or Spring.GetSelectedUnits()
	if mainWindowShown then
		--Spring.Echo("Upgrade UI Debug - Number of units selected", #units)
		local foundMatchingComm = false
		for i = 1, #units do
			local unitID = units[i]
			local level, chassis, staticLevel = GetCommanderUpgradeAttributes(unitID)
			if level and (not staticLevel) and level == upgradeSignature.level and chassis == upgradeSignature.chassis then
				local alreadyOwned = {}
				local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
				for i = 1, moduleCount do
					local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
					alreadyOwned[#alreadyOwned + 1] = module
				end
				
				table.sort(alreadyOwned)
				
				if upgradeUtilities.ModuleSetsAreIdentical(alreadyOwned, upgradeSignature.alreadyOwned) then
					foundMatchingComm = true
					break
				end
			end
		end
		
		if foundMatchingComm then
			local customCommands = widgetHandler.customCommands
			customCommands[#customCommands+1] = UPGRADE_CMD_DESC
		else
			----Spring.Echo("Upgrade UI Debug - Commander Deselected")
			HideMainWindow() -- Hide window if no commander matching the window is selected
		end
	end
	
	if not mainWindowShown then
		local foundRulesParams = false
		for i = 1, #units do
			local unitID = units[i]
			local level, chassis, staticLevel = GetCommanderUpgradeAttributes(unitID, true)
			if level and (not staticLevel) and chassis and (not LEVEL_BOUND or level < LEVEL_BOUND) then
				foundRulesParams = true
				break
			end
		end
		
		if foundRulesParams then
			local customCommands = widgetHandler.customCommands

			customCommands[#customCommands+1] = {
				id      = CMD_UPGRADE_UNIT,
				type    = CMDTYPE.ICON,
				tooltip = 'Upgrade Commander',
				cursor  = 'Repair',
				action  = 'upgradecomm',
				params  = {}, 
				texture = 'LuaUI/Images/commands/Bold/upgrade.png',
			}
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	screen0 = Chili.Screen0

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------