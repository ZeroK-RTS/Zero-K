
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
----------------------------------------------------
-- Widget option functions

local CHAT_PADDING = 100
local USE_SIZE_FACTOR = false

local coreName, corePath = "Chili Core Selector", "Settings/HUD Panels/Quick Selection Bar"
local integralName, integralPath = "Chili Integral Menu", "Settings/HUD Panels/Command Panel"
local minimapName, minimapPath = "Chili Minimap", "Settings/HUD Panels/Minimap"
local consoleName, consolePath = "Chili Pro Console", "Settings/HUD Panels/Chat"
local selName, selPath = "Chili Selections & CursorTip v2", "Settings/HUD Panels/Selected Units Panel"
local globalName, globalPath = "Chili Global Commands", "Settings/HUD Panels/Global Commands"
local econName, econPath = "Chili Economy Panel Default", "Settings/HUD Panels/Economy Panel"
local specName, specPath = "Chili Spectator Panels", "Settings/HUD Panels/Spectator Panels"
local dockName, dockPath = "Chili Docking", "Settings/HUD Panels/Extras/Docking"

local function Selections_SetOptions(group, showInfo, square, iconSize, showCommand, showDgun, alwaysShow)
	local selName, selPath = "Chili Selections & CursorTip v2", "Settings/HUD Panels/Selected Units Panel"
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
-- Enabled Skinning

local fancySkinOverride = {}

local SKIN_DEFAULT = {}
local SKIN_FLUSH = {
	epic = "panel_0001_small",
	global = "panel_0001_small",
}

local function SetFancySkin()
	WG.SetWidgetOption(coreName, corePath, "fancySkinning", "panel_1100_small")
	WG.SetWidgetOption(integralName, integralPath, "fancySkinning", true)
	WG.SetWidgetOption(integralName, integralPath, "flushLeft", false)
	WG.SetWidgetOption(minimapName, minimapPath, "fancySkinning", "panel_1100_large")
	WG.SetWidgetOption(selName, selPath, "fancySkinning", "panel_0120")
	WG.SetWidgetOption(globalName, globalPath, "fancySkinning", fancySkinOverride.global or "panel_1001_small")
	WG.SetWidgetOption(econName, econPath, "fancySkinning", fancySkinOverride.econ or "panel_2021")
	WG.SetWidgetOption(specName, specPath, "fancySkinning", "panel_0001")
	
	WG.crude.SetMenuSkinClass(fancySkinOverride.epic or "panel_0021")
end

local function SetFancySkinBottomLeft()
	WG.SetWidgetOption(coreName, corePath, "fancySkinning", "panel_0110_small")
	WG.SetWidgetOption(integralName, integralPath, "fancySkinning", true)
	WG.SetWidgetOption(integralName, integralPath, "flushLeft", true)
	WG.SetWidgetOption(minimapName, minimapPath, "fancySkinning", "panel_1100_large")
	WG.SetWidgetOption(selName, selPath, "fancySkinning", "panel_2100")
	WG.SetWidgetOption(globalName, globalPath, "fancySkinning", fancySkinOverride.global or "panel_1001_small")
	WG.SetWidgetOption(econName, econPath, "fancySkinning", fancySkinOverride.econ or "panel_2011")
	WG.SetWidgetOption(specName, specPath, "fancySkinning", "panel_1011")
	
	WG.crude.SetMenuSkinClass(fancySkinOverride.epic or "panel_0011_small")
end

local function SetFancySkinBottomRight()
	WG.SetWidgetOption(coreName, corePath, "fancySkinning", "panel_1100_small")
	WG.SetWidgetOption(integralName, integralPath, "fancySkinning", true)
	WG.SetWidgetOption(integralName, integralPath, "flushLeft", false)
	WG.SetWidgetOption(minimapName, minimapPath, "fancySkinning", "panel_0110_large")
	WG.SetWidgetOption(selName, selPath, "fancySkinning", "panel_0120")
	WG.SetWidgetOption(globalName, globalPath, "fancySkinning", fancySkinOverride.global or "panel_1001_small")
	WG.SetWidgetOption(econName, econPath, "fancySkinning", fancySkinOverride.econ or "panel_2011")
	WG.SetWidgetOption(specName, specPath, "fancySkinning", "panel_1011")
	
	WG.crude.SetMenuSkinClass(fancySkinOverride.epic or "panel_0011_small")
end

