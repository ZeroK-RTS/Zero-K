-- This configures all the distortions weapon effects, including:
-- Projectile attached distortions
-- Muzzle flashes
-- Explosion distortions
-- Pieceprojectiles (gibs on death) distortions
-- customparams= {
-- expl_distortion_skip = bool , -- no explosion on projectile death
-- expl_distortion_color = {rgba} , -- color of the explosion distortion at peak?
-- expl_distortion_opacity = a, -- alpha or power of the distortion
-- expl_distortion_mult = ,-- fuck if i know?
-- expl_distortion_radius = , -- radius
-- expl_distortion_radius_mult = , -- why?
-- expl_distortion_life = , life of the expl distortion?

local DEBUG_MODE = false

local exampleDistortion = {
	distortionType = "point", -- or cone or beam
	pieceName = nil, -- optional
	yOffset = 10, -- optional, gives extra Y height
	fraction = 3, -- optional, only every nth projectile gets the effect (randomly)
	distortionConfig = {
		posx = 0,
		posy = 0,
		posz = 0,
		radius = 0,
		r = 1,
		g = 1,
		b = 1,
		a = 1,
		color2r = 1,
		color2g = 1,
		color2b = 1,
		colortime = 15, -- point distortions only, colortime in seconds for unit-attached
		dirx = 0,
		diry = 0,
		dirz = 1,
		theta = 0.5, -- cone distortions only, specify direction and half-angle in radians
		pos2x = 100,
		pos2y = 100,
		pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
		modelfactor = 1,
		specular = 1,
		scattering = 1,
		lensflare = 1,
		lifeTime = 0,
		sustain = 1,
		effectType = 0,
	},
}

local exampleDistortionBeamShockwave = {
	distortionType = "point", -- or cone or beam
	pieceName = nil, -- optional
	distortionConfig = {
		posx = 0,
		posy = 10,
		posz = 0,
		radius = 150,
		r = 1,
		g = 1,
		b = 1,
		a = 0.075,
		pos2x = 100,
		pos2y = 1000,
		pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
		modelfactor = 1,
		specular = 0.5,
		scattering = 0.1,
		lensflare = 1,
		lifeTime = 10,
		sustain = 1,
		effectType = "groundShockwave",
	},
}

-- Local Variables

--------------------------------------------------------------------------------
-- Config

-- Config order is:
-- Auto-assign a distortionclass to each weaponDefID
-- Override on a per-weaponDefID basis, and copy table before overriding

--------------------------------General Base Distortion Classes for further usage --------
local BaseClasses = {
	GroundShockWave = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.1,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 21,
			decay = 16,
			rampUp = 4,
			onlyModelMap = 1,
			effectStrength = 1.5, --needed for shockwaves
			shockWidth = 1.2,
			refractiveIndex = -1.2,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},
	AirShockWave = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 11,
			refractiveIndex = 1.04,
			decay = 4,
			rampUp = 2,
			effectStrength = 2.8,
			startRadius = 0.25,
			shockWidth = -0.80,
			effectType = "airShockwave",
		},
	},
	TorpedoShockWave = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 1.2,
			noiseStrength = 0.8,
			onlyModelMap = 0,
			lifeTime = 10,
			refractiveIndex = 1.2,
			decay = 3,
			rampUp = 3,
			effectStrength = 2.2,
			startRadius = 0.25,
			shockWidth = -0.95,
			effectType = "airShockwave",
		},
	},

	ExploShockWaveXS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 4.5,
			refractiveIndex = 1.04,
			decay = 3.5,
			rampUp = 1,
			effectStrength = 3.0,
			startRadius = 0.39,
			shockWidth = -1.1,
			effectType = "airShockwave",
		},
	},
	ExploShockWaveS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 5,
			refractiveIndex = 1.06,
			decay = 3.2,
			rampUp = 1,
			effectStrength = 3.2,
			startRadius = 0.39,
			shockWidth = -1.03,
			effectType = "airShockwave",
		},
	},
	ExploShockWaveM = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseScaleSpace = 0.3,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 5.5,
			refractiveIndex = 1.09,
			decay = 3,
			rampUp = 1,
			effectStrength = 3.5,
			startRadius = 0.39,
			shockWidth = -0.99,
			effectType = "airShockwave",
		},
	},
	ExploShockWaveL = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 380,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 11,
			refractiveIndex = 1.03,
			decay = 4,
			rampUp = 6,
			effectStrength = 4.1,
			startRadius = 0.33,
			shockWidth = -0.50,
			effectType = "airShockwave",
		},
	},
	ExploShockWaveXL = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 480,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 24,
			refractiveIndex = 1.02,
			decay = 4,
			rampUp = 4,
			effectStrength = 4,
			startRadius = 0.28,
			shockWidth = -0.50,
			effectType = "airShockwave",
		},
	},

	MuzzleShockWaveXS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.3,
			onlyModelMap = 0,
			lifeTime = 6,
			refractiveIndex = 1.03,
			decay = 3,
			rampUp = 1,
			effectStrength = 1.5,
			startRadius = 0.2,
			shockWidth = -0.80,
			effectType = "airShockwave",
		},
	},
	MuzzleShockWave = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.3,
			onlyModelMap = 0,
			lifeTime = 7,
			refractiveIndex = 1.03,
			decay = 6,
			rampUp = 1,
			effectStrength = 1.8,
			startRadius = 0.6,
			shockWidth = -0.80,
			effectType = "airShockwave",
		},
	},
	MuzzleShockWaveXL = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 9,
			refractiveIndex = 1.02,
			decay = 6,
			rampUp = 2,
			effectStrength = 4.0,
			startRadius = 0.5,
			shockWidth = -0.75,
			effectType = "airShockwave",
		},
	},
	
	
	-- ZK fiddling
	
	empWobble = {
		distortionType = "point",
		yOffset = 0,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			effectStrength = 0.25,
			noiseStrength = 0.85,
			noiseScaleSpace = 0.4,
			distanceFalloff = 0.25,
			onlyModelMap = 1,
			startRadius = 0.60,
			shockWidth = 20,
			refractiveIndex = -1.2,
			windAffected = -3.95,
			riseRate = -4,
			lifeTime = 25,
			rampUp = 5,
			decay = 15,
			effectType = 0,
		},
	},
	
	ExplosionHeat = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.1,
			distanceFalloff = 0.9,
			onlyModelMap = 0,
			windAffected = -1,
			effectStrength = 0.2,
			riseRate = 0.6,
			startRadius = 0.7,
			lifeTime = 100,
			rampUp = 20,
			decay = 20,
			effectType = 0,
		},
	},
	
	
	ExplosionHeatNuke = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.05,
			distanceFalloff = 0.9,
			onlyModelMap = 0,
			windAffected = -1,
			effectStrength = 0.2,
			riseRate = 0.6,
			startRadius = 0.7,
			lifeTime = 450,
			rampUp = 120,
			decay = 150,
			effectType = 0,
		},
	},
	AirShockWaveNuke = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.12,
			noiseStrength = 0.22,
			onlyModelMap = 0,
			lifeTime = 38,
			refractiveIndex = 1.1,
			decay = 15,
			rampUp = 1,
			effectStrength = 16,
			startRadius = 0.16,
			shockWidth = -0.65,
			effectType = "airShockwave",
		},
	},
	AirShockWaveNukeLater = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.12,
			noiseStrength = 0.22,
			onlyModelMap = 0,
			lifeTime = 150,
			refractiveIndex = 1.03,
			decay = 20,
			rampUp = 1,
			effectStrength = 50,
			startRadius = 0.01,
			shockWidth = 2,
			effectType = "airShockwave",
		},
	},
	GroundShockWaveNuke = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = true,
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 2,
			noiseScaleSpace = 0.10,
			effectStrength = 2.5,
			lifeTime = 70,
			decay = 25,
			rampUp = 5,
			shockWidth = 16,
			refractiveIndex = -1.1,
			startRadius = 0.02,
			effectType = "groundShockwave",
		},
	},
	
	DisruptionPulse = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 480,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 23,
			refractiveIndex = 1.015,
			distanceFalloff = 0.5,
			decay = 8,
			rampUp = 4,
			effectStrength = 0.4,
			startRadius = 0.04,
			shockWidth = 0.1,
			effectType = "airShockwave",
		},
	},
	BlackHole = {
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseStrength = 0.9,
			noiseScaleSpace = 0.5,
			onlyModelMap = 0,
			lifeTime = 330,
			distanceFalloff = 0.6,
			refractiveIndex = 1.2,
			decay = 80,
			rampUp = 4,
			effectStrength = -1.5,
			startRadius = 0.8,
			shockWidth = -1.7,
			effectType = "airShockwave",
		},
	},
	
	FireExplosionHeat = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1,
			noiseScaleSpace = 0.75,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			lifeTime = 50,
			rampUp = 2,
			decay = 10,
			effectType = 0,
		},
	},
	Implosion = { 
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 13,
			distanceFalloff = 0.6,
			refractiveIndex = 1.5,
			decay = 2,
			rampUp = 4,
			effectStrength = -1.5,
			startRadius = 0.2,
			shockWidth = -0.64,
			effectType = "airShockwave",
		},
	},
	DgunImplosion = { 
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 11,
			distanceFalloff = 1,
			refractiveIndex = 1.5,
			decay = 10,
			rampUp = 4,
			effectStrength = -2,
			startRadius = 0.7,
			shockWidth = -2,
			effectType = "airShockwave",
		},
	},
	DgunProjectile = { 
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 45,
			distanceFalloff = 1,
			refractiveIndex = 1.5,
			decay = 10,
			rampUp = 4,
			effectStrength = -2,
			startRadius = 0.7,
			shockWidth = -2,
			effectType = "airShockwave",
		},
	},
	SlowBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.18,
			noiseScaleSpace = 0.24,
			onlyModelMap = 0,
			riseRate = -0.1,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 22,
			sustain = 15,
			rampUp = 0,
			decay = 10,
			effectType = 7,
		},
	},
	DisruptorBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.4,
			noiseScaleSpace = 0.03,
			onlyModelMap = 0,
			riseRate = -0.1,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 22,
			sustain = 15,
			rampUp = 0,
			decay = 10,
			effectType = 7,
		},
	},
	ShieldGunBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.2,
			noiseStrength = 1.1,
			noiseScaleSpace = 0.35,
			onlyModelMap = 0,
			riseRate = 2,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 16,
			sustain = 5,
			rampUp = 0,
			decay = 2,
			effectType = 7,
		},
	},
	HeavyLaser = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.35,
			noiseScaleSpace = 0.08,
			onlyModelMap = 0,
			riseRate = -0.2,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 4,
			sustain = 1,
			rampUp = 0,
			decay = 3,
			effectType = 7,
		},
	},
	ExplosionHeatFirewalker = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1,
			noiseScaleSpace = 0.75,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			lifeTime = 400,
			rampUp = 30,
			decay = 260,
			effectType = 0,
		},
	},
	ExplosionHeatLong = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1.1,
			noiseScaleSpace = 0.65,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			lifeTime = 1350,
			rampUp = 30,
			decay = 600,
			effectType = 0,
		},
	},
}

