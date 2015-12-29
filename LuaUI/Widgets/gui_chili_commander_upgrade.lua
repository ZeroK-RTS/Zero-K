--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Commander Upgrade",
    desc      = "Interface for commander upgrade selection.",
    author    = "GoogleFrog",
    date      = "29 December 2015",
    license   = "GNU GPL, v2 or later",
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
local Colorbars
local Checkbox
local Window
local Panel
local ScrollPanel
local StackPanel
local LayoutPanel
local Grid
local Trackbar
local TextBox
local Image
local Progressbar
local Colorbars
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
-- * Callins. This block handles widget callins. Should check whether the target
--   unit is still alive etc..

local BUTTON_SIZE = 55
local ROW_COUNT = 6

-- Index of module which is selected for the purposes of replacement.
local activeSlotIndex

-- StackPanel containing the buttons for the current list of modules
local currentModuleList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- WIP config, move to a seperate file when done

local moduleDefs = {
	{
		name = "Health Thingy",
		description = "Health Thingy",
		image = "unitpics/module_ablative_armor.png",
		limit = 3,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "Big Health Thingy",
		description = "Big Health Thingy",
		image = "unitpics/module_heavy_armor.png",
		limit = 3,
		requireModules = {1},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "Skull Thingy",
		description = "Skull Thingy",
		image = "unitpics/module_dmg_booster.png",
		limit = 3,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "Gun Thingy",
		description = "Gun Thingy",
		image = "unitpics/commweapon_beamlaser.png",
		limit = 1,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
	{
		name = "nullmodule",
		description = "No Module",
		image = "LuaUI/Images/commands/Bold/cancel.png",
		limit = false,
		requireModules = {},
		requireLevel = 0,
		slotType = "module",
	},
	{
		name = "nullweapon",
		description = "No Weapon",
		image = "LuaUI/Images/commands/Bold/cancel.png",
		limit = false,
		requireModules = {},
		requireLevel = 0,
		slotType = "weapon",
	},
}

local emptyModule = {}
for i = 1, #moduleDefs do
	if moduleDefs[i].name == "nullmodule" then
		emptyModule.module = i
	elseif moduleDefs[i].name == "nullweapon" then
		emptyModule.weapon = i
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- New Module Selection Button Handling

local newButtons = {}

local function AddNewSelectonButton(moduleDefID)
	local moduleData = moduleDefs[moduleDefID]
	local newButton = Button:New{
		caption = "",
		width = BUTTON_SIZE,
		minHeight = BUTTON_SIZE,
		padding = {0, 0, 0, 0},	
		OnClick = { 
			function() 
				SelectNewModule(moduleDefID)
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
	
	newButtons[moduleDefID] = newButton
end

local function GetNewSelectionButton(moduleDefID)
	if not newButtons[moduleDefID] then
		AddNewSelectonButton(moduleDefID)
	end
	return newButtons[moduleDefID]
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

local function ShowModuleSelection(moduleSet)
	if not selectionWindow then
		selectionWindow = CreateModuleSelectionWindow()
	end
	
	local panel = selectionWindow.panel
	local fakeWindow = selectionWindow.fakeWindow
	local window = selectionWindow.window
	
	-- Removes all previous children
	for i = #panel.children, 1, -1  do
		panel:RemoveChild(panel.children[i])
	end
	
	-- Resize window to fit module count
	local moduleCount = #moduleSet
	local rows, columns
	if moduleCount < 3*ROW_COUNT then
		columns = math.min(moduleCount, 3)
		rows = math.ceil(moduleCount/3)
	else
		columns = math.ceil(moduleCount/ROW_COUNT)
		rows = math.ceil(moduleCount/columns)
	end
	
	panel.columns = columns
	window:Resize(columns*BUTTON_SIZE + 10, rows*BUTTON_SIZE + 10)
	fakeWindow:Resize(columns*BUTTON_SIZE + 10, rows*BUTTON_SIZE + 10)
	
	-- Add all required buttons
	for i = 1, moduleCount do
		panel:AddChild(GetNewSelectionButton(moduleSet[i]))
	end

	-- Display window if not already shown
	if not selectionWindow.windowShown then
		selectionWindow.windowShown = true
		screen0:AddChild(window)
	end
end

local function HideModuleSelection()
	if selectionWindow.windowShown then
		selectionWindow.windowShown = false
		screen0:RemoveChild(selectionWindow.window)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Keep track of the current modules and generate restrictions

local alreadyOwnedModules = {} -- by moduleDefID

local currentModulesBySlot = {}
local currentModulesByDefID = {}

local function ResetCurrentModules(newAlreadyOwned)
	currentModulesBySlot = {}
    currentModulesByDefID = {}
	alreadyOwnedModules = newAlreadyOwned
end

local function GetSlotModule(slot, slotType)
	return currentModulesBySlot[slot] or emptyModule[slotType]
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

local function ModuleIsValid(level, slotType, slotIndex)
	local moduleDefID = currentModulesBySlot[slotIndex]
	local data = moduleDefs[moduleDefID]
	if data.slotType ~= slotType or (data.requireLevel or 0) > level then
		return false
	end
	
	-- Check that requirements are met
	if data.requireModules then
		for j = 1, #data.requireModules do
			-- Modules should not depend on themselves so this check is simplier than the
			-- corresponding chcek in the replacement set generator.
			if not (alreadyOwnedModules[j] or currentModulesByDefID[j]) then
				return false
			end
		end
	end
	
	-- Check that the module limit is not reached
	if data.limit and (currentModulesByDefID[moduleDefID] or alreadyOwnedModules[moduleDefID]) then
		local count = (currentModulesByDefID[moduleDefID] or 0) + (alreadyOwnedModules[moduleDefID] or 0) 
		if count > data.limit then
			return false
		end
	end
	return true
end

local function GetNewReplacementSet(level, slotType, ignoreSlot)
	local replacementSet = {}
	for i = 1, #moduleDefs do
		local data = moduleDefs[i]
		if data.slotType == slotType and (data.requireLevel or 0) <= level then
			local accepted = true
			
			-- Check whether required modules are present, not counting ignored slot
			if data.requireModules then
				for j = 1, #data.requireModules do
					if not (alreadyOwnedModules[j] or 
						(currentModulesByDefID[j] and 
							(currentModulesBySlot[ignoreSlot] ~= j or 
							currentModulesByDefID[j] > 1))) then
						
						accepted = false
						break
					end
				end
			end
			
			-- Check against module limit, not counting ignored slot
			if accepted and data.limit and (currentModulesByDefID[i] or alreadyOwnedModules[i]) then
				local count = (currentModulesByDefID[i] or 0) + (alreadyOwnedModules[i] or 0) 
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

local function CurrentModuleClick(self, slotIndex)
	if (not activeSlotIndex) or activeSlotIndex ~= slotIndex then
		if activeSlotIndex then
			currentModuleList.children[activeSlotIndex].backgroundColor = {0.5,0.5,0.5,0.5}
			currentModuleList.children[activeSlotIndex]:Invalidate()
		end
		self.backgroundColor = {0,1,0,1}
		activeSlotIndex = slotIndex
		ShowModuleSelection(currentModuleData[slotIndex].replacementSet)
	else
		self.backgroundColor = {0.5,0.5,0.5,0.5}
		activeSlotIndex = false
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

local function GetCurrentModuleButton(moduleDefID, slotIndex, level, slotType)
	if not currentModuleButton[slotIndex] then
		AddCurrentModuleButton(slotIndex, moduleDefID)
	end
	
	currentModuleData[slotIndex] = currentModuleData[slotIndex] or {}
	local current = currentModuleData[slotIndex]
	
	current.level = level
	current.slotType = slotType
	current.replacementSet = GetNewReplacementSet(level, slotType, slotIndex)

	UpdateSlotModule(slotIndex, moduleDefID)
	
	return currentModuleButton[slotIndex]
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

function SelectNewModule(moduleDefID)
	ModuleReplacmentWithButton(activeSlotIndex, moduleDefID)
	
	-- Check whether module choices are still valid
	local requireUpdate = true
	while requireUpdate do
		requireUpdate = false
		for i = 1, #currentModuleData do
			local data = currentModuleData[i]
			if not ModuleIsValid(data.level, data.slotType, i) then
				requireUpdate = true
				ModuleReplacmentWithButton(i, emptyModule[data.slotType])
			end
		end
	end
	
	-- Update each replacement set
	for i = 1, #currentModuleData do
		local data = currentModuleData[i]
		data.replacementSet = GetNewReplacementSet(data.level, data.slotType, i)
	end
	
	ShowModuleSelection(currentModuleData[activeSlotIndex].replacementSet)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Main Module Window Handling

local function CreateMainWindow()
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
	
	local cancelButton = Button:New{
		caption = "Cancel",
		x = "52%",
		bottom = 15,
		width = 65,
		height = 65,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function()
			
			end
		},
	}
	
	local acceptButton = Button:New{
		caption = "Accept",
		right = "52%",
		bottom = 15,
		width = 65,
		height = 65,
		padding = {0, 0, 0, 0},	
		backgroundColor = {0.5,0.5,0.5,0.5},
		OnClick = {
			function()
			
			end
		},
	}
	
	local fakeWindow = Panel:New{  
		fontsize = 20,
		x = 0,  
		right = 0,
		y = 0, 
		bottom = 0,
		padding = {0, 0, 0, 0},	
		backgroundColor = {1, 1, 1, 0.8},
		children = {topLabel, currentModuleList, cancelButton, acceptButton}
	}
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local minimapHeight = screenWidth/6 + 45
	
	local mainWindow = Window:New{
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
		children = {fakeWindow}
	}
end

local function ShowModuleListWindow(slots, level, alreadyOwnedModules)
	if not currentModuleList then
		CreateMainWindow()
	end

	-- Removes all previous children
	for i = #currentModuleList.children, 1, -1  do
		currentModuleList:RemoveChild(currentModuleList.children[i])
	end
	
	ResetCurrentModuleData()
	ResetCurrentModules(alreadyOwnedModules)
	
	-- Data is added here to generate reasonable replacementSets in actual adding.
	for i = 1, #slots do
		local slotData = slots[i]
		UpdateSlotModule(i, slotData.defaultModule)
	end
	
	-- Check that the module in each slot is valid
	for i = 1, #slots do
		local slotData = slots[i]
		if not ModuleIsValid(level, slotData.slotType, i) then
			UpdateSlotModule(i, emptyModule[slotData.slotType])
		end
	end
	
	-- Actually add the default modules and slot data
	for i = 1, #slots do
		local slotData = slots[i]
		currentModuleList:AddChild(GetCurrentModuleButton(GetSlotModule(i, slotData.slotType), i, level, slotData.slotType))
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
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	LayoutPanel = Chili.LayoutPanel
	Grid = Chili.Grid
	Trackbar = Chili.Trackbar
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Colorbars = Chili.Colorbars
	screen0 = Chili.Screen0

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	slotDefs = {
		{
			defaultModule = 4,
			slotType = "weapon",
		},
		{
			defaultModule = 1,
			slotType = "module",
		},
		{
			defaultModule = 1,
			slotType = "module",
		},
		{
			defaultModule = 6,
			slotType = "weapon",
		},
	}
	
	ShowModuleListWindow(slotDefs, 3, {})
end

function widget:Update()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------