local function SetNewOptions()
	WG.SetWidgetOption(coreName, corePath, "background_opacity", 1)
	WG.SetWidgetOption(coreName, corePath, "buttonSpacing", 0.75)
	WG.SetWidgetOption(coreName, corePath, "horPaddingLeft", 5)
	WG.SetWidgetOption(coreName, corePath, "horPaddingRight", 6)
	WG.SetWidgetOption(coreName, corePath, "buttonSizeLong", 50)
	WG.SetWidgetOption(coreName, corePath, "minButtonSpaces", 3)
	WG.SetWidgetOption(coreName, corePath, "minSize", 196)
	WG.SetWidgetOption(coreName, corePath, "showCoreSelector", "specSpace")
	WG.SetWidgetOption(coreName, corePath, "vertPadding", 6.25)
	WG.SetWidgetOption(coreName, corePath, "vertical", true)
	
	WG.SetWidgetOption(integralName, integralPath, "background_opacity", 1)
	WG.SetWidgetOption(integralName, integralPath, "hide_when_spectating", false)
	WG.SetWidgetOption(integralName, integralPath, "leftPadding", 8)
	WG.SetWidgetOption(integralName, integralPath, "rightPadding", 10)
	
	WG.SetWidgetOption(minimapName, minimapPath, "alwaysResizable", false)
	WG.SetWidgetOption(minimapName, minimapPath, "hidebuttons", true)
	WG.SetWidgetOption(minimapName, minimapPath, "minimizable", false)
	WG.SetWidgetOption(minimapName, minimapPath, "opacity", 1)
	WG.SetWidgetOption(minimapName, minimapPath, "use_map_ratio", "armap")
	
	WG.SetWidgetOption(consoleName, consolePath, "backlogHideNotChat", true)
	WG.SetWidgetOption(consoleName, consolePath, "backlogShowWithChatEntry", true)
	
	WG.SetWidgetOption(selName, selPath, "selection_opacity", 1)
	WG.SetWidgetOption(selName, selPath, "leftPadding", 7)
	
	WG.SetWidgetOption(econName, econPath, "opacity", 0.95)
	
	WG.SetWidgetOption(specName, specPath, "playerOpacity", 0.95)
	
	WG.SetWidgetOption(dockName, dockPath, "dockEnabledPanels", false)
end

----------------------------------------------------
----------------------------------------------------
-- Disable skinning

local function SetBoringSkin()
	WG.SetWidgetOption(coreName, corePath, "fancySkinning", "panel")
	WG.SetWidgetOption(integralName, integralPath, "fancySkinning", false)
	WG.SetWidgetOption(minimapName, minimapPath, "fancySkinning", "panel")
	WG.SetWidgetOption(selName, selPath, "fancySkinning", "panel")
	WG.SetWidgetOption(globalName, globalPath, "fancySkinning", "panel")
	WG.SetWidgetOption(econName, econPath, "fancySkinning", "panel")
	WG.SetWidgetOption(specName, specPath, "fancySkinning", "panel")
	
	WG.crude.SetMenuSkinClass("panel")
end

local function ResetOptionsFromNew()
	SetBoringSkin()
	needToCallFunction = SetBoringSkin

	WG.SetWidgetOption(coreName, corePath, "background_opacity", 0)
	WG.SetWidgetOption(coreName, corePath, "buttonSpacing", 0)
	WG.SetWidgetOption(coreName, corePath, "horPaddingLeft", 0)
	WG.SetWidgetOption(coreName, corePath, "horPaddingRight", 0)
	WG.SetWidgetOption(coreName, corePath, "buttonSizeLong", 58)
	WG.SetWidgetOption(coreName, corePath, "minButtonSpaces", 0)
	WG.SetWidgetOption(coreName, corePath, "minSize", 0)
	WG.SetWidgetOption(coreName, corePath, "showCoreSelector", "specHide")
	WG.SetWidgetOption(coreName, corePath, "vertPadding", 0)
	WG.SetWidgetOption(coreName, corePath, "vertical", false)
	
	WG.SetWidgetOption(integralName, integralPath, "hide_when_spectating", false)
	WG.SetWidgetOption(integralName, integralPath, "leftPadding", 0)
	WG.SetWidgetOption(integralName, integralPath, "rightPadding", 0)
	WG.SetWidgetOption(integralName, integralPath, "tabFontSize", 14)
	
	WG.SetWidgetOption(minimapName, minimapPath, "alwaysResizable", false)
	WG.SetWidgetOption(minimapName, minimapPath, "hidebuttons", false)
	WG.SetWidgetOption(minimapName, minimapPath, "minimizable", false)
	WG.SetWidgetOption(minimapName, minimapPath, "opacity", 0)
	WG.SetWidgetOption(minimapName, minimapPath, "use_map_ratio", "arwindow")
	
	WG.SetWidgetOption(consoleName, consolePath, "backlogHideNotChat", false)
	WG.SetWidgetOption(consoleName, consolePath, "backlogShowWithChatEntry", false)
	
	WG.SetWidgetOption(selName, selPath, "leftPadding", 0)
	
	WG.SetWidgetOption(econName, econPath, "opacity", 0.8)
	
	WG.SetWidgetOption(specName, specPath, "playerOpacity", 0.6)
	
	WG.SetWidgetOption(dockName, dockPath, "dockEnabledPanels", true)
end

----------------------------------------------------
----------------------------------------------------
-- Useful Functions
----------------------------------------------------
local function GetSelectionIconSize(height)
	local rows = math.floor((height - 25)/50)
	local size = math.floor((height - 25)/rows)
	local iconHeight = math.min(53, size) + 4
	return iconHeight
end

----------------------------------------------------
----------------------------------------------------

