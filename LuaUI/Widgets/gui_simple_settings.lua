
function widget:GetInfo()
	return {
		name      = "Simple Settings",
		desc      = "Creates and manages the simple settings for simple settings mode.",
		author    = "GoogleFrog",
		date      = "1 June 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
		handler   = true,
	}
end

local thisWidgetName = "Simple Settings"
local initializationComplete = false 

local LUAMENU_SETTING = "changeSetting "

----------------------------------------------------
-- Utilities
----------------------------------------------------
local function CopyWidgetSetting()

end

----------------------------------------------------
-- Options
----------------------------------------------------
options_path = 'Settings'
options_order = {}
options = {}

local optionGenerationTable = {
	{
		optionWidget = "Selection Hierarchy",
		optionPath = "Settings/Interface/Selection",
		optionName = "useSelectionFilteringOption",
		name  = "Use selection filtering",
		desc = "Filter constructors out of mixed constructor/combat unit selection.",
		type = "bool",
		default = true,
		path = "Settings/Interface",
	},
	{
		optionWidget = "Grab Input",
		optionPath = "Settings/Interface/Mouse Cursor",
		optionName = "grabinput",
		name = "Grab Input (lock mouse to window)",
		desc = "Prevents the cursor from leaving the Window/Screen.",
		type = "bool",
		default = true,
		path = "Settings/Interface",
	},
	{
		optionWidget = "Showeco and Grid Drawer",
		optionPath = "Settings/Interface/Economy Overlay",
		optionName = "start_with_showeco",
		name = "Start with economy overlay",
		desc = "Enable the economy overlay when the game starts.",
		type = "bool",
		default = false,
		path = "Settings/Interface",
	},
	{
		optionWidget = "Showeco and Grid Drawer",
		optionPath = "Settings/Interface/Economy Overlay",
		optionName = "always_show_mexes",
		name = "Always show Mexes",
		desc = "Show metal extractors even when the full economy overlay is not enabled.",
		type = "bool",
		default = true,
		path = "Settings/Interface",
	},
	{
		optionName = "minimapRight",
		optionFunction = function (self)
			WG.SetWidgetOption("HUD Presets", "Settings/HUD Presets", "interfacePreset", (self.value and "minimapRight") or "minimapLeft")
		end,
		name = "Minimap on Right",
		desc = "Toggle whether the minimap is on the left or right.",
		type = "bool",
		default = true,
		path = "Settings/Interface",
	},
	{
		optionWidget = "HUD Presets",
		optionPath = "Settings/HUD Presets",
		optionName = "minimapScreenSpace",
		name = "Minimap Size",
		type = "number",
		min = 0.05, 
		max = 0.4,
		step = 0.01,
		default = 0.19, 
		path = "Settings/Interface",
	},
	{
		optionName = "unitLabel",
		name = "Unit Visibility",
		type = "label",
		path = "Settings/Graphics",
	},
	--{
	--	optionName = "unitPlatter",
	--	optionFunction = function(self) Spring.SendCommands{"luaui togglewidget Fancy Teamplatter"} end,
	--	name = "Toggle Unit Platter",
	--	desc = "Puts a team-coloured platter-halo below units.",
	--	type = "button",
	--	path = "Settings/Graphics",
	--},
	{
		optionName = "unitOutline",
		optionFunction = function(self) Spring.SendCommands{"luaui togglewidget Outline"} end,
		name = "Toggle Unit Outline",
		desc = "Draws a black outline around units.",
		type = "button",
		path = "Settings/Graphics",
	},
	{
		optionWidget = "Settings/Graphics/Unit Visibility", -- Special hax for epicmenu options
		optionPath = "Settings/Graphics/Unit Visibility",
		optionName = "Icon Distance",
		name = "Icon Distance",
		min = 1,
		max = 500,
		default = 151,
		type = "number",
		path = "Settings/Graphics",
	},
	{
		optionName = "moreOptions",
		name = "More Options",
		value = "More graphics settings are available in the main menu under Settings -> Graphics. These settings require a restart to take effect.",
		type = "text",
		path = "Settings/Graphics",
	},
	{
		optionName = "moreOptionsButton",
		optionFunction = function(self) Spring.SendLuaMenuMsg("openSettingsTab Graphics") end,
		name = "Edit Main Graphics Settings",
		type = "button",
		path = "Settings/Graphics",
	},
	{
		optionName = "scrollSpeed",
		chobbyName = "CameraPanSpeed",
		name = "Scroll Speed",
		min = 1,
		max = 200,
		default = 50,
		valueOverrideFunc = function ()
			return Spring.GetConfigInt("OverheadScrollSpeed", 50) or 50
		end,
		type = "number",
		path = "Settings/Camera",
	},
	{
		optionName = "zoomSpeed",
		chobbyName = "MouseZoomSpeed",
		name = "Zoom Speed",
		min = 1,
		max = 100,
		default = 25,
		valueOverrideFunc = function ()
			return math.abs(Spring.GetConfigInt("ScrollWheelSpeed", 25) or 25)
		end,
		type = "number",
		path = "Settings/Camera",
	},
	{
		optionName = "invertZoom",
		chobbyName = "InvertZoom",
		name = "Invert Zoom",
		default = false,
		valueOverrideFunc = function ()
			return (Spring.GetConfigInt("ScrollWheelSpeed", 1) or 1) > 0
		end,
		type = "bool",
		path = "Settings/Camera",
	},
}

local function AddOption(optionData)
	options[optionData.optionName] = {
		name = optionData.name,
		desc = optionData.desc,
		type = optionData.type,
		value = optionData.value or optionData.default,
		min = optionData.min,
		max = optionData.max,
		step = optionData.step,
		items = optionData.items,
		OnChange = function (self)
			if initializationComplete then
				if optionData.optionFunction then
					optionData.optionFunction(self)
				elseif optionData.chobbyName then
					if optionData.type == "number" then
						Spring.SendLuaMenuMsg(LUAMENU_SETTING .. optionData.chobbyName .. " " .. math.floor(self.value or 25))
					else
						Spring.SendLuaMenuMsg(LUAMENU_SETTING .. optionData.chobbyName .. " " .. (self.value and "On" or "Off"))
					end
				else
					WG.SetWidgetOption(optionData.optionWidget, optionData.optionPath, optionData.optionName, self.value)
				end
			end
		end,
		noHotkey = true,
		simpleMode = true,
		path = optionData.path,
	}
	
	options_order[#options_order + 1] = optionData.optionName
end

for i = 1, #optionGenerationTable do
	AddOption(optionGenerationTable[i])
end

function widget:Update()
	for i = 1, #optionGenerationTable do
		local optionData = optionGenerationTable[i]
		local option = WG.GetWidgetOption(optionData.optionWidget, optionData.optionPath, optionData.optionName)
		if optionData.valueOverrideFunc then
			options[optionData.optionName].value = optionData.valueOverrideFunc()
		elseif option.value ~= nil then
			options[optionData.optionName].value = option.value
		end
	end
	
	initializationComplete = true
	widgetHandler:RemoveWidgetCallIn("Update", self)
end