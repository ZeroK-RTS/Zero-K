--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Sun and Atmosphere Handler.",
		desc      = "Overrides sun and atmosphere for maps with poor settings",
		author    = "GoogleFrog",
		date      = "June 8, 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 100000000,
		enabled   = true --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local sunPath   = 'Settings/Graphics/Sun, Fog & Water/Sun'
local fogPath   = 'Settings/Graphics/Sun, Fog & Water/Fog'
local waterpath = 'Settings/Graphics/Sun, Fog & Water/Water'

local OVERRIDE_DIR    = LUAUI_DIRNAME .. 'Configs/MapSettingsOverride/'
local MAP_FILE        = (Game.mapName or "") .. ".lua"
local OVERRIDE_FILE   = OVERRIDE_DIR .. MAP_FILE
local OVERRIDE_CONFIG = VFS.FileExists(OVERRIDE_FILE) and VFS.Include(OVERRIDE_FILE) or false

local sunSettingsList = {}
local sunSettingsGetSunMap = {}

local defaultFog = {
	["fogStart"] = 0.99,
	["fogEnd"] = 1,
}

local initialized              = false
local sunSettingsChanged       = false
local directionSettingsChanged = false
local fogSettingsChanged       = false
local waterSettingsChanged     = false

local skip = {
	["enable_fog"] = true,
	["save_map_settings"] = true,
	["load_map_settings"] = true,
}

local defaultWaterFixParams = {
	["ambientFactor"] = 0.8,
	["blurExponent"]= 1.8,
	["diffuseFactor"]= 1.15,
	["fresnelMin"]= 0.07,
	["surfaceAlpha"] = 0.32,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings Updates

local function ResetWater()
	Spring.SendCommands("water 4")
end

local sunDir = 0
local sunPitch = math.pi*0.8

local function SunDirectionFunc(newDir, newPitch)
	directionSettingsChanged = true
	sunDir = newDir or sunDir
	sunPitch = newPitch or sunPitch
	
	local sunX = math.cos(sunPitch)*math.cos(sunDir)
	local sunY = math.sin(sunPitch)
	local sunZ = math.cos(sunPitch)*math.sin(sunDir)
	
	Spring.SetSunDirection(sunX, sunY, sunZ)
end

local function GetSunDirection()
	local sx, sy, sz = gl.GetSun("pos")
	local dir = Spring.Utilities.Vector.Angle(sx, sz)
	
	-- Idk if GetSun is guranteed to return a unit
	local norm = Spring.Utilities.Vector.Dist3D(sx, sy, sz, 0, 0, 0)
	sx, sy, sz = sx/norm, sy/norm, sz/norm
	local pitch = math.asin(sy) or 1
	--Spring.Echo("SunVec", sx, sy, sz, pitch, dir)
	return pitch, dir
end

local function FullSunUpdate()
	local sunData = {}
	for i = 1, #sunSettingsList do
		local name = sunSettingsList[i]
		sunData[name] = options[name].value
	end
	Spring.SetSunLighting(sunData)
end

local function UpdateSunValue(name, value)
	Spring.SetSunLighting({[name] = value}) -- For specularExponent, which isn't in sunSettingsList
	FullSunUpdate()
	sunSettingsChanged = true
end

local function UpdateFogValue(name, value)
	Spring.SetAtmosphere({[name] = value})
	fogSettingsChanged = true
end

local function UpdateWaterValue(name, value)
	Spring.SetWaterParams({[name] = value})
	ResetWater()
	waterSettingsChanged = true
end

local function GetSunMapSetting(thing, colType)
	if colType == "shadowDensity" then
		if thing == "unit" then
			return gl.GetSun(colType, thing)
		end
		return gl.GetSun(colType)
	end
	if thing == "unit" then
		local r, g, b = gl.GetSun(colType, thing)
		return {r, g, b, 1}
	end
	local r, g, b = gl.GetSun(colType)
	return {r, g, b, 1}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetOptionsTable(pathMatch, filter, whitelistFilter)
	-- Filter is either a blacklist of a whitelist
	local retTable = {}
	for i = 1, #options_order do
		local name = options_order[i]
		if (not skip[name]) and ((not filter) or (whitelistFilter and filter[name]) or ((not whitelistFilter) and (not filter[name]))) then
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
		sun       = sunSettingsChanged       and GetOptionsTable(sunPath, {sunDir = true, sunPitch = true}, false),
		direction = directionSettingsChanged and GetOptionsTable(sunPath, {sunDir = true, sunPitch = true}, true),
		fog       = fogSettingsChanged       and GetOptionsTable(fogPath),
		water     = waterSettingsChanged     and GetOptionsTable(waterpath),
	}
	
	WG.SaveTable(writeTable, OVERRIDE_DIR, MAP_FILE, nil, {concise = true, prefixReturn = true, endOfFile = true})
end

local function ApplyDefaultWaterFix()
	Spring.SetWaterParams(defaultWaterFixParams)
	ResetWater()
end