local function SetupMissionGUI(preset)
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	-- mission objectives
	local objOnLeft = (preset == "new") or (preset == "newMinimapLeft") or (preset == "newMinimapRight") or (preset == "westwood") or (preset == "crafty") or (preset == "ensemble")
	local objX = objOnLeft and 0 or screenWidth - 64
	local objY = 50 + screenHeight * 0.2	-- menu bar height + console height
	if (preset == "crafty") then
		objY = 50	-- resource bar height
	elseif (preset == "new") then
		objY = 50	-- thick button bar height
	elseif (preset == "newMinimapLeft") or (preset == "newMinimapRight") then
		objY = 32 -- thin menu/button bar height
	elseif (preset == "ensemble") then
		objY = screenHeight * 0.2	-- console height
	end
	
	WG.SetWindowPosAndSize("objectivesButtonWindow",
		objX,
		objY,
		64,
		64
	)
	
	local persistentOnLeft = (preset == "newMinimapRight") or (preset == "westwood") -- or (preset == "crafty")
	local persistentY = objY + 64
	if (preset == "new") then
		persistentY = 50 + screenHeight * 0.2	-- menu bar height + console height
	elseif (preset == "newMinimapLeft") then
		persistentY = 32 + screenHeight * 0.2	-- thin menu bar height + console height
	elseif (preset == "ensemble") then
		persistentY = 50	-- menu bar height
	elseif (preset == "crafty") then
		persistentY = 100	-- approximate resbar height
	end
	
	-- mission persistent messagebox
	WG.SetWindowPosAndSize("msgPersistentWindow",
		persistentOnLeft and 0 or screenWidth - 64,	-- let it be auto-pushed to the left
		persistentY,
		360,
		160
	)
	
	-- tutorial next button
	local nextButtonY = persistentY + 200 + 60
	if (preset == "new") or (preset == "crafty") then
		nextButtonY = 50	-- button/menu bar height
	elseif (preset == "newMinimapRight") then
		nextButtonY = 32	-- thin menu/button bar height
	elseif (preset == "ensemble") then
		nextButtonY = screenHeight * 0.2	-- console height
	end
	local nextButtonHeight = 48
	local nextButtonX = persistentOnLeft and 0 or screenWidth - 80
	if (preset == "new") or (preset == "newMinimapRight") or (preset == "crafty") or (preset == "ensemble") then
		nextButtonX = 64	-- next to objectives button
		nextButtonHeight = 64
	end
	
	WG.SetWindowPosAndSize("uitutorial_nextButtonWindow",
		nextButtonX,
		nextButtonY,
		80,
		nextButtonHeight
	)
end

----------------------------------------------------
-- Default Preset
----------------------------------------------------
local function SetupDefaultPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	widgetHandler:DisableWidget("Chili Global Commands")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	
	Spring.SendCommands("resbar 0")
	
	ResetOptionsFromNew()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Minimap
	local minimapWidth = math.ceil(screenWidth*2/11)
	local minimapHeight = math.ceil(screenWidth*2/11 + 20)
	WG.Minimap_SetOptions("arwindow", 0, false, false, false)
	WG.SetWindowPosAndSize("Minimap Window",
		0,
		0,
		minimapWidth,
		minimapHeight
	)

	-- Integral Menu
	local integralWidth = math.max(350, math.min(480, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
	WG.SetWindowPosAndSize("integralwindow",
		0,
		screenHeight - integralHeight,
		integralWidth,
		integralHeight
	)
	
	-- Selection Bar
	local selectorButtonWidth = math.min(60, screenHeight/16)
	local coreSelectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(integralWidth/selectorButtonWidth)))
	local coreSelectorWidth = selectorButtonWidth*selectionButtonCount
	
	WG.SetWindowPosAndSize("selector_window",
		0,
		screenHeight - coreSelectorHeight - integralHeight,
		coreSelectorWidth,
		coreSelectorHeight
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
	local menuWidth = 380
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = math.min(screenWidth - 700, 660)
	local resourceBarHeight = 100
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth)
	local resourceBarRight = resourceBarWidth + resourceBarX
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	-- Console
	local consoleWidth = math.min(screenWidth * 0.30, screenWidth - minimapWidth, resourceBarRight - 2)
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		screenWidth - consoleHeight,
		menuHeight,
		consoleWidth,
		consoleHeight
	)
	
	SetupMissionGUI("default")
end

