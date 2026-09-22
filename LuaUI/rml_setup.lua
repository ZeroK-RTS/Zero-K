--  file:    rml_setup.lua
--  brief:   RmlUi Setup
--  author:  lov + ChrisFloofyKitsune
--
--  Copyright (C) 2024.
--  Licensed under the terms of the GNU GPL, v2 or later.

if RmlGuard or not RmlUi then
	return
end
-- don't allow this initialization code to be run multiple times
RmlGuard = true

--[[
	Recoil uses a custom set of Lua bindings (check out rts/Rml/SolLua/bind folder in the C++ engine code)
	Aside from the Lua API, the rest of the RmlUi documentation is still relevant
		https://mikke89.github.io/RmlUiDoc/index.html
]]

local initialized = false
local initializeOnce

local oldGetContext = RmlUi.GetContext
local oldCreateContext = RmlUi.CreateContext

local function NewCreateContext(...)
	initializeOnce()
	local context = oldCreateContext(...)

	-- set up dp_ratio considering the user's UI scale preference and the screen resolution
	local viewSizeX, viewSizeY = Spring.GetViewGeometry()

	local userScale = Spring.GetConfigFloat("ui_scale", 1)

	local baseWidth = 1920
	local baseHeight = 1080
	local resFactor = math.min(viewSizeX / baseWidth, viewSizeY / baseHeight)

	context.dp_ratio = resFactor * userScale

	context.dp_ratio = math.floor(context.dp_ratio * 100) / 100
	return context
end

local function NewGetContext(...)
	initializeOnce()
	return oldGetContext(...)
end

RmlUi.CreateContext = NewCreateContext
RmlUi.GetContext = NewGetContext

if Script.IsEngineMinVersion and Script.IsEngineMinVersion(2026, 6, 0) then
	RmlUi.ClearResourcesForWidget = function(name)
		if RmlUi.WidgetDocumentPaths[name] then
			RmlUi.WidgetDocumentPaths[name] = {}
		end
	end

	RmlUi.GetResourcesForWidget = function(name)
		local resources = {}
		if not RmlUi.WidgetDocumentPaths[name] then
			return
		end
		for _, value in ipairs(RmlUi.WidgetDocumentPaths[name]) do
			table.insert(resources, value)
			for _, resvalue in ipairs(RmlUi.GetDocumentPathRequests(value)) do
				table.insert(resources, resvalue)
			end
		end
		return resources
	end
end

-- Only initialize RmlUI if a context is accessed by a widget
function initializeOnce()
	if initialized then
		return
	end
	initialized = true

	-- Load fonts
	RmlUi.LoadFontFace("fonts/FreeSansBold.otf", true)
	local font_files = VFS.DirList("LuaUI/fonts", "*.ttf")
	for _, file in ipairs(font_files) do
		Spring.Echo("loading font", file)
		RmlUi.LoadFontFace(file, true)
	end

	-- Mouse Cursor Aliases
	--[[
	These let standard CSS cursor names be used when doing styling.
	If a cursor set via RCSS does not have an alias, it is unchanged.
	CSS cursor list: https://developer.mozilla.org/en-US/docs/Web/CSS/cursor
	RmlUi documentation: https://mikke89.github.io/RmlUiDoc/pages/rcss/user_interface.html#cursor
	]]

	-- when "cursor: normal" is set via RCSS, "cursornormal" will be sent to the engine... and so on for the rest
	RmlUi.SetMouseCursorAlias("default", "cursornormal")
	RmlUi.SetMouseCursorAlias("pointer", "Move")
	RmlUi.SetMouseCursorAlias("move", "uimove")
	RmlUi.SetMouseCursorAlias("nesw-resize", "uiresized2")
	RmlUi.SetMouseCursorAlias("nwse-resize", "uiresized1")
	RmlUi.SetMouseCursorAlias("ns-resize", "uiresizev")
	RmlUi.SetMouseCursorAlias("ew-resize", "uiresizeh")

	NewCreateContext("shared")
end