local SizeRadius = {
	Quaco = 6,
	Zetto = 8,
	Atto = 11,
	Banthlaser = 13,
	Femto = 28,
	Pico = 34,
	Nano = 40,
	Micro = 44,
	DGun = 50,
	Tiniest = 60,
	Tiny = 72,
	Smallest = 90,
	Smaller = 115,
	Small = 140,
	Smallish = 165,
	SmallMedium = 190,
	Medium = 220,
	Mediumer = 260,
	MediumLarge = 320,
	Large = 400,
	Juno = 450,
	Larger = 500,
	Largest = 650,
	Mega = 800,
	MegaXL = 1000,
	MegaXXL = 1500,
	Nuke = 2800,
	Tera = 3500,
	Planetary = 5000,
}

--------------------------------------------------------------------------------

local function GetClosestSizeClass(desiredsize)
	local delta = math.huge
	local best = nil
	for classname, size in pairs(SizeRadius) do
		if math.abs(size - desiredsize) < delta then
			delta = math.abs(size - desiredsize)
			best = classname
		end
	end
	return best
end

local distortionClasses = {}

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

local currentWeaponDefID -- Evil global, only use for the debug function below
local function MarkUnits(class, size)
	if not currentWeaponDefID then
		return
	end
	local wd = WeaponDefs[currentWeaponDefID]
	local name = wd.name
	local data = name:split("_")
	local ud = data and data[1] and UnitDefNames[data[1]]
	if not ud then
		return
	end
	local units = Spring.GetTeamUnitsSorted(0)
	Spring.Echo("units", ud.id, #units, units[ud.id])
	local unitID = false
	if units[ud.id] then
		for k, v in pairs(units[ud.id]) do
			unitID = v
			break
		end
	end
	if not unitID then
		return
	end
	Spring.Utilities.UnitEcho(unitID, class .. ", " .. size)
end


local usedclasses = 0
local function GetDistortionClass(baseClassname, sizekey, additionaloverrides)
	local distortionClassKey = baseClassname .. (sizekey or "")
	if additionaloverrides and type(additionaloverrides) == "table" then
		for k, v in pairs(additionaloverrides) do
			distortionClassKey = distortionClassKey .. "_" .. tostring(k) .. "=" .. tostring(v)
		end
	end
	MarkUnits(baseClassname, sizekey)

	if distortionClasses[distortionClassKey] then
		return distortionClasses[distortionClassKey]
	else
		if not BaseClasses[baseClassname] then
			error("BaseClasses[" .. tostring(baseClassname) .. "] is nil!")
		end
		distortionClasses[distortionClassKey] = deepcopy(BaseClasses[baseClassname])
		distortionClasses[distortionClassKey].distortionClassName = distortionClassKey
		usedclasses = usedclasses + 1
		local distortionConfig = distortionClasses[distortionClassKey].distortionConfig or {}

		if sizekey and SizeRadius[sizekey] then
			distortionConfig.radius = SizeRadius[sizekey]
			if additionaloverrides then
				for k, v in pairs(additionaloverrides) do
					distortionConfig[k] = v
				end
			end
		else
			print("Warning: sizekey or SizeRadius[sizekey] is nil!")
		end
	end
	return distortionClasses[distortionClassKey]
end

--------------------------------------------------------------------------------

local gibDistortion = {
	distortionType = "point", -- or cone or beam
	pieceName = nil, -- optional
	distortionConfig = {
		posx = 0,
		posy = 0,
		posz = 0,
		radius = 12,
		lifeTime = 75,
		decay = 75,
		effectType = 0,
	},
}
-----------------------------------

-- This function automatically assigns distortions to weapons for their 3 main events:
-- It first checks for various things among the different categories of weapons, which identify if the weapon
-- should have a muzzleFlash, projectileDistortion, or an explosionDistortion.
-- See https://docs.google.com/document/d/16mvYJX8WJ8cNjGe_3zhrymTOzPoSkFprr78i_vpH7yA/edit?tab=overrideTable.0#heading=h.qx93abxpcjjo for details

-- 1. explosionDistortion - Weapon explosions based on damage and type
-- Note that this must be a table of distortions, as an explosion can consist of multiple effects, e.g.:
-- explosionDistortions[weaponID] = {GetDistortionClass("ExplosionHeat"), GetDistortionClass("GroundShockWave"), GetDistortionClass("AirShockWave")}

-- 2. muzzleFlash
-- Note that this must be a table of distortions, as a muzzle flash can consist of multiple effects, e.g.:
-- muzzleFlashDistortions[weaponID] = {GetDistortionClass("GroundShockWave"), GetDistortionClass("AirShockWave")}

-- 3. Weapon Projectiles, projectileDistortion
-- NOTE THAT ONLY A SINGLE DISTORTION CAN BE ASSIGNED TO A FLYING PROJECTILE!, e.g.:
-- projectileDefDistortions[weaponID] = GetDistortionClass("CannonProjectile")

-- 4-5. Unit/building Explosions, these also go into explosionDistortions, as tables.
-- Note that the weapons that define these explosions are in weapons/Unit_Explosions.lua,
-- and the weaponDef.customParams.unitexplosion is set to 1.
-- Unit / building explosions are not differentiated, they could easily be, by adding a customParam to the weaponDef, such as
-- weaponDef.customParams.buildingexplosion = 1
-- In this case, also also edit DeferredLightsGL4Config to ensure that both unitexplosions and weaponexplosions are handled correctly.
-- (search for weaponDef.customParams.unitexplosion)

-- CegTag -> distortion override tables for missile thruster trails
-- Uses MissileProjectile as base class with per-size overrides (same pattern as manual overrides)

local explosionDistortionsNames = {}
local muzzleFlashDistortionsNames = {}
local projectileDefDistortionsNames = {}

--------------------------------------------------------------------------------

local function GetDamageCatIds()
	local aaDamageCat, defaultDamageCat, shieldDamageCat
	for cat = 0, #Game.armorTypes do
		Spring.Echo("Game.armorTypes[cat]", Game.armorTypes[cat])
		if Game.armorTypes[cat] == "else" then
			defaultDamageCat = cat
		elseif Game.armorTypes[cat] == "planes" then
			aaDamageCat = cat
		elseif Game.armorTypes[cat] == "shield" then
			shieldDamageCat = cat
		end
	end
	return aaDamageCat, defaultDamageCat, shieldDamageCat
end

local function IsWeaponAA(weaponDef, aaDamageCat, defaultDamageCat)
	local aaDamage = weaponDef.damages[aaDamageCat]
	local defaultDamage = weaponDef.damages[defaultDamageCat]
	if not (aaDamage and defaultDamage) then
		return false
	end
	Spring.Echo("defaultDamage", defaultDamage, aaDamage)
	return (defaultDamage < aaDamage*0.11) and (defaultDamage > aaDamage*0.09)
end

local function AssignDistortionsToAllWeapons()
	local aaDamageCat, defaultDamageCat, shieldDamageCat = GetDamageCatIds()

	for weaponID = 0, #WeaponDefs do
		currentWeaponDefID = DEBUG_MODE and weaponID
		local weaponDef = WeaponDefs[weaponID]
		local weaponName = weaponDef.name
		local wcp = weaponDef.customParams
		local isAA = IsWeaponAA(weaponDef, aaDamageCat, defaultDamageCat)
		local damage = weaponDef.damages[(isAA and aaDamageCat) or defaultDamageCat]
		if weaponDef.damages[shieldDamageCat] then
			damage = weaponDef.damages[shieldDamageCat]
		end
		local isStunOrDisarm = wcp.disarmdamagemult or wcp.emp_paratime

		-- Start by collecting some common parameters of the weapon
		local projectileSpeed = weaponDef.weaponVelocity or 10
		local weaponRange = weaponDef.range or 0
		local areaofeffect = weaponDef.damageAreaOfEffect or 0
		--local weaponImpulse = weaponDef.impulseFactor or 0 (doesn't seem to work)
		local radius = ((areaofeffect * 0.7) + (areaofeffect * weaponDef.edgeEffectiveness * 1.1))
		--local effectiveRangeExplo = ((areaofeffect * 1.2) - ((1 - weaponDef.edgeEffectiveness) * areaofeffect * 0.5)) --+ (weaponImpulse * 1000)
		local effectiveRangeExplo = areaofeffect * (0.75 + (0.4 * math.sqrt(weaponDef.edgeEffectiveness)))
		--local effectiveUnitRangeExplo = areaofeffect * 2

		--local radius = (weaponDef.damageAreaOfEffect * weaponDef.edgeEffectiveness * 1.55)

		local sizeclass = GetClosestSizeClass(radius)
		local overrideTable = {}

		-- Assign projectileDistortions based on type, and decide weather muzzleflashes or explosiondistortions are needed
		if wcp.lups_noshockwave then
		elseif weaponDef.type == "BeamLaser" then
			if wcp.timeslow_damagefactor or wcp.timeslow_onlyslow then
				if damage < 20 then -- Weapon contains real damage by this point, so this catches onlyslow too.
					projectileDefDistortionsNames[weaponName] = GetDistortionClass("SlowBeam", "Atto")
				else
					projectileDefDistortionsNames[weaponName] = GetDistortionClass("DisruptorBeam", "Atto")
				end
			elseif damage > 2500 then
				projectileDefDistortionsNames[weaponName] = GetDistortionClass("HeavyLaser", "Banthlaser")
			elseif damage > 800 then
				projectileDefDistortionsNames[weaponName] = GetDistortionClass("HeavyLaser", "Atto")
			end
		elseif weaponDef.type == "DGun" then
			sizeclass = "DGun"
			projectileDefDistortionsNames[weaponName] = GetDistortionClass("DgunProjectile", "Micro")
		end

		-- Add a muzzle flash if needed:
		if wcp.lups_noshockwave then
		elseif areaofeffect > 60 and damage > 500 then
			local size = weaponRange > 2500 and "Tiniest" or "KorgLaser"
			local class = weaponRange > 2500 and "MuzzleShockWaveXL" or "MuzzleShockWave"
			muzzleFlashDistortionsNames[weaponName] = {
				GetDistortionClass(class, size),
			}
		end

		-- Add explosion distortions if needed:
		if wcp.lups_noshockwave then
		elseif (wcp.timeslow_damagefactor or wcp.timeslow_onlyslow) and wcp.nofriendlyfire then
			Spring.Echo("weaponDefweaponDefweaponDef", weaponDef.name,  GetClosestSizeClass(effectiveRangeExplo))
			explosionDistortionsNames[weaponName] = {
				GetDistortionClass("DisruptionPulse", GetClosestSizeClass(effectiveRangeExplo)),
			}
		elseif weaponDef.type == "DGun" then
			explosionDistortionsNames[weaponName] = {
				GetDistortionClass("DgunImplosion", "Micro"),
			}
		elseif weaponDef.type == "TorpedoLauncher" then
			explosionDistortionsNames[weaponName] = {
				GetDistortionClass("TorpedoShockWave", GetClosestSizeClass(radius)),
			}
		elseif weaponDef.type == "AircraftBomb" then
			explosionDistortionsNames[weaponName] = {
				GetDistortionClass("FireExplosionHeat", "SmallMedium"),
			}
		else
			local distortionClass
			if effectiveRangeExplo > 184 then
				distortionClass = "ExploShockWaveXL"
			elseif effectiveRangeExplo > 92 then
				distortionClass = "ExploShockWaveL"
			elseif effectiveRangeExplo > 48 then
				distortionClass = "ExploShockWaveM"
			elseif effectiveRangeExplo > 24 then
				distortionClass = "ExploShockWaveS"
			elseif effectiveRangeExplo > 10 then
				distortionClass = "ExploShockWaveXS"
			end
			if distortionClass then
				local adjRadius = math.max(40, effectiveRangeExplo*1.2)
				if isAA then
					adjRadius = adjRadius*0.6
				end
				local distorts = {
					GetDistortionClass(distortionClass, GetClosestSizeClass(adjRadius))
				}
				if isStunOrDisarm then
					distorts[#distorts + 1] = GetDistortionClass("empWobble", GetClosestSizeClass(adjRadius * 1.2))
				end
				explosionDistortionsNames[weaponName] = distorts
			end
		end
	end
	Spring.Echo(Spring.GetGameFrame(), "DLGL4 weapons conf using", usedclasses, "distortion types")
end
AssignDistortionsToAllWeapons() -- disable this if it doesn't work

-----------------Manual Overrides--------------------

projectileDefDistortionsNames.jumpblackhole_black_hole = GetDistortionClass("BlackHole", "Micro")

projectileDefDistortionsNames.shieldfelon_shieldgun = GetDistortionClass("ShieldGunBeam", "Atto")

explosionDistortionsNames.shieldbomb_shieldbomb_death = explosionDistortionsNames.shieldbomb_shieldbomb_death or {}
explosionDistortionsNames.shieldbomb_shieldbomb_death[#explosionDistortionsNames.shieldbomb_shieldbomb_death + 1] = GetDistortionClass("ExplosionHeat", "Medium")

explosionDistortionsNames.jumpblackhole_black_hole = explosionDistortionsNames.jumpblackhole_black_hole or {}
explosionDistortionsNames.jumpblackhole_black_hole[#explosionDistortionsNames.jumpblackhole_black_hole + 1] = GetDistortionClass("BlackHole", "Small")

explosionDistortionsNames.bomberheavy_arm_pidr = {
	GetDistortionClass("Implosion", "Medium")
}

explosionDistortionsNames.spidercrabe_arm_crabe_gauss = {
	GetDistortionClass("GroundShockWave", "Smallish", {
		shockWidth = 8,
	}),
}

explosionDistortionsNames.spidercrabe_arm_crabe_gauss = {
	GetDistortionClass("GroundShockWave", "Smallish", {
		shockWidth = 8,
	}),
}
explosionDistortionsNames.jumparty_napalm_sprayer = {
	GetDistortionClass("ExplosionHeatFirewalker", "Small"),
}
explosionDistortionsNames.napalmmissile_weapon = {
	GetDistortionClass("ExplosionHeatLong", "Juno"),
}

explosionDistortionsNames.staticnuke_crblmssl = {
	GetDistortionClass("ExplosionHeatNuke", "MegaXXL"),
	GetDistortionClass("AirShockWaveNuke", "Nuke"),
	GetDistortionClass("AirShockWaveNukeLater", "Nuke"),
	GetDistortionClass("GroundShockWaveNuke", "Nuke"),
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local muzzleFlashDistortions = {}
local explosionDistortions = {}
local projectileDefDistortions = {
	default = {
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 16,
			posz = 0,
			radius = 420,
			lifeTime = 50,
			sustain = 20,
			effectType = 0,
		},
	},
}

-- convert weaponname -> weaponDefID
for name, distortionList in pairs(explosionDistortionsNames) do
	if WeaponDefNames[name] then
		explosionDistortions[WeaponDefNames[name].id] = distortionList
	end
end
explosionDistortionsNames = nil

-- convert weaponname -> weaponDefID
for name, distortionList in pairs(muzzleFlashDistortionsNames) do
	if WeaponDefNames[name] then
		muzzleFlashDistortions[WeaponDefNames[name].id] = distortionList
	end
end
muzzleFlashDistortionsNames = nil

-- convert weaponname -> weaponDefID
for name, params in pairs(projectileDefDistortionsNames) do
	if WeaponDefNames[name] then
		projectileDefDistortions[WeaponDefNames[name].id] = params
	end
end
projectileDefDistortionsNames = nil

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Projectile Collection

return {
	muzzleFlashDistortions = muzzleFlashDistortions,
	projectileDefDistortions = projectileDefDistortions,
	explosionDistortions = explosionDistortions,
	gibDistortion = gibDistortion,
}