local function SaveDefaultWaterFix()
	local writeTable = {
		fixDefaultWater = true,
		sun       = sunSettingsChanged       and GetOptionsTable(sunPath, {sunDir = true, sunPitch = true}, false),
		direction = directionSettingsChanged and GetOptionsTable(sunPath, {sunDir = true, sunPitch = true}, true),
		fog       = fogSettingsChanged       and GetOptionsTable(fogPath),
	}
	
	WG.SaveTable(writeTable, OVERRIDE_DIR, MAP_FILE, nil, {concise = true, prefixReturn = true, endOfFile = true})
end

local function ReadSunFromMap(sunConf, dirConf)
	for i = 1, #sunSettingsList do
		local name = sunSettingsList[i]
		if not sunConf[name] then
			options[name].value = GetSunMapSetting(sunSettingsGetSunMap[name][1], sunSettingsGetSunMap[name][2])
		end
	end
	
	local pitch, dir = GetSunDirection()
	if not dirConf["sunPitch"] then
		options["sunPitch"].value = pitch
	end
	if not dirConf["sunDir"] then
		options["sunDir"].value = dir
	end
end

local function LoadSunAndFogSettings()
	local override = OVERRIDE_CONFIG or {}
	local sun = override.sun
	if sun then
		Spring.SetSunLighting(sun)
		sunSettingsChanged = true
		
		for name, value in pairs(sun) do
			if options[name] then
				options[name].value = value
			end
		end
	end
	
	local direction = override.direction
	if direction then
		SunDirectionFunc(direction.sunDir, direction.sunPitch)
		
		options["sunDir"].value = direction.sunDir
		options["sunPitch"].value = direction.sunPitch
	end
	ReadSunFromMap(sun or {}, direction or {})
	
	local fog = override.fog or defaultFog
	if fog then
		Spring.SetAtmosphere(fog)
		fogSettingsChanged = true
		
		for name, value in pairs(fog) do
			if options[name] then
				options[name].value = value
			end
		end
	end

	local water = override.water
	if water then
		Spring.SetWaterParams(water)
		waterSettingsChanged = true
		ResetWater()
	end
	
	if override.fixDefaultWater then
		ApplyDefaultWaterFix()
	end
end

local function LoadMinimapSettings()
	if (not OVERRIDE_CONFIG) or (not OVERRIDE_CONFIG.minimap) then
		return
	end
	local minimap = OVERRIDE_CONFIG.minimap
	Spring.Echo("Setting minimap brightness")
	Spring.SetSunLighting(minimap)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local waterColorDefaults = {
	{name = "absorb",        val = {0, 0, 0, 1}},
	{name = "baseColor",     val = {0, 0, 0, 1}},
	{name = "minColor",      val = {0, 0, 0, 1}},
	{name = "planeColor",    val = {0, 0.4, 0, 1}},
	{name = "surfaceColor",  val = {0.75, 0.8, 0.85, 1}},
	{name = "diffuseColor",  val = {1, 1, 1, 1}},
	{name = "specularColor", val = { 0.8, 0.8, 0.8, 1}},
}
local waterNumberDefaults = {
	{name = "ambientFactor", val = 1.0, minVal = 0, maxVal = 3},
	{name = "diffuseFactor", val = 1.0, minVal = 0, maxVal = 3},
	{name = "specularFactor", val = 1.0, minVal = 0, maxVal = 3},
	{name = "specularPower", val = 20.0, minVal = 0, maxVal = 50},

	{name = "surfaceAlpha", val = 0.5, minVal = 0, maxVal = 1},

	{name = "fresnelMin", val = 0.2, minVal = 0, maxVal = 3},
	{name = "fresnelMax", val = 0.8, minVal = 0, maxVal = 3},
	{name = "fresnelPower", val = 4.0, minVal = 0, maxVal = 10},

	{name = "reflectionDistortion", val = 1.0, minVal = 0, maxVal = 3},

	{name = "blurBase", val = 2.0, minVal = 0, maxVal = 10},
	{name = "blurExponent", val = 1.5, minVal = 0, maxVal = 10},

	{name = "perlinStartFreq", val = 8.0, minVal = 0, maxVal = 50},
	{name = "perlinLacunarity", val = 3.0, minVal = 0, maxVal = 10},
	{name = "perlinAmplitude", val = 0.9, minVal = 0, maxVal = 10},

	{name = "repeatX", val = 0.0, minVal = 0, maxVal = 50},
	{name = "repeatY", val = 0.0, minVal = 0, maxVal = 50},
}