----------------------------------------------------
-- New Preset
----------------------------------------------------
local function SetupNewPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	widgetHandler:EnableWidget("Chili Global Commands")
	
	Spring.SendCommands("resbar 0")
	
	fancySkinOverride = {}
	SetFancySkin()
	needToCallFunction = SetFancySkin
	
	SetNewOptions()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	------------------------------------------------------------------------
	------------------------------------------------------------------------
	-- Bottom of the UI
	
	-- Minimap
	local minimapSize = math.floor(screenWidth*options.minimapScreenSpace.value)
	if minimapSize < 1650*options.minimapScreenSpace.value then
		if screenWidth > 1340 then
			minimapSize = 1650*options.minimapScreenSpace.value
		else
			minimapSize = screenWidth*options.minimapScreenSpace.value
		end
	end
	WG.SetWindowPosAndSize("Minimap Window",
		0,
		screenHeight - minimapSize,
		minimapSize,
		minimapSize
	)
	
	local _,_, coreSelectorWidth, coreSelectorHeight = WG.GetWindowPosAndSize("selector_window")
	coreSelectorHeight = coreSelectorHeight or 150
	coreSelectorWidth = math.ceil(coreSelectorWidth or 60)
	WG.SetWindowPosAndSize("selector_window",
		minimapSize,
		screenHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
	)
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(480, screenWidth*0.4))
	local integralHeight = 7*math.floor((math.min(screenHeight/4.5, 200*integralWidth/450))/7)
	if integralWidth/integralHeight > 2.5 then
		integralWidth = integralHeight*2.5
	end
	if minimapSize + coreSelectorWidth + integralWidth < screenWidth/2 then
		local extraPadding = screenWidth/2 - (minimapSize + coreSelectorWidth + integralWidth)
		integralWidth = screenWidth/2 - (minimapSize + coreSelectorWidth)
	end
	
	if integralWidth < 480 then
		local integralName, integralPath = "Chili Integral Menu", "Settings/HUD Panels/Command Panel"
		WG.SetWidgetOption(integralName, integralPath, "tabFontSize", math.floor(13*integralWidth/480))
	else
		local integralName, integralPath = "Chili Integral Menu", "Settings/HUD Panels/Command Panel"
		WG.SetWidgetOption(integralName, integralPath, "tabFontSize", 14)
	end
	
	integralWidth = math.floor(integralWidth)
	
	WG.SetWindowPosAndSize("integralwindow",
		minimapSize + coreSelectorWidth,
		screenHeight - integralHeight,
		integralWidth,
		integralHeight
	)
	
	local thinMode = screenWidth < 1645
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = 450
	if thinMode then
		selectionsWidth = screenWidth - (minimapSize + coreSelectorWidth + integralWidth)
	end
	if screenWidth > 1750 then
		selectionsWidth = 475
	end
	
	Selections_SetOptions(false, true, false, GetSelectionIconSize(selectionsHeight), false, true, false)
	WG.SetWindowPosAndSize("selections",
		math.max(screenWidth/2, minimapSize + coreSelectorWidth + integralWidth),
		screenHeight - selectionsHeight,
		selectionsWidth,
		selectionsHeight
	)
	
	WG.SetWidgetOption(coreName, corePath, "specSpaceOverride", selectionsHeight, integralHeight)
	
	-- Player List
	local playerlistWidth = 296
	local playerlistHeight = 150
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - playerlistHeight - ((thinMode and selectionsHeight) or 0),
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	WG.SetWindowPosAndSize("ProChat",
		0,
		screenHeight - minimapSize - selectionsHeight,
		minimapSize,
		selectionsHeight
	)
	
	-- Commander Upgrade
	local commUpgradeWidth = 200
	local commUpgradeHeight = 325
	local commUpgradeY = screenHeight - integralHeight - commUpgradeHeight - 25
	WG.SetWindowPosAndSize("CommanderUpgradeWindow",
		minimapSize + coreSelectorWidth,
		commUpgradeY,
		commUpgradeWidth,
		commUpgradeHeight
	)
	
	WG.SetWindowPosAndSize("ModuleSelectionWindow",
		minimapSize + coreSelectorWidth + commUpgradeWidth,
		commUpgradeY,
		500,
		500
	)
	
	------------------------------------------------------------------------
	------------------------------------------------------------------------
	-- Top of the UI
	
	local menuWidth = 380
	local menuHeight = 50
	
	-- Resource Bar
	local resourceBarWidth = math.min(screenWidth - 700, 660)
	local resourceBarHeight = 100
	local resourceBarX = math.floor(math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth))
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	WG.SetWindowPosAndSize("SpectatorPlayerPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		menuHeight
	)
	
	-- Menu
	if screenWidth - (resourceBarX + resourceBarWidth) > menuWidth then
		menuWidth = screenWidth - (resourceBarX + resourceBarWidth)
	end
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Global build buttons
	WG.SetWindowPosAndSize("globalCommandsWindow",
		0,
		0,
		resourceBarX,
		menuHeight
	)
	
	-- Console
	local consoleWidth = 380
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		screenWidth - consoleHeight,
		menuHeight,
		consoleWidth,
		consoleHeight
	)
	
	SetupMissionGUI("new")
end

----------------------------------------------------
-- New with Minimap Left
----------------------------------------------------

local function SetupNewWidgets()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	widgetHandler:EnableWidget("Chili Global Commands")

	if not WG.Chili.Screen0:GetChildByName("Player List") then
		widgetHandler:EnableWidget("Chili Crude Player List")
	end
	
	Spring.SendCommands("resbar 0")
end

