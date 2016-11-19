--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Space Waster",
		desc      = "Wastes space to make the UI look 'better'.",
		author    = "GoogleFrog",
		date      = "19 November 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window
local Chili

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CreateWindow()
	window = Chili.Window:New{
		name = "SpaceWaster_1",
		backgroundColor = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = Chili.Screen0,
		dockable = true,
		padding = {0,0,0,0},
		minWidth = 0,
		minHeight = 50,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
	}

	local background = Chili.Panel:New{
		classname = "panel_0021",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.8},
		parent = window,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	if window then
		window:Dispose()
	end
end

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	CreateWindow()
end
