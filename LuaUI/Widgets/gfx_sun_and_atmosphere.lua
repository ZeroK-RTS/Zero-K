--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Sun and Atmosphere Handler.",
		desc      = "Overrides sun and atmosphere for maps with poor settings",
		author    = "GoogleFrog",
		date      = "June 8, 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local OVERRIDE_DIR = LUAUI_DIRNAME .. 'Configs/MapSettingsOverride/'
local OVERRIDE_FILE = OVERRIDE_DIR .. (Game.mapName or "") .. ".lua"
local OVERRIDE_CONFIG = VFS.FileExists(OVERRIDE_FILE) and VFS.Include(OVERRIDE_FILE) or false

local skip = {
	["enable_fog"] = true,
	["save_map_settings"] = true,
	["load_map_settings"] = true,
}

local function GetOptionsTable(pathMatch)
	local retTable = {}
	for i = 1, #options_order do
		local name = options_order[i]
		if not skip[name] then
			local option = options[name]
			if option.path == pathMatch then
				retTable[name] = option.value
			end
		end
	end
	return retTable
end

local function SaveSettings()
	local writeTable = {
		sun = GetOptionsTable('Settings/Graphics/Sun and Fog/Sun'),
		fog = GetOptionsTable('Settings/Graphics/Sun and Fog/Sun')
	}

	WG.SaveTable(writeTable, OVERRIDE_DIR, OVERRIDE_FILE, nil, {concise = true, prefixReturn = true, endOfFile = true})
end

local function LoadSettings()
	if not OVERRIDE_CONFIG then
		return
	end
	local sun = OVERRIDE_CONFIG.sun
	local fog = OVERRIDE_CONFIG.fog
	
	Spring.SetSunLighting(sun)
	Spring.SetAtmosphere(fog)
	
	for name, value in pairs(sun) do
		options[name].value = value
	end
	for name, value in pairs(fog) do
		options[name].value = value
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetOptions()
	local fogPath = 'Settings/Graphics/Sun and Fog/Fog'
	local sunPath = 'Settings/Graphics/Sun and Fog/Sun'
	
	local options = {}
	local options_order = {}
	
	local function AddOption(name, option)
		options[name] = option
		options_order[#options_order + 1] = name
	end
	
	local options_order = {'enable_fog', 'save_map_settings', 'load_map_settings'}
	
	local function AddColorOption(name, humanName, path, ColorFunction)
		options[name] = {
			name = humanName,
			type = 'colors',
			value = { 0.8, 0.8, 0.8, 1},
			OnChange = function (self)
				Spring.Echo("ColorFunction", name, self.value)
				ColorFunction({[name] = self.value})
			end,
			advanced = true,
			path = path
		}
		options_order[#options_order + 1] = name
	end
	
	local function AddNumberOption(name, humanName, path, NumberFunction)
		options[name] = {
			name = humanName,
			type = 'number',
			value = 0,
			min = -5, max = 5, step = 0.01,
			OnChange = function (self) 
				Spring.Echo("NumberFunction", name, self.value)
				NumberFunction({[name] = self.value})
			end,
			advanced = true,
			path = path
		}
		options_order[#options_order + 1] = name
	end
	
	local sunThings = {"ground", "unit"}
	local sunColors = {"Ambient", "Diffuse", "Specular"}
	for _, thing in ipairs(sunThings) do
		for _, color in ipairs(sunColors) do
			AddColorOption(thing .. color .. "Color", thing .. " " .. color .. "Color", sunPath, Spring.SetSunLighting)
		end
	end
	
	AddNumberOption("specularExponent", "Specular Exponent", sunPath, Spring.SetSunLighting)
	
	local fogThings = {"sun", "sky", "cloud", "fog"}
	for _, thing in ipairs(fogThings) do
		AddColorOption(thing .. "Color", thing .. " Color", fogPath, Spring.SetAtmosphere)
	end
	AddNumberOption("fogStart", "Fog Start", fogPath, Spring.SetAtmosphere)
	AddNumberOption("fogEnd", "Fog End", fogPath, Spring.SetAtmosphere)	
	
	
	AddOption("enable_fog", {
		name = "Enable fog",
		type = 'bool',
		value = true,
		noHotkey = true,
	})
	AddOption("save_map_settings", {
		name = 'Save Settings',
		type = 'button',
		desc = "Save settings to infolog.",
		OnChange = SaveSettings,
		advanced = true
	})
	AddOption("load_map_settings", {
		name = 'Load Settings',
		type = 'button',
		desc = "Load the settings, if the map has a config.",
		OnChange = LoadSettings,
		advanced = true
	})
	
	return options, options_order
end

options_path = 'Settings/Graphics/Sun and Fog'
options, options_order = GetOptions()

function widget:Initialize()
	LoadSettings()
end