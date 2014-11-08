
function widget:GetInfo()
  return {
    name      = "HUD Presets",
    desc      = "Sets the default UI and provides presets for different HUD setups.",
    author    = "Google Frog",
    date      = "24 August, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 51,
    enabled   = true,
    handler   = true,
  }
end

----------------------------------------------------
-- widget option functions

local function Selections_SetOptions(group, showInfo, square, iconSize, showCommand, showDgun, alwaysShow)
	local widgetName, path = "Chili Selections & CursorTip","Settings/HUD Panels/Selected Units Window"
	WG.SetWidgetOption(widgetName, path, "groupalways",group)
	WG.SetWidgetOption(widgetName, path, "showgroupinfo",showInfo)
	WG.SetWidgetOption(widgetName, path, "squarepics",square)
	WG.SetWidgetOption(widgetName, path, "uniticon_size",iconSize)
	WG.SetWidgetOption(widgetName, path, "manualWeaponReloadBar",showDgun)
	WG.SetWidgetOption(widgetName, path, "unitCommand",showCommand)
	WG.SetWidgetOption(widgetName, path, "alwaysShowSelectionWin",alwaysShow)
end

----------------------------------------------------
----------------------------------------------------
-- Useful Functions
----------------------------------------------------
local function GetSelectionIconSize(height)
	local fitNumber = math.floor((height - 20)/(44 + 2))
	local size = math.floor((height - 20)/fitNumber - 2)
	return math.min(50, size)
end

----------------------------------------------------
-- Default Preset
----------------------------------------------------
local function SetupDefaultPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili FactoryBar")
	widgetHandler:DisableWidget("Chili FactoryPanel")
	widgetHandler:DisableWidget("Chili Gesture Menu")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip")
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Minimap
	local minimapWidth = screenWidth*2/11
	local minimapHeight = screenWidth*2/11 + 20
	WG.Minimap_SetOptions("arwindow", 0, false, false, false)
	WG.SetWindowPosAndSize("Minimap Window", 
		0, 
		0, 
		minimapWidth,
		minimapHeight
	)

	-- Integral Menu
	local integralWidth = math.max(350, math.min(480, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	WG.SetWindowPosAndSize("integralwindow",
		0,
		screenHeight - integralHeight,
		integralWidth,
		integralHeight
	)
	
	-- Selection Bar
	local selectorButtonWidth = math.min(60, screenHeight/16)
	local selectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(integralWidth/selectorButtonWidth)))
	local selectorWidth = selectorButtonWidth*selectionButtonCount
	WG.CoreSelector_SetOptions(selectionButtonCount)
	WG.SetWindowPosAndSize("selector_window", 
		0, 
		screenHeight - selectorHeight - integralHeight, 
		selectorWidth, 
		selectorHeight
	)
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = 450
	Selections_SetOptions(false, true, false, GetSelectionIconSize(selectionsHeight), false, true, false)
	WG.SetWindowPosAndSize("selections",
		integralWidth,
		screenHeight - selectionsHeight,
		selectionsWidth,
		selectionsHeight
	)
	
	-- Player List
	local playerlistWidth = 296
	local playerlistHeight = 150
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - playerlistHeight,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	local chatWidth = math.min(screenWidth*0.25, screenWidth - playerlistWidth - integralWidth)
	local chatX = math.max(integralWidth, math.min(screenWidth/2 - chatWidth/2, screenWidth - playerlistWidth - chatWidth))
	local chatY = screenHeight - 2*selectionsHeight
		
	if chatWidth + integralWidth + selectionsWidth + playerlistWidth <= screenWidth then
		chatX = integralWidth + selectionsWidth
		chatY = screenHeight - selectionsHeight
	end
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		chatY,
		chatWidth,
		selectionsHeight
	)
	
	-- Menu
	local menuWidth = 400
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = 390
	local resourceBarHeight = 70
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth)
	WG.SetWindowPosAndSize("EconomyPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	-- Console
	local consoleWidth = math.min(screenWidth * 0.30, screenWidth - minimapWidth)
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		screenWidth - consoleHeight,
		resourceBarHeight,
		consoleWidth,
		consoleHeight
	)
end