local function GetOptions()
	local options = {}
	local options_order = {}
	
	local function AddOption(name, option)
		options[name] = option
		options_order[#options_order + 1] = name
	end
	
	local function AddColorOption(name, humanName, path, ApplyFunc, defaultVal)
		options[name] = {
			name = humanName,
			type = 'colors',
			value = defaultVal or {0.8, 0.8, 0.8, 1},
			OnChange = function (self)
				if initialized then
					Spring.Utilities.TableEcho(self.value, name)
					ApplyFunc(name, self.value)
				end
			end,
			advanced = true,
			developmentOnly = true,
			path = path
		}
		options_order[#options_order + 1] = name
	end
	
	local function AddNumberOption(name, humanName, path, ApplyFunc, defaultVal, minVal, maxVal)
		options[name] = {
			name = humanName,
			type = 'number',
			value = defaultVal or 0,
			min = minVal or -5, max = maxVal or 5, step = 0.01,
			OnChange = function (self)
				if initialized then
					ApplyFunc(name, self.value)
				end
			end,
			advanced = true,
			developmentOnly = true,
			path = path
		}
		options_order[#options_order + 1] = name
	end
	
	local function AddSunNumberOption(name, humanName, readFromMap, minVal, maxVal)
		local currentSetting = GetSunMapSetting(readFromMap[1], readFromMap[2])
		sunSettingsList[#sunSettingsList + 1] = name
		sunSettingsGetSunMap[name] = readFromMap
		AddNumberOption(name, humanName, sunPath, UpdateSunValue, currentSetting, minVal, maxVal)
	end

---------------------------------------
-- Sun
---------------------------------------
	local sunThings = {"ground", "unit"}
	local sunColors = {"Ambient", "Diffuse", "Specular"}
	local sunColorsLower = {"ambient", "diffuse", "specular"}
	for _, thing in ipairs(sunThings) do
		for i, color in ipairs(sunColors) do
			local name = thing .. color .. "Color"
			local currentColor = GetSunMapSetting(thing, sunColorsLower[i])
			sunSettingsList[#sunSettingsList + 1] = name
			sunSettingsGetSunMap[name] = {thing, sunColorsLower[i]}
			AddColorOption(name, thing .. " " .. color .. " Color", sunPath, UpdateSunValue, currentColor)
		end
	end
	
	AddSunNumberOption("groundShadowDensity", "Shadow Density when cast on ground", {"ground", "shadowDensity"}, 0, 1)
	AddSunNumberOption("modelShadowDensity", "Shadow Density when cast on units", {"unit", "shadowDensity"}, 0, 1)

	options["sunDir"] = {
		name = "Sun Direction",
		type = 'number',
		value = sunDir,
		min = 0, max = 2*math.pi, step = 0.01,
		OnChange = function (self)
			if initialized then
				SunDirectionFunc(self.value, false)
				FullSunUpdate()
			end
		end,
		advanced = true,
		developmentOnly = true,
		path = sunPath
	}
	options_order[#options_order + 1] = "sunDir"
	
	options["sunPitch"] = {
		name = "Sun Pitch",
		type = 'number',
		value = sunPitch,
		min = 0.05*math.pi, max = 0.5*math.pi, step = 0.01,
		OnChange = function (self)
			if initialized then
				SunDirectionFunc(false, self.value)
				FullSunUpdate()
			end
		end,
		advanced = true,
		developmentOnly = true,
		path = sunPath
	}
	options_order[#options_order + 1] = "sunPitch"

	-- I don't know how to read this from maps so it isn't in sunSettingsList.
	AddNumberOption("specularExponent", "Specular Exponent", sunPath, UpdateSunValue, 30, 0, 50)
	
---------------------------------------
-- Fog
---------------------------------------
	local fogThings = {"sun", "sky", "cloud", "fog"}
	for _, thing in ipairs(fogThings) do
		AddColorOption(thing .. "Color", thing .. " Color", fogPath, UpdateFogValue)
	end
	AddNumberOption("fogStart", "Fog Start", fogPath, UpdateFogValue, 0, -1, 1)
	AddNumberOption("fogEnd", "Fog End", fogPath, UpdateFogValue, -1, -1, 1)

---------------------------------------
-- Water
---------------------------------------
	for i = 1, #waterNumberDefaults do
		local data = waterNumberDefaults[i]
		AddNumberOption(data.name, data.name, waterpath, UpdateWaterValue, data.val, data.minVal, data.maxVal)
	end
	for i = 1, #waterColorDefaults do
		local data = waterColorDefaults[i]
		AddColorOption(data.name, data.name, waterpath, UpdateWaterValue, data.val)
	end

---------------------------------------
-- Save/Load
---------------------------------------
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
		OnChange = LoadSunAndFogSettings,
		advanced = true
	})
	AddOption("save_water_fix", {
		name = 'Save Water Fix',
		type = 'button',
		desc = "Save settings to infolog, overriding water with a minimal fix for default water.",
		OnChange = SaveDefaultWaterFix,
		advanced = true
	})
	AddOption("apply_water_fix", {
		name = 'Apply Water Fix',
		type = 'button',
		desc = "Test the minimal fix for default water.",
		OnChange = ApplyDefaultWaterFix,
		advanced = true
	})
	return options, options_order
end

options_path = 'Settings/Graphics/Sun, Fog & Water'
options, options_order = GetOptions()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	-- See Mantis https://springrts.com/mantis/view.php?id=5280
	Spring.Echo("SetSunLighting")
	Spring.SetSunLighting({groundSpecularColor = {0, 0, 0, 0}})

	if Spring.GetGameFrame() < 1 then
		LoadMinimapSettings()
	end
end

local updates = 0
function widget:Update()
	initialized = true
	updates = updates + 1
	if updates == 4 or updates == 28 then
		LoadSunAndFogSettings()
		if updates == 28 then
			widgetHandler:RemoveCallIn("Update")
		end
	end
end