local function GetBottomSizes(screenWidth, screenHeight, parity)
	
	local SIZE_FACTOR = 1
	if screenWidth > 3000 and USE_SIZE_FACTOR then
		SIZE_FACTOR = 2
	end
	
	-- Integral Menu
	local integralWidth = math.max(350 * SIZE_FACTOR, math.min(500 * SIZE_FACTOR, screenWidth*0.4))
	local integralHeight = 7*math.floor((math.min(screenHeight/4.5, 200*integralWidth/450))/7)
	
	if integralWidth/integralHeight > 2.5 then
		integralWidth = integralHeight*2.5
	end
	
	if integralWidth < 480 then
		local integralName, integralPath = "Chili Integral Menu", "Settings/HUD Panels/Command Panel"
		WG.SetWidgetOption(integralName, integralPath, "tabFontSize", math.floor(13*integralWidth/480) * SIZE_FACTOR)
	else
		local integralName, integralPath = "Chili Integral Menu", "Settings/HUD Panels/Command Panel"
		WG.SetWidgetOption(integralName, integralPath, "tabFontSize", 14 * SIZE_FACTOR)
	end
	integralWidth = math.floor(integralWidth)
	
	-- Core Selector
	local coreSelectorHeight = math.floor(screenHeight/2)
	local coreSelectorWidth = math.ceil(integralHeight/3) + 3
	
	local hPad = math.ceil(screenWidth/300) + 2
	WG.SetWidgetOption(coreName, corePath, "horPaddingLeft", hPad - 5*parity)
	WG.SetWidgetOption(coreName, corePath, "horPaddingRight", hPad + 5*parity)
	WG.SetWidgetOption(coreName, corePath, "vertPadding", math.floor(hPad))
	WG.SetWidgetOption(coreName, corePath, "buttonSpacing", math.floor(hPad/2))
	WG.SetWidgetOption(coreName, corePath, "buttonSizeLong", coreSelectorWidth - 2*hPad - 1)
	
	local coreMinHeight = 3*(coreSelectorWidth - 2*hPad - 1) + 2*math.floor(hPad/2) + 2*math.floor(1.5*hPad)
	
	-- Minimap
	local mapRatio = Game.mapX/Game.mapY
	
	local minimapWidth, minimapHeight
	if mapRatio > 1 then
		minimapWidth = math.floor(screenWidth*options.minimapScreenSpace.value)
		minimapHeight = (minimapWidth/mapRatio)
	else
		minimapHeight = math.floor(screenWidth*options.minimapScreenSpace.value)
		minimapWidth = math.floor(minimapHeight*mapRatio)
	end
	
	minimapWidth = minimapWidth + 4 -- padding differences
	if minimapWidth < 160 then
		minimapWidth = 160
	end
	
	if minimapHeight < coreMinHeight then
		minimapHeight = coreMinHeight
	end
	
	-- Selections
	local selectionsHeight = integralHeight*0.85
	local selectionsWidth = screenWidth - integralWidth - minimapWidth - coreSelectorWidth

	WG.SetWidgetOption(selName, selPath, "uniticon_size", GetSelectionIconSize(selectionsHeight))
	
	WG.SetWidgetOption(coreName, corePath, "specSpaceOverride", math.floor(integralHeight*6/7))
	
	-- Chat
	local maxWidth = screenWidth - 2*math.max(minimapWidth, coreSelectorWidth + integralWidth) - CHAT_PADDING
	
	local chatWidth = math.max(maxWidth, math.floor(screenWidth/5))
	local chatHeight = selectionsHeight
	
	--local chatWidth = math.max(300, minimapWidth)
	--local chatHeight = 0.2*screenHeight
	
		-- Player List
	local playerlistWidth = 310
	local playerlistHeight = screenHeight/2
	local playerListControl = WG.Chili.Screen0:GetChildByName("Player List")
	if playerListControl then
		playerlistWidth = playerListControl.minWidth
	end
	
	return integralWidth, integralHeight,
		coreSelectorWidth, coreSelectorHeight,
		minimapWidth, minimapHeight,
		selectionsWidth, selectionsHeight,
		chatWidth, chatHeight,
		playerlistWidth, playerlistHeight
end

local function SetupNewUITop()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	screenHeight = math.floor(screenHeight)
	local SIZE_FACTOR = 1
	if screenWidth > 3000 and USE_SIZE_FACTOR then
		SIZE_FACTOR = 2
	end
	
	local sideHeight = 38 * SIZE_FACTOR
	local flushTop = (screenWidth <= 1650)
	
	-- Resource Bar
	local resourceBarWidth = math.max(580 * SIZE_FACTOR, math.min(screenWidth - 700, 660 * SIZE_FACTOR))
	local resourceBarHeight = 110 * SIZE_FACTOR
	
	-- Chicken
	local chickenWidth = 189 * SIZE_FACTOR
	local chickenHeight = 270 * SIZE_FACTOR
	
	-- Menu
	local menuWidth, globalWidth
	if flushTop then
		menuWidth = math.max(350, math.ceil((screenWidth - resourceBarWidth)/2))
		globalWidth = screenWidth - resourceBarWidth - menuWidth
	else
		menuWidth = math.floor((screenWidth - resourceBarWidth)/2)
		if menuWidth > 445 then
			menuWidth = 445
		elseif menuWidth > 377 then
			menuWidth = 377
		else
			menuWidth = 347
		end
		menuWidth = menuWidth * SIZE_FACTOR
		globalWidth = menuWidth
	end
	
	local resourceBarX = math.floor(math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth))
	
	-- Set Window Positions
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
		resourceBarX,
		0,
		resourceBarWidth,
		resourceBarHeight
	)
	
	WG.SetWindowPosAndSize("SpectatorPlayerPanel",
		resourceBarX,
		0,
		resourceBarWidth,
		55
	)
	
	-- Right Side
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth - 3,
		0,
		menuWidth + 3,
		sideHeight
	)
	
	WG.SetWindowPosAndSize("chickenpanel",
		screenWidth - chickenWidth - 1,
		resourceBarHeight,
		chickenWidth,
		chickenHeight
	)
	
	-- Left Side
	WG.SetWindowPosAndSize("votes",
		0,
		resourceBarHeight,
		300 * SIZE_FACTOR,
		120 * SIZE_FACTOR
	)
	
	WG.SetWindowPosAndSize("globalCommandsWindow",
		0,
		0,
		globalWidth + 3,
		sideHeight
	)
	
	-- Console
	local consoleWidth = 380 * SIZE_FACTOR
	local consoleHeight = screenHeight * 0.20
	WG.SetWindowPosAndSize("ProConsole",
		screenWidth - consoleWidth,
		sideHeight,
		consoleWidth,
		consoleHeight
	)