----------------------------------------------------
-- Crafty Preset
----------------------------------------------------
local function SetupCraftyPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili FactoryBar")
	widgetHandler:DisableWidget("Chili FactoryPanel")
	widgetHandler:DisableWidget("Chili Gesture Menu")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip")
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Minimap
	local minimapWidth = screenWidth*9/44 + 20
	local minimapHeight = screenWidth*9/44
	WG.Minimap_SetOptions("armap", 0.8, false, true, false)
	WG.SetWindowPosAndSize("Minimap Window", 
		0, 
		screenHeight - minimapHeight, 
		minimapWidth,
		minimapHeight
	)
	
	-- Quick Selection Bar
	local selectorButtonWidth = math.min(60, screenHeight/16)
	local selectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(minimapWidth/selectorButtonWidth)))
	local selectorWidth = selectorButtonWidth*selectionButtonCount
	WG.CoreSelector_SetOptions(selectionButtonCount)
	WG.SetWindowPosAndSize("selector_window", 
		0, 
		screenHeight - minimapHeight - selectorHeight, 
		selectorWidth, 
		selectorHeight
	)
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(500, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	WG.SetWindowPosAndSize("integralwindow",
		screenWidth - integralWidth,
		screenHeight - integralHeight,
		integralWidth,
		integralHeight
	)
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = screenWidth - integralWidth - minimapWidth
	Selections_SetOptions(false, true, false, GetSelectionIconSize(selectionsHeight), false, true, true)
	WG.SetWindowPosAndSize("selections",
		minimapWidth,
		screenHeight - selectionsHeight,
		selectionsWidth,
		selectionsHeight
	)
	
	-- Player List
	local playerlistWidth = 296
	local playerlistHeight = 150
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - integralHeight - playerlistHeight,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	local chatWidth = math.min(screenWidth*0.25, selectionsWidth)
	local chatX = math.max(minimapWidth, math.min(screenWidth/2 - chatWidth/2, screenWidth - integralWidth - chatWidth))
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		screenHeight - 2*selectionsHeight,
		chatWidth,
		selectionsHeight
	)
	
	-- Menu
	local menuWidth = 400
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		0,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = 390
	local resourceBarHeight = 70
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth)
	WG.SetWindowPosAndSize("EconomyPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	-- Console
	local consoleWidth = math.min(screenWidth * 0.30, screenWidth - menuWidth - resourceBarWidth)
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		0,
		0,
		consoleWidth,
		consoleHeight
	)
end


----------------------------------------------------
-- Ensemble Preset
----------------------------------------------------
local function SetupEnsemblePreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili FactoryBar")
	widgetHandler:DisableWidget("Chili FactoryPanel")
	widgetHandler:DisableWidget("Chili Gesture Menu")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip")
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(500, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	WG.SetWindowPosAndSize("integralwindow",
		0,
		screenHeight - integralHeight,
		integralWidth,
		integralHeight
	)
	
	-- Minimap
	local minimapWidth = screenWidth*9/44 + 20
	local minimapHeight = screenWidth*9/44
	WG.Minimap_SetOptions("armap", 0.8, false, true, false)
	WG.SetWindowPosAndSize("Minimap Window", 
		screenWidth - minimapWidth, 
		screenHeight - minimapHeight, 
		minimapWidth,
		minimapHeight
	)
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = screenWidth - integralWidth - minimapWidth
	Selections_SetOptions(false, true, false, GetSelectionIconSize(selectionsHeight), false, true, true)
	WG.SetWindowPosAndSize("selections",
		integralWidth,
		screenHeight - selectionsHeight,
		selectionsWidth,
		selectionsHeight
	)

	-- Quick Selection Bar
	local selectorButtonWidth = math.min(60, screenHeight/16)
	local selectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(integralWidth/selectorButtonWidth)))
	local selectorWidth = selectorButtonWidth*selectionButtonCount
	WG.CoreSelector_SetOptions(selectionButtonCount)
	WG.SetWindowPosAndSize("selector_window", 
		integralWidth, 
		screenHeight - selectionsHeight - selectorHeight, 
		selectorWidth, 
		selectorHeight
	)
	
	-- Player List
	local playerlistWidth = 296
	local playerlistHeight = 150
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - integralHeight - playerlistHeight,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	local chatWidth = math.min(screenWidth*0.25, selectionsWidth)
	local chatX = 0
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		screenHeight - integralHeight,
		chatWidth,
		selectionsHeight
	)
	
	-- Menu
	local menuWidth = 400
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = 390
	local resourceBarHeight = 70
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth)
	WG.SetWindowPosAndSize("EconomyPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	-- Console
	local consoleWidth = math.min(screenWidth * 0.30, screenWidth - menuWidth - resourceBarWidth)
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		0,
		0,
		consoleWidth,
		consoleHeight
	)
