
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
}

local function AddOption(optionData)
	options[optionData.optionName] = {
		name = optionData.name,
		desc = optionData.desc,
		type = optionData.type,
		value = optionData.default,
		OnChange = function (self)
			if initializationComplete then
				WG.SetWidgetOption(optionData.optionWidget, optionData.optionPath, optionData.optionName, self.value)
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