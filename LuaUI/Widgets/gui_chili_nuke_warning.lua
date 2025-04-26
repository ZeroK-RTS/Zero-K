--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Nuke Warning",
    desc      = "Displays a warning to players whenever a nuke is launched.",
    author    = "GoogleFrog",
    date      = "15 August 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("colors.lua")
VFS.Include("LuaRules/Configs/constants.lua")

local Chili
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local mainWindow

local wantedShown = false
local currentlyShown = false
local flashState = 1
local flashTime = 0
local previewShow = false
local postInit = false

local FLASH_PERIOD = 0.4

local flashStateDefs

local UpdateFont

local function UpdateFlashStateDefs()
	local opacity = options and options.nukeWarningOpacity and (options.nukeWarningOpacity.value / 100.0) or 0.6

	flashStateDefs = {
		{
			color = {1,0.2,0,opacity},
			outlinecolor = {0.3,0.1,0,opacity},
		},
		{
			color = {0.9,0.6,0.1,opacity},
			outlinecolor = {0.25,0.15,0,opacity},
		}
	}

	if currentlyShown then
		UpdateFont(flashState)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Update Text

function UpdateFont(state)
	local c = flashStateDefs[state].color
	local o = flashStateDefs[state].outlinecolor
	mainWindow.label.font:SetColor(c[1],c[2],c[3], c[4])
	mainWindow.label.font:SetOutlineColor(o[1],o[2],o[3], o[4])
	
	mainWindow.window:Invalidate()
	mainWindow.label:Invalidate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Window Creation

local function CreateWindow()
	local data = {}
	
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	local resourcePanelHeight = 105
	local windowWidth = screenWidth - 10

	data.window = Chili.Window:New{
		parent = screen0,
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		name = "NukeLaunchWarningWindow",
		padding = {0,0,0,0},
		x = 5,
		y = (options.nukeWarningIsHuge.value and 0) or (options.yOffset.value + 109),
		clientWidth  = windowWidth,
		bottom = 0,
		dockable = false,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
	}
	
	data.label = Chili.Label:New{
		parent = data.window,
		x      = 0,
		y      = 0,
		right  = 0,
		bottom = 0,
		caption = WG.Translate ("interface", "nuclear_launch_detected"),
		valign = options.nukeWarningIsHuge.value and "center" or "top",
		align  = "center",
		autosize = false,
		font   = {
			size = options.fontSize.value,
			outline = true,
			outlineWidth = 6,
			outlineWeight = 6,
			color = flashStateDefs[1].color,
			outlinecolor = flashStateDefs[1].outlinecolor,
		},
	}
	
	return data
end

local function ShowWindow()
	--local _,fullView = Spring.GetSpectatingState()
	--
	---- Spectators with fullview should not be distracted by nuke warning
	--if fullView then
	--	return
	--end
	
	if mainWindow then
		screen0:AddChild(mainWindow.window)
	else
		mainWindow = CreateWindow()
		UpdateFont(1)
	end
	currentlyShown = true
	flashState = 1
	flashTime = 0
end

local function HideWindow()
	if mainWindow then
		screen0:RemoveChild(mainWindow.window)
	end
	currentlyShown = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function languageChanged ()
	if not mainWindow then return end
	mainWindow.label:SetCaption(WG.Translate ("interface", "nuclear_launch_detected"))
end

function widget:Shutdown()
	if mainWindow and mainWindow.window then
		mainWindow.window:Dispose()
	end
	WG.ShutdownTranslation(GetInfo().name)
end

function widget:Initialize()
	Chili = WG.Chili
	screen0 = Chili.Screen0
	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	WG.InitializeTranslation (languageChanged, GetInfo().name)
end

function widget:Update(dt)
	if not postInit then
		postInit = true
	end
	if previewShow then
		wantedShown = true
		ShowWindow()
		previewShow = false
	end
	if not currentlyShown then
		return
	end
	
	flashTime = flashTime + dt
	
	if flashTime > FLASH_PERIOD then
		flashTime = flashTime%FLASH_PERIOD
		flashState = 3 - flashState
		if wantedShown then
			UpdateFont(flashState)
		else
			HideWindow()
		end
	end
end

function widget:GameFrame(n)
	if wantedShown ~= (Spring.GetGameRulesParam("recentNukeLaunch") == 1) then
		if wantedShown then
			wantedShown = false
		else
			wantedShown = true
			ShowWindow()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function RecreateWindow()
	if mainWindow and mainWindow.window then
		mainWindow.window:Dispose()
		mainWindow = nil
		currentlyShown = false
	end
	UpdateFlashStateDefs()

	if wantedShown then
		ShowWindow()
	end
	if postInit then
		previewShow = 1
	end
end

options_path = "Settings/HUD Panels/Nuke Warning"
options_order = { "mainlabel", "nukeWarningOpacity", "fontSize", "yOffset", "nukeWarningIsHuge"}

options = {
	mainlabel = {
		name='Nuclear launch warning',
		type='label',
	},
	nukeWarningOpacity = {
		name = "Warning opacity",
		type = "number",
		value = 100,
		min = 1, max = 100, step = 1,
		OnChange = RecreateWindow,
	},
	yOffset = {
		name = "Warning offset",
		type = "number",
		value = 0,
		min = 0, max = 1000,
		step = 5,
		OnChange = RecreateWindow,
	},
	fontSize = {
		name = "Warning size",
		type = "number",
		value = 32,
		min = 32, max = 250,
		step = 1,
		OnChange = RecreateWindow,
	},
	nukeWarningIsHuge = {
		name = "Warn in the middle of the screen",
		type = "bool",
		value = false,
		noHotkey = true,
		OnChange = RecreateWindow,
	},
}