end

----------------------------------------------------
-- Westwood Preset
----------------------------------------------------
local function SetupWestwoodPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili FactoryBar")
	widgetHandler:DisableWidget("Chili FactoryPanel")
	widgetHandler:DisableWidget("Chili Gesture Menu")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip")
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Resource Bar
	local resourceBarWidth = screenWidth*5/22 + 20
	local resourceBarHeight = 65
	local resourceBarX = screenWidth - resourceBarWidth
	WG.SetWindowPosAndSize("EconomyPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	-- Minimap
	local minimapWidth = resourceBarWidth
	local minimapHeight = screenWidth*1/4
	WG.Minimap_SetOptions("armap", 0.8, false, true, false)
	WG.SetWindowPosAndSize("Minimap Window", 
		screenWidth - minimapWidth, 
		resourceBarHeight, 
		minimapWidth,
		minimapHeight
	)
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(500, resourceBarWidth))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)
	WG.SetWindowPosAndSize("integralwindow",
		screenWidth - integralWidth,
		resourceBarHeight + minimapHeight,
		integralWidth,
		integralHeight
	)
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = resourceBarWidth
	Selections_SetOptions(false, true, false, GetSelectionIconSize(selectionsHeight), false, true, true)
	WG.SetWindowPosAndSize("selections",
		screenWidth - selectionsWidth,
		screenHeight - selectionsHeight,
		selectionsWidth,
		selectionsHeight
	)
	
	-- Quick Selection Bar
	local selectorButtonWidth = math.min(60, screenHeight/16)
	local selectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(resourceBarWidth/selectorButtonWidth)))
	local selectorWidth = selectorButtonWidth*selectionButtonCount
	WG.CoreSelector_SetOptions(selectionButtonCount)
	WG.SetWindowPosAndSize("selector_window", 
		screenWidth - selectionsWidth, 
		screenHeight - selectionsHeight - selectorHeight, 
		selectorWidth, 
		selectorHeight
	)
	
	-- Player List
	local playerlistWidth = 296
	local playerlistHeight = 150
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth - selectionsWidth,
		screenHeight - playerlistHeight,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	local chatWidth = math.min(screenWidth*0.25, selectionsWidth)
	local chatX = 0
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		screenHeight,
		chatWidth,
		selectionsHeight
	)
	
	-- Menu
	local menuWidth = 400
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		0,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Console
	local consoleWidth = math.min(screenWidth * 0.30, screenWidth - menuWidth - resourceBarWidth)
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		0,
		0,
		consoleWidth,
		consoleHeight
	)
end

----------------------------------------------------
-- Options
----------------------------------------------------
options_path = 'Settings/HUD Presets'
options_order = {'setToDefault', 'presetlabel', 'interfacePresetDefault', 'interfacePresetCrafty', 'interfacePresetEnsemble', 'interfacePresetWestwood'}
options = {
	setToDefault = {
		name  = "Set To Default Once",
		type  = "bool", 
		value = true, 
		desc = "Resets the HUD to the default next time this widget is initialized.",
		advanced = true,
	},
	presetlabel = {
		name = "presetlabel",
		type = 'label', 
		value = "Presets", 
	},
	interfacePresetDefault = {
		name = "Default",
		desc = "The default interface.",
		type = 'button',
		OnChange = SetupDefaultPreset,
	},
	interfacePresetCrafty = {
		name = "Crafty",
		desc = "Interface reminiscent of the craft of war and stars.",
		type = 'button',
		OnChange = SetupCraftyPreset,
	},
	interfacePresetEnsemble = {
		name = "Ensemble",
		desc = "Interface reminiscent of the imperial ages.",
		type = 'button',
		OnChange = SetupEnsemblePreset,
	},
	interfacePresetWestwood = {
		name = "Westwood",
		desc = "Interface reminiscent of the conquest of dunes.",
		type = 'button',
		OnChange = SetupWestwoodPreset,
	},
}

----------------------------------------------------
-- First Run Handling
----------------------------------------------------
local firstUpdate = true

function widget:Update()
	if firstUpdate then
		if options.setToDefault.value then
			-- This is where the defaults are set.
			SetupDefaultPreset()
			options.setToDefault.value = false
		end
		firstUpdate = false
	end
end