end

local function SetupMinimapLeftPreset()
	SetupNewWidgets()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	screenHeight = math.ceil(screenHeight)
	
	if screenWidth <= 1650 then
		fancySkinOverride = SKIN_FLUSH
	else
		fancySkinOverride = SKIN_DEFAULT
	end
	
	SetFancySkinBottomLeft()
	needToCallFunction = SetFancySkinBottomLeft
	
	SetNewOptions()
	
	------------------------------------------------------------------------
	------------------------------------------------------------------------
	-- Bottom of the UI
	
	local integralWidth, integralHeight,
		coreSelectorWidth, coreSelectorHeight,
		minimapWidth, minimapHeight,
		selectionsWidth, selectionsHeight,
		chatWidth, chatHeight,
		playerlistWidth, playerlistHeight = GetBottomSizes(screenWidth, screenHeight, -1)
	
	--local chatX = 0
	--local chatY = screenHeight - chatHeight - minimapHeight
	
	local chatX = math.floor((screenWidth - chatWidth)/2)
	local chatY = screenHeight - chatHeight - selectionsHeight
	if chatX + chatWidth > screenWidth - coreSelectorWidth - integralWidth then
		chatY = screenHeight - chatHeight - integralHeight
	end
	
	-- Player List
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - playerlistHeight - minimapHeight - 5,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		chatY,
		chatWidth,
		chatHeight
	)
	
	-- Set Windows
	WG.SetWindowPosAndSize("Minimap Window",
		0,
		screenHeight - minimapHeight,
		minimapWidth,
		minimapHeight
	)
	WG.SetWindowPosAndSize("selections",
		minimapWidth - 3,
		screenHeight - selectionsHeight,
		selectionsWidth + 3,
		selectionsHeight
	)
	WG.SetWindowPosAndSize("integralwindow",
		minimapWidth + selectionsWidth,
		screenHeight - integralHeight,
		integralWidth + 3,
		integralHeight
	)
	WG.SetWindowPosAndSize("selector_window",
		minimapWidth + selectionsWidth + integralWidth,
		screenHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
	)
	WG.SetWidgetOption(coreName, corePath, "leftsideofscreen", false)
	
	-- Commander Upgrade
	local commUpgradeWidth = 200
	local commUpgradeHeight = 325
	local commUpgradeY = screenHeight - integralHeight - commUpgradeHeight - 25
	WG.SetWindowPosAndSize("CommanderUpgradeWindow",
		minimapWidth + selectionsWidth,
		commUpgradeY,
		commUpgradeWidth,
		commUpgradeHeight
	)
	
	WG.SetWindowPosAndSize("ModuleSelectionWindow",
		minimapWidth + selectionsWidth + commUpgradeWidth,
		commUpgradeY,
		500,
		500
	)
	
	SetupNewUITop()
	SetupMissionGUI("newMinimapLeft")
end

----------------------------------------------------
-- New with Minimap Right
----------------------------------------------------
local function SetupMinimapRightPreset()
	SetupNewWidgets()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	screenHeight = math.ceil(screenHeight)
	
	if screenWidth <= 1650 then
		fancySkinOverride = SKIN_FLUSH
	else
		fancySkinOverride = SKIN_DEFAULT
	end
	SetFancySkinBottomRight()
	needToCallFunction = SetFancySkinBottomRight
	
	SetNewOptions()
	
	------------------------------------------------------------------------
	------------------------------------------------------------------------
	-- Bottom of the UI
	
	local integralWidth, integralHeight,
		coreSelectorWidth, coreSelectorHeight,
		minimapWidth, minimapHeight,
		selectionsWidth, selectionsHeight,
		chatWidth, chatHeight,
		playerlistWidth, playerlistHeight = GetBottomSizes(screenWidth, screenHeight, 1)
	
	--local chatX = screenWidth - chatWidth
	--local chatY = screenHeight - chatHeight - minimapHeight
	
	local chatX = math.floor((screenWidth - chatWidth)/2)
	local chatY = screenHeight - chatHeight - selectionsHeight
	if chatX < coreSelectorWidth + integralWidth then
		chatY = screenHeight - chatHeight - integralHeight
	end
	
	-- Player List
	WG.SetWindowPosAndSize("Player List",
		screenWidth - playerlistWidth,
		screenHeight - playerlistHeight - minimapHeight - 5,
		playerlistWidth,
		playerlistHeight
	)
	
	-- Chat
	WG.SetWindowPosAndSize("ProChat",
		chatX,
		chatY,
		chatWidth,
		chatHeight
	)
	
	-- Set Windows
	WG.SetWindowPosAndSize("Minimap Window",
		coreSelectorWidth + integralWidth + selectionsWidth,
		screenHeight - minimapHeight,
		minimapWidth,
		minimapHeight
	)
	WG.SetWindowPosAndSize("selections",
		coreSelectorWidth + integralWidth,
		screenHeight - selectionsHeight,
		selectionsWidth + 3,
		selectionsHeight
	)
	WG.SetWindowPosAndSize("integralwindow",
		coreSelectorWidth - 3,
		screenHeight - integralHeight,
		integralWidth + 3,
		integralHeight
	)
	WG.SetWindowPosAndSize("selector_window",
		0,
		screenHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
	)
	WG.SetWidgetOption(coreName, corePath, "leftsideofscreen", true)
	
	-- Commander Upgrade
	local commUpgradeWidth = 200
	local commUpgradeHeight = 325
	local commUpgradeY = screenHeight - integralHeight - commUpgradeHeight - 25
	WG.SetWindowPosAndSize("CommanderUpgradeWindow",
		coreSelectorWidth,
		commUpgradeY,
		commUpgradeWidth,
		commUpgradeHeight
	)
	
	WG.SetWindowPosAndSize("ModuleSelectionWindow",
		coreSelectorWidth + commUpgradeWidth,
		commUpgradeY,
		500,
		500
	)
	
	SetupNewUITop()
	SetupMissionGUI("newMinimapRight")
