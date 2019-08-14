--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Display Keys 2",
		desc      = "Displays the current key combination.",
		author    = "GoogleFrog",
		date      = "12 August 2015",
		license   = "GNU GPL, v2 or later",
		layer     = -10000,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

include("keysym.h.lua")

local keyData, mouseData

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

options_path = 'Settings/HUD Panels/Extras/Display Keys'

options_order = {
	'enable', 'keyReleaseTimeout', 'mouseReleaseTimeout',
}
 
options = {
	enable = {
		name = "Show input visualizer",
		desc = "Shows pressed key combinations and mouse buttons. Useful for video tutorials.",
		type = "bool",
		value = false,
	},
	keyReleaseTimeout = {
		name  = "Key Release Timeout",
		type  = "number",
		value = 0.6, min = 0, max = 2, step = 0.025,
	},
	mouseReleaseTimeout = {
		name  = "Mouse Release Timeout",
		type  = "number",
		value = 0.3, min = 0, max = 2, step = 0.025,
	},
}

local panelColor = {1,1,1,0.8}
local highlightColor = {1,0.7, 0, 1}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Window Creation

local function InitializeDisplayLabelControl(name)
	local data = {}
	
	local screenWidth, screenHeight = Spring.GetWindowGeometry()

	local window = Chili.Window:New{
		parent = screen0,
		dockable = true,
		name = name,
		padding = {0,0,0,0},
		x = 0,
		y = 740,
		clientWidth  = 380,
		clientHeight = 64,
		classname = "main_window_small_very_flat",
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		OnMouseDown = ShowOptions,
	}
	
	local displayLabel = Chili.Label:New{
		parent = window,
		x      = 15,
		y      = 10,
		right  = 10,
		bottom = 12,
		caption = "",
		valign = "center",
 		align  = "center",
		autosize = false,
		font   = {
			size = 36,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
		},
	}
	
	local function UpdateWindow(val)
		displayLabel:SetCaption(val)
	end
	
	local function Dispose()
		window:Dispose()
	end
	
	local data = {
		UpdateWindow = UpdateWindow,
		Dispose = Dispose,
	}
	
	return data
end

local function InitializeMouseButtonControl(name)
	local window = Chili.Window:New{
		parent = screen0,
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		dockable = true,
		name = name,
		padding = {0,0,0,0},
		x = 60,
		y = 676,
		clientWidth  = 260,
		clientHeight = 64,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		OnMouseDown = ShowOptions,
	}
	
	local leftPanel = Chili.Panel:New{
		backgroundColor = panelColor,
		color = panelColor,
		parent = window,
		padding = {0,0,0,0},
		y      = 0,
		x      = 0,
		right  = "60%",
		bottom = 0,
		classname = "panel_button_rounded",
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
	}
	local middlePanel = Chili.Panel:New{
		backgroundColor = panelColor,
		color = panelColor,
		parent = window,
		padding = {0,0,0,0},
		y      = 0,
		x      = "40%",
		right  = "40%",
		bottom = 0,
		classname = "panel_button_rounded",
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
	}
	local rightPanel = Chili.Panel:New{
		backgroundColor = panelColor,
		color = panelColor,
		parent = window,
		padding = {0,0,0,0},
		y      = 0,
		x      = "60%",
		right  = 0,
		bottom = 0,
		classname = "panel_button_rounded",
		dockable = false;
		draggable = false,
		resizable = false,
		OnMouseDown = ShowOptions,
	}
	
	local leftLabel = Chili.Label:New{
		parent = leftPanel,
		x      = 15,
		y      = 10,
		right  = 10,
		bottom = 12,
		caption = "",
 		align  = "center",
		autosize = false,
		font   = {
			size = 36,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
		},
	}
	local rightLabel = Chili.Label:New{
		parent = rightPanel,
		x      = 15,
		y      = 10,
		right  = 10,
		bottom = 12,
		caption = "",
 		align  = "center",
		autosize = false,
		font   = {
			size = 36,
			outline = true,
			outlineWidth = 2,
			outlineWeight = 2,
		},
	}
	
	local function UpdateWindow(val)
		if val == 1 then
			leftPanel.backgroundColor = highlightColor
			leftPanel.color = highlightColor
			middlePanel.backgroundColor = panelColor
			middlePanel.color = panelColor
			rightPanel.backgroundColor = panelColor
			rightPanel.color = panelColor
			leftLabel:SetCaption("Left")
			rightLabel:SetCaption("")
		elseif val == 2 then
			leftPanel.backgroundColor = panelColor
			leftPanel.color = panelColor
			middlePanel.backgroundColor = highlightColor
			middlePanel.color = highlightColor
			rightPanel.backgroundColor = panelColor
			rightPanel.color = panelColor
			leftLabel:SetCaption("")
			rightLabel:SetCaption("")
		elseif val == 3 then
			leftPanel.backgroundColor = panelColor
			leftPanel.color = panelColor
			middlePanel.backgroundColor = panelColor
			middlePanel.color = panelColor
			rightPanel.backgroundColor = highlightColor
			rightPanel.color = highlightColor
			leftLabel:SetCaption("")
			rightLabel:SetCaption("Right")
		else
			leftPanel.backgroundColor = panelColor
			leftPanel.color = panelColor
			middlePanel.backgroundColor = panelColor
			middlePanel.color = panelColor
			rightPanel.backgroundColor = panelColor
			rightPanel.color = panelColor
			leftLabel:SetCaption("")
			rightLabel:SetCaption("")
		end
		leftPanel:Invalidate()
		middlePanel:Invalidate()
		rightPanel:Invalidate()
		window:Invalidate()
	end
	
	local function Dispose()
		window:Dispose()
	end
	
	local data = {
		UpdateWindow = UpdateWindow,
		Dispose = Dispose,
	}
	
	return data
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- General Functions

