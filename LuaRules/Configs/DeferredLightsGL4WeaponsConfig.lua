
local gibLight = {
	lightType = 'point', -- or cone or beam
	pieceName = nil, -- optional
	lightConfig = {
		posx = 0, posy = 0, posz = 0, radius = 52,
		r = 1, g = 0.9, b = 0.5, a = 0.08,
		color2r = 0.9, color2g = 0.75, color2b = 0.25, colortime = 0.3, -- point lights only, colortime in seconds for unit-attache
		modelfactor = 0.4, specular = 0.5, scattering = 0.5, lensflare = 0,
		lifetime = 300, sustain = 3, selfshadowing = 0 
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local baseLightDefs = VFS.Include("LuaUI/Configs/projectileLightDefs.lua")
local projLights = {}
local explosionLights = {}

for weaponDefID = 1, #WeaponDefs do
	local wep = baseLightDefs[weaponDefID]
	if wep then
		if wep.beam then
			local lightTime = (wep.fadeTime or 0) + 15
			projLights[weaponDefID] = {
				lightType = 'beam', -- or cone or beam
				lightConfig = {
					posx = 0, posy = 0, posz = 0, radius = wep.radius,
					colortime = lightTime,
					r = wep.r, g = wep.g, b = wep.b, a = wep.a,
					pos2x = 100, pos2y = 1000, pos2z = 100, -- beam lights only, specifies the endpoint of the beam
					modelfactor = 1, specular = 0.5, scattering = 2.5, lensflare = 1,
					lifetime = lightTime, sustain = lightTime*0.1, selfshadowing = 0, 
				}
			}
		else
			projLights[weaponDefID] = {
				lightType = 'point', -- or cone or beam
				lightConfig = {
					posx = 0, posy = wep.elevation or 10, posz = 0, radius = wep.radius,
					r = wep.r, g = wep.g, b = wep.b, a = wep.a,
					modelfactor = 0.5, specular = 0.6, scattering = 0.5, lensflare = 0,
					lifetime = 0, sustain = 0, selfshadowing = 0, 
				}
			}
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local BaseClasses = {
	Explosion = { -- spawned on explosions
		lightType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		lightConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 240,
			dirx = 0,
			diry = 10,
			dirz = 0,
			theta = 0.93, -- Give explosions a bit of a vertical bounce component
			r = 2,
			g = 2,
			b = 2,
			a = 0.6,
			color2r = 0.7,
			color2g = 0.55,
			color2b = 0.28,
			colortime = 0.1, -- point lights only, colortime in seconds for unit-attached
			modelfactor = 0.15,
			specular = 0.15,
			scattering = 0.4,
			lensflare = 1,
			lifetime = 12,
			sustain = 3,
			selfshadowing = 4,
		},
	},
}

local SizeRadius = {
	Pico = 26,
	Nano = 34,
	Micro = 44,
	Tiniest = 56,
	Tiny = 72,
	Smallest = 90,
	Smaller = 115,
	Small = 140,
	Smallish = 165,
	SmallMedium = 190,
	Medium = 220,
	Mediumer = 260,
	MediumLarge = 300,
	Large = 400,
	Larger = 500,
	Largest = 650,
	Mega = 800,
	MegaXL = 1000,
	MegaXXL = 1500,
	Giga = 2000,
	Tera = 3500,
	Planetary = 5000,
}

local ColorSets = { -- TODO add advanced dual-color sets!
	Red = { r = 1, g = 0, b = 0 },
	Green = { r = 0, g = 1, b = 0 },
	Blue = { r = 0, g = 0, b = 1 },
	Purple = { r = 0.7, g = 0.3, b = 1 },
	Yellow = { r = 1, g = 1, b = 0 },
	White = { r = 1, g = 1, b = 1 },
	Plasma = { r = 1, g = 0.8, b = 0.45 },
	HeatRay = { r = 0.88, g = 0.65, b = 0.10 },
	Emg = { r = 0.42, g = 0.32, b = 0.07 },
	Fire = { r = 0.8, g = 0.3, b = 0.05 },
	Warm = { r = 0.7, g = 0.7, b = 0.1 },
	Cold = { r = 0.5, g = 0.75, b = 1.0 },
	Emp = { r = 0.5, g = 0.5, b = 1.0 },
	Team = { r = -1, g = -1, b = -1 },
}

local function GetClosestSizeClass(desiredsize)
	local delta = math.huge
	local best = nil
	for classname, size in pairs(SizeRadius) do
		if math.abs(size - desiredsize) < delta then
			delta = math.abs(size - desiredsize)
			best = classname
		end
	end
	return best, SizeRadius[best]
end

local lightClasses = {}

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		--setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local usedclasses = 0
local function GetLightClass(baseClassname, colorkey, sizekey, additionaloverrides)
	local lightClassKey = baseClassname .. (colorkey or "") .. (sizekey or "")
	if additionaloverrides and type(additionaloverrides) == "table" then
		for k, v in pairs(additionaloverrides) do
			lightClassKey = lightClassKey .. "_" .. tostring(k) .. "=" .. tostring(v)
		end
	end

	if lightClasses[lightClassKey] then
		return lightClasses[lightClassKey]
	else
		lightClasses[lightClassKey] = deepcopy(BaseClasses[baseClassname])
		lightClasses[lightClassKey].lightClassName = lightClassKey
		usedclasses = usedclasses + 1
		local lightConfig = lightClasses[lightClassKey].lightConfig
		if sizekey then
			lightConfig.radius = SizeRadius[sizekey]
		end
		if colorkey then
			lightConfig.r = ColorSets[colorkey].r
			lightConfig.g = ColorSets[colorkey].g
			lightConfig.b = ColorSets[colorkey].b
			if lightClasses[lightClassKey].lightType == "point" then
				lightConfig.color2r = ColorSets[colorkey].color2r or lightConfig.color2r
				lightConfig.color2g = ColorSets[colorkey].color2g or lightConfig.color2g
				lightConfig.color2b = ColorSets[colorkey].color2b or lightConfig.color2b
				lightConfig.colortime = ColorSets[colorkey].colortime or lightConfig.colortime
			end
		end
		if additionaloverrides then
			for k, v in pairs(additionaloverrides) do
				lightConfig[k] = v
			end
		end
	end
	return lightClasses[lightClassKey]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Bespoke explosions

explosionLightsNames.staticnuke_crblmssl = GetLightClass("Explosion", nil, "Planetary", {
	r = 2.92,
	g = 2.64,
	b = 1.76,
	a = 0.2,
	color2r = 1.0,
	color2g = 0.6,
	color2b = 0.18,
	colortime = 200,
	sustain = 180,
	lifetime = 200,
	modelfactor = 0.1,
	specular = 0.2,
	scattering = 0.1,
	lensflare = 4,
})

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return {muzzleFlashLights = {}, projectileDefLights = projLights, explosionLights = explosionLights, gibLight = gibLight}
