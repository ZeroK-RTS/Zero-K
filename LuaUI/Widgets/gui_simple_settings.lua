
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
		default = 0.19, 
		min = 0.05, 
		max = 0.4,
		step = 0.01,
		path = "Settings/Interface",
	},
	{
		optionName = "unitLabel",
		name = "Unit Effects",
		type = "label",
		path = "Settings/Graphics",
	},
	{
		optionName = "unitPlatter",
		optionFunction = function(self) Spring.SendCommands{"luaui togglewidget Fancy Teamplatter"} end,
		name = "Toggle Unit Platter",
		desc = "Puts a team-coloured platter-halo below units.",
		type = "button",
		path = "Settings/Graphics",
	},
	{
		optionName = "unitOutline",
		optionFunction = function(self) Spring.SendCommands{"luaui togglewidget Outline"} end,
		name = "Toggle Unit Outline",
		desc = "Draws a black outline around units.",
		type = "button",
		path = "Settings/Graphics",
	},
	{
		optionName = "moreOptions",
		name = "",
		value = "More graphics options are available in the main menu under Settings -> Graphics.",
		type = "text",
		path = "Settings/Graphics",
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
		if option.value ~= nil then
			options[optionData.optionName].value = option.value
		end
	end
	
	initializationComplete = true
	widgetHandler:RemoveWidgetCallIn("Update", self)
end