local function DoDelayedUpdate(data, dt)
	if not data.updateTime then
		return
	end
	
	data.updateTime = data.updateTime - dt
	if data.updateTime > 0 then
		return
	end
	
	data.UpdateWindow(data.updateData)
	data.updateTime = false
end

function widget:Update(dt)
	if mouseData.pressed then
		local x, y, lmb, mmb, rmb = Spring.GetMouseState()
		if not (lmb or mmb or rmb) then
			mouseData.pressed = false
			mouseData.updateData = false
			mouseData.updateTime = options.mouseReleaseTimeout.value
		end
	end

	DoDelayedUpdate(keyData, dt)
	DoDelayedUpdate(mouseData, dt)
end

function widget:Initialize()
	Chili = WG.Chili
	screen0 = Chili.Screen0

	options.enable.OnChange(options.enable)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Keys

local function IsMod(key)
	return key == 32 or key >= 128
end

local onlyMods = false

local function Conc(str, add, val)
	if val then
		if onlyMods then
			return (str or "") .. (str and " + " or "") .. add
		else
			return (str or "") .. add .. " + "
		end
	else
		return str
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	onlyMods = IsMod(key) and not keyData.pressed

	local keyText = Conc(false, "Space", modifier.meta)
	keyText = Conc(keyText, "Ctrl", modifier.ctrl)
	keyText = Conc(keyText, "Alt", modifier.alt)
	keyText = Conc(keyText, "Shift", modifier.shift)
	
	if not onlyMods then
		if not keyData.pressed then
			keyData.pressedString = string.upper(tostring(string.char(key)))
		end
		keyData.pressed = true
		keyText = (keyText or "") .. keyData.pressedString
	end
	
	keyData.UpdateWindow(keyText or "")
	keyData.updateData = keyText or ""
	keyData.updateTime = false
end

function widget:KeyRelease(key, modifier, isRepeat)
	if not IsMod(key) then
		keyData.pressed = false
	end
	
	onlyMods = not keyData.pressed
	
	local keyText = Conc(false, "Space", modifier.meta)
	keyText = Conc(keyText, "Ctrl", modifier.ctrl)
	keyText = Conc(keyText, "Alt", modifier.alt)
	keyText = Conc(keyText, "Shift", modifier.shift)
	
	if not onlyMods then
		keyText = (keyText or "") .. keyData.pressedString
	end
	
	keyData.updateData = keyText or ""
	keyData.updateTime = options.keyReleaseTimeout.value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mouse

function widget:MousePress(x, y, button)
	mouseData.pressed = true
	mouseData.UpdateWindow(button)
	mouseData.updateTime = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local callins = {"Update", "KeyPress", "KeyRelease", "MousePress"}

local function Enable()
	if not mouseData then
		mouseData = InitializeMouseButtonControl("Mouse Display")
	end
	if not keyData then
		keyData = InitializeDisplayLabelControl("Key Display")
	end
	for _, callin in pairs(callins) do
		widgetHandler:UpdateCallIn(callin)
	end
end

local function Disable()
	if keyData then
		keyData.Dispose()
		keyData = nil
	end
	if mouseData then
		mouseData.Dispose()
		mouseData = nil
	end
	for _, callin in pairs(callins) do
		widgetHandler:RemoveCallIn(callin)
	end
end

options.enable.OnChange = function(self)
	if self.value then
		Enable()
	else
		Disable()
	end
end

function widget:Shutdown()
	Disable()
end
