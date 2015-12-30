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
    layer     = 0,
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
local moduleDefs, emptyModules, chassisDefs = VFS.Include("LuaRules/Configs/dynamic_comm_defs.lua")

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
	if newButtons[moduleDefID] then
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
	alreadyOwnedModulesByDefID = {}
	for i = 1, #newAlreadyOwned do
		local defID = newAlreadyOwned[i]
		alreadyOwnedModulesByDefID[defID] = (alreadyOwnedModulesByDefID[defID] or 0) + 1
	end
end

local function GetCurrentModules()
	return currentModulesBySlot
end

local function GetAlreadyOwned()
	return alreadyOwnedModules
end

local function GetSlotModule(slot, slotType)
	return currentModulesBySlot[slot] or emptyModules[slotType]
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

local function ModuleIsValid(level, chassis, slotType, slotIndex)
	local moduleDefID = currentModulesBySlot[slotIndex]
	local data = moduleDefs[moduleDefID]
	if data.slotType ~= slotType or (data.requireLevel or 0) > level or (data.requireChassis and (not data.requireChassis[chassis])) then
		return false
	end
	
	-- Check that requirements are met
	if data.requireModules then
		for j = 1, #data.requireModules do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			local req = data.requireModules[j]
			if not (alreadyOwnedModulesByDefID[req] or currentModulesByDefID[req]) then
				return false
			end
		end
	end
	
	-- Check that the module limit is not reached
	if data.limit and (currentModulesByDefID[moduleDefID] or alreadyOwnedModulesByDefID[moduleDefID]) then
		local count = (currentModulesByDefID[moduleDefID] or 0) + (alreadyOwnedModulesByDefID[moduleDefID] or 0) 
		if count > data.limit then
			return false
		end
	end
	return true
end

local function GetNewReplacementSet(level, chassis, slotType, ignoreSlot)
	local replacementSet = {}
	for i = 1, #moduleDefs do
		local data = moduleDefs[i]
		if data.slotType == slotType and (data.requireLevel or 0) <= level and ((not data.requireChassis) or data.requireChassis[chassis]) then
			local accepted = true
			
			-- Check whether required modules are present, not counting ignored slot
			if data.requireModules then
				for j = 1, #data.requireModules do
					local req = data.requireModules[j]
					if not (alreadyOwnedModulesByDefID[req] or 
						(currentModulesByDefID[req] and 
							(currentModulesBySlot[ignoreSlot] ~= req or 
							currentModulesByDefID[req] > 1))) then
						
						accepted = false
						break
					end
				end
			end
			
			-- Check against module limit, not counting ignored slot
			if accepted and data.limit and (currentModulesByDefID[i] or alreadyOwnedModulesByDefID[i]) then
				local count = (currentModulesByDefID[i] or 0) + (alreadyOwnedModulesByDefID[i] or 0) 
				if currentModulesBySlot[ignoreSlot] == i then
					count = count - 1
				end
				if count >= data.limit then
					accepted = false
				end
			end
			
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
	UpdateSlotModule(slotIndex, moduleDefID)
end

local function GetCurrentModuleButton(moduleDefID, slotIndex, level, chassis, slotType)
	if not currentModuleButton[slotIndex] then
		AddCurrentModuleButton(slotIndex, moduleDefID)
	end
	
	currentModuleData[slotIndex] = currentModuleData[slotIndex] or {}
	local current = currentModuleData[slotIndex]
	
	current.level = level
	current.chassis = chassis
	current.slotType = slotType
	current.replacementSet = GetNewReplacementSet(level, chassis, slotType, slotIndex)

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
	while requireUpdate do
		requireUpdate = false
		for i = 1, #currentModuleData do
			local data = currentModuleData[i]
			if not ModuleIsValid(data.level, data.chassis, data.slotType, i) then
				requireUpdate = true
				ModuleReplacmentWithButton(i, emptyModules[data.slotType])
			end
		end
	end
	
	-- Update each replacement set
	for i = 1, #currentModuleData do
		local data = currentModuleData[i]
		data.replacementSet = GetNewReplacementSet(data.level, data.chassis, data.slotType, i)
	end
	
	ShowModuleSelection(currentModuleData[activeSlotIndex].replacementSet)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Main Module Window Handling

local mainWindowShown = false
local mainWindow

local function HideMainWindow()
	if mainWindowShown then
		screen0:RemoveChild(mainWindow)
		mainWindowShown = false
	end
	HideModuleSelection()
end