end

----------------------------------------------------
-- Crafty Preset
----------------------------------------------------
local function SetupCraftyPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	widgetHandler:DisableWidget("Chili Global Commands")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	
	Spring.SendCommands("resbar 0")
	
	ResetOptionsFromNew()
	
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
	local coreSelectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(minimapWidth/selectorButtonWidth)))
	local coreSelectorWidth = selectorButtonWidth*selectionButtonCount
	WG.SetWindowPosAndSize("selector_window",
		0,
		screenHeight - minimapHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
	)
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(500, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
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
	local menuWidth = 380
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		0,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = 660
	local resourceBarHeight = 50
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth + 4)
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
		resourceBarX,
		0 - 4,
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
	
	SetupMissionGUI("crafty")
end


----------------------------------------------------
-- Ensemble Preset
----------------------------------------------------
local function SetupEnsemblePreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	widgetHandler:DisableWidget("Chili Global Commands")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	
	Spring.SendCommands("resbar 0")
	
	ResetOptionsFromNew()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Integral Menu
	local integralWidth = math.max(350, math.min(500, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
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
	local coreSelectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(integralWidth/selectorButtonWidth)))
	local coreSelectorWidth = selectorButtonWidth*selectionButtonCount
	WG.SetWindowPosAndSize("selector_window",
		integralWidth,
		screenHeight - selectionsHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
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
	local menuWidth = 380
	local menuHeight = 50
	WG.SetWindowPosAndSize("epicmenubar",
		screenWidth - menuWidth,
		0,
		menuWidth,
		menuHeight
	)
	
	-- Resource Bar
	local resourceBarWidth = 660
	local resourceBarHeight = 50
	local resourceBarX = math.min(screenWidth/2 - resourceBarWidth/2, screenWidth - resourceBarWidth - menuWidth)
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
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
	
	SetupMissionGUI("ensemble")
end

----------------------------------------------------
-- Westwood Preset
----------------------------------------------------
local function SetupWestwoodPreset()
	-- Disable
	widgetHandler:DisableWidget("Chili Chat 2.2")
	widgetHandler:DisableWidget("Chili Deluxe Player List - Alpha 2.02")
	widgetHandler:DisableWidget("Chili Chat Bubbles")
	widgetHandler:DisableWidget("Chili Keyboard Menu")
	widgetHandler:DisableWidget("Chili Radial Build Menu")
	widgetHandler:DisableWidget("Chili Resource Bars Classic")
	widgetHandler:DisableWidget("Chili Global Commands")
	
	-- Enable
	widgetHandler:EnableWidget("Chili Minimap")
	widgetHandler:EnableWidget("Chili Crude Player List")
	widgetHandler:EnableWidget("Chili Integral Menu")
	widgetHandler:EnableWidget("Chili Pro Console")
	widgetHandler:EnableWidget("Chili Economy Panel Default")
	widgetHandler:EnableWidget("Chili Core Selector")
	widgetHandler:EnableWidget("Chili Selections & CursorTip v2")
	
	Spring.SendCommands("resbar 0")
	
	ResetOptionsFromNew()
	
	-- Settings for window positions and settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	
	-- Resource Bar
	local resourceBarWidth = screenWidth*5/22 + 20
	local resourceBarHeight = 65
	local resourceBarX = screenWidth - resourceBarWidth
	WG.SetWindowPosAndSize("EconomyPanelDefaultTwo",
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
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
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
	local coreSelectorHeight = 55*selectorButtonWidth/60
	local selectionButtonCount = math.min(12,math.max(4,math.floor(resourceBarWidth/selectorButtonWidth)))
	local coreSelectorWidth = selectorButtonWidth*selectionButtonCount
	WG.SetWindowPosAndSize("selector_window",
		screenWidth - selectionsWidth,
		screenHeight - selectionsHeight - coreSelectorHeight,
		coreSelectorWidth,
		coreSelectorHeight
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
	local menuWidth = 380
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
	
	SetupMissionGUI("westwood")
end

----------------------------------------------------
-- Preset selection
----------------------------------------------------

local firstUpdate = true

local presetFunction = {
	default2 = SetupDefaultPreset,
	new = SetupNewPreset,
	minimapLeft = SetupMinimapLeftPreset,
	minimapRight = SetupMinimapRightPreset,
	crafty = SetupCraftyPreset,
	ensemble = SetupEnsemblePreset,
	westwood = SetupWestwoodPreset,
}

local function UpdateInterfacePreset(self)
	if firstUpdate then
		-- Don't reset IU while initializing
		return
	end
	local presetKey = self.value
	Spring.Echo("UpdateInterfacePreset", presetKey)
	if presetFunction[presetKey] then
		presetFunction[presetKey]()
	end
end

----------------------------------------------------
-- Options
----------------------------------------------------
options_path = 'Settings/HUD Presets'
options_order = {'updateNewDefaults', 'setToDefault', 'maintainDefaultUI', 'minimapScreenSpace', 'interfacePreset'}
options = {
	updateNewDefaults = {
		name  = "Stay up to date",
		type  = "bool",
		value = true,
		desc = "Updates your UI when new defaults are released.",
		noHotkey = true,
	},
	setToDefault = {
		name  = "Set To Default Once",
		type  = "bool",
		value = true,
		desc = "Resets the HUD to the default next time this widget is initialized.",
		advanced = true,
		noHotkey = true,
	},
	maintainDefaultUI = {
		name  = "Reset on screen resolution change",
		type  = "bool",
		value = true,
		desc = "Resets the UI when screen resolution changes. Disable if you plan to customise your UI.",
		noHotkey = true,
	},
	minimapScreenSpace = {
		name = "Minimap Size",
		type = "number",
		value = 0.19, min = 0.05, max = 0.4, step = 0.01,
		--desc = "Controls minimap size for the New UI presets.", -- supresses value tooltip
		OnChange = function(self)
			UpdateInterfacePreset(options.interfacePreset)
		end,
	},
	interfacePreset = {
		name = 'UI Preset',
		type = 'radioButton',
		value = 'default',
		items = {
			{key = 'default2', name = 'Old Default', desc = "The old default UI. Not recommended",},
			--{key = 'new', name = 'New UI', desc = "The WIP new interface. NOTE: '/luaui reload' might be required to switch the skinning.",},
			{key = 'minimapLeft', name = 'Minimap Left',},
			{key = 'minimapRight', name = 'Minimap Right (default)',},
			--{key = 'crafty', name = 'Crafty', desc = "Interface reminiscent of the craft of war and stars.",},
			--{key = 'ensemble', name = 'Ensemble', desc = "Interface reminiscent of the imperial ages.",},
			--{key = 'westwood', name = 'Westwood', desc = "Interface reminiscent of the conquest of dunes.",},
			{key = 'default', name = 'None', desc = "No preset. Select this if you want to modify your UI and have the changes rememberd on subsequent launches.",},
		},
		noHotkey = true,
		OnChange = UpdateInterfacePreset
	},
}

----------------------------------------------------
-- Interface
----------------------------------------------------

function WG.HudEnableWidget(widgetName)
	widgetHandler:EnableWidget(widgetName)
end

function WG.HudDisableWidget(widgetName)
	widgetHandler:DisableWidget(widgetName)
end

function WG.IsWidgetEnabled(widgetName)
	local widgets = widgetHandler.widgets
	for i = 1, #widgets do
		local w = widgets[i]
		if w:GetInfo().name == widgetName then
			return true
		end
	end
end

----------------------------------------------------
-- Callins
----------------------------------------------------
local timeSinceUpdate = 0
local UPDATE_FREQUENCY = 5
local oldWidth = 0
local oldHeight = 0

local callCount = 0

function widget:Update(dt)
	if needToCallFunction then
		needToCallFunction()
		callCount = callCount + 1
		if callCount > 4 then
			needToCallFunction = nil
			callCount = 0
		end
	end
	
	if options.setToDefault.value then
		options.interfacePreset.value = "minimapRight"
		options.interfacePreset.OnChange(options.interfacePreset)
		options.setToDefault.value = false
	end
	
	if options.updateNewDefaults.value then
		if not ((options.interfacePreset.value == "minimapRight") or (options.interfacePreset.value == "minimapLeft")) then
			options.interfacePreset.value = "minimapRight"
			options.interfacePreset.OnChange(options.interfacePreset)
		end
	end
	
	if firstUpdate then
		firstUpdate = false
		
		local screenWidth, screenHeight = Spring.GetWindowGeometry()
		oldWidth = screenWidth
		oldHeight = screenHeight
		UpdateInterfacePreset(options.interfacePreset)
	end
	
	if options.maintainDefaultUI.value  then
		timeSinceUpdate = timeSinceUpdate + dt
		if timeSinceUpdate > UPDATE_FREQUENCY then
			local screenWidth, screenHeight = Spring.GetWindowGeometry()
			if oldWidth ~= screenWidth or oldHeight ~= screenHeight then
				oldWidth = screenWidth
				oldHeight = screenHeight
				UpdateInterfacePreset(options.interfacePreset)
			end
			timeSinceUpdate = 0
		end
	end
end

function widget:ViewResize(screenWidth, screenHeight)
	if options.maintainDefaultUI.value then
		oldWidth = screenWidth
		oldHeight = screenHeight
		UpdateInterfacePreset(options.interfacePreset)
	end
end

function widget:GetConfigData()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	return {oldScreenWidth = screenWidth, oldScreenHeight = screenHeight}
end

function widget:SetConfigData(data)
	if data then
		oldWidth = data.oldScreenWidth or 0
		oldHeight = data.oldScreenHeight or 0
	end
end