local function CreateMainWindow()
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local minimapHeight = screenWidth/6 + 45
	
	mainWindow = Window:New{
		fontsize = 20,
		x = 0,  
		y = minimapHeight, 
		clientWidth = 200,
		clientHeight = 400,
		minWidth = 100,
		minHeight = 350,	
		padding = {0, 0, 0, 0},	
		resizable = false,
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		parent = screen0,
		color = {0,0,0,0},
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
	}
	
	currentModuleList = StackPanel:New{  
		x = 0,  
		right = 0,
		y = 40, 
		bottom = 0,
		padding = {0, 0, 0, 0},	
		itemPadding = {2,2,2,2},
		itemMargin  = {0,0,0,0},
		backgroundColor = {1, 1, 1, 0.8},
		resizeItems = false,
		centerItems = false,
	}
	
	local timeLabel = Chili.Label:New{
		x = 20,
		right  = 0,
		bottom  = 110,
		height = 35,
		valign = "center",
		align  = "left",
		caption = "Time:",
		autosize = false,
		font   = {size = 20, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
	}
	
	local costLabel = Chili.Label:New{
		x = 20,
		right  = 0,
		bottom  = 80,
		height = 35,
		valign = "center",
		align  = "left",
		caption = "Cost:",
		autosize = false,
		font   = {size = 20, outline = true, color = {.8,.8,.8,.9}, outlineWidth = 2, outlineWeight = 2},
	}
	
	local acceptButton = Button:New{
		caption = "tick",
		right = 135,
		bottom = 15,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function()
				if mainWindowShown then
					SendUpgradeCommand(GetCurrentModules())
				end
			end
		},
	}
	
	viewAlreadyOwnedButton = Button:New{
		caption = "eye",
		right = 75,
		bottom = 15,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function(self)
				AlreadyOwnedModuleClick(self)
			end
		},
	}
	
	local cancelButton = Button:New{
		caption = "cross",
		right = 15,
		bottom = 15,
		width = 55,
		height = 55,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function()
				HideMainWindow()
			end
		},
	}
	
	local fakeWindow = Panel:New{
		parent = mainWindow,
		fontsize = 20,
		x = 0,  
		right = 0,
		y = 0, 
		bottom = 0,
		padding = {0, 0, 0, 0},	
		backgroundColor = {1, 1, 1, 0.8},
		children = {topLabel, currentModuleList, timeLabel, costLabel, acceptButton, viewAlreadyOwnedButton, cancelButton}
	}
end

local function ShowModuleListWindow(slots, slotDefaults, level, chassis, alreadyOwnedModules)
	if not currentModuleList then
		CreateMainWindow()
	end

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
	for i = 1, #slots do
		local slotData = slots[i]
		if not ModuleIsValid(level, chassis, slotData.slotType, i) then
			UpdateSlotModule(i, emptyModules[slotData.slotType])
		end
	end
	
	-- Actually add the default modules and slot data
	for i = 1, #slots do
		local slotData = slots[i]
		currentModuleList:AddChild(GetCurrentModuleButton(GetSlotModule(i, slotData.slotType), i, level, chassis, slotData.slotType))
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local upgradeSignature = {}

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
			local weaponCount = Spring.GetUnitRulesParam(unitID, "comm_weapon_count")
			for i = 1, weaponCount do
				local weapon = Spring.GetUnitRulesParam(unitID, "comm_weapon_" .. i)
				alreadyOwned[#alreadyOwned + 1] = weapon
			end
			
			local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
			for i = 1, moduleCount do
				local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
				alreadyOwned[#alreadyOwned + 1] = module
			end
			
			table.sort(alreadyOwned)
			
			if #alreadyOwned == #upgradeSignature.alreadyOwned then
				local validUnit = true
				for i = 1, #alreadyOwned do
					if alreadyOwned[i] ~= upgradeSignature.alreadyOwned[i] then
						validUnit = false
						break
					end
				end
				if validUnit then
					upgradableUnits[#upgradableUnits + 1] = unitID
				end
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
		Spring.GiveOrderToUnitArray(upgradableUnits, CMD_MORPH_UPGRADE, params, {})
	end
	
	-- Remove main window
	HideMainWindow()
end

local function CreateModuleListWindowFromUnit(unitID)
	local level = Spring.GetUnitRulesParam(unitID, "comm_level")
	local chassis = Spring.GetUnitRulesParam(unitID, "comm_chassis")
	
	local slotDefs = chassisDefs[chassis].upgradeSlots[level+1]
	
	-- Find the modules which are already owned
	local alreadyOwned = {}
	local weaponCount = Spring.GetUnitRulesParam(unitID, "comm_weapon_count")
	for i = 1, weaponCount do
		local weapon = Spring.GetUnitRulesParam(unitID, "comm_weapon_" .. i)
		alreadyOwned[#alreadyOwned + 1] = weapon
	end
	
	local moduleCount = Spring.GetUnitRulesParam(unitID, "comm_module_count")
	for i = 1, moduleCount do
		local module = Spring.GetUnitRulesParam(unitID, "comm_module_" .. i)
		alreadyOwned[#alreadyOwned + 1] = module
	end
	
	-- Record the signature of the morphing unit for later application.
	upgradeSignature.level = level
	upgradeSignature.chassis = chassis
	upgradeSignature.alreadyOwned = alreadyOwned
	
	-- Create the window
	windowOpen = true
	ShowModuleListWindow(slotDefs, slotDefaults, level, chassis, alreadyOwned)
end

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD_UPGRADE_UNIT then
		return false
	end
	
	local units = Spring.GetSelectedUnits()
	local upgradeID = false
	for i = 1, #units do
		local unitID = units[i]
		local level = Spring.GetUnitRulesParam(unitID, "comm_level")
		if level and level < 5 then
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

function widget:CommandsChanged()
	local units = Spring.GetSelectedUnits()
	local foundRulesParams = false
	for i = 1, #units do
		local unitID = units[i]
		local level = Spring.GetUnitRulesParam(unitID, "comm_level")
		if level and level < 5 then
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
			texture = 'LuaUI/Images/commands/Bold/build.png',
		}
	else
		HideMainWindow() -- Hide window if upgradables are deselected
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