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

	LaserProjectile = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 100,
			pos2x = 100,
			pos2y = 1000,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 0,
			sustain = 1,
			effectType = 0,
		},
	},

	CannonProjectile = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 125,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	LaserCannonExplosion = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 125,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	PlasmaTrailProjectile = {
		distortionType = "cone",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 100,
			dirx = 0,
			diry = 1,
			dirz = 1.0,
			theta = 0.09,
			noiseStrength = 6,
			noiseScaleSpace = 0.25,
			distanceFalloff = 1.5,
			onlyModelMap = 1,
			windAffected = -1,
			riseRate = 0,
			yoffset = 5,
			lifeTime = 0,
			rampUp = 30,
			decay = 5,
			effectType = 0,
		},
	},

	RailgunTrailProjectile = {
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 100,
			--dirx =  0, diry = 1, dirz = 1.0, theta = 0.12,
			noiseStrength = 8,
			noiseScaleSpace = -0.35,
			distanceFalloff = 0.8,
			onlyModelMap = 0,
			refractiveIndex = 1.04,
			windAffected = -0.5,
			riseRate = 0.5, --yoffset = -2,
			lifeTime = 0,
			rampUp = 0,
			decay = 0,
			effectType = 0,
		},
	},

	LaserBeamShockWaveProjectile = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 150,
			pos2x = 100,
			pos2y = 1000,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 10,
			sustain = 1,
			effectType = "groundShockwave",
		},
	},

	LaserBeamHeat = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 10,
			noiseStrength = 0.3,
			noiseScaleSpace = 0.3,
			effectStrength = 0.5,
			pos2x = 100,
			pos2y = 1000,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 0,
			rampUp = 2,
			decay = 0,
			effectType = 0,
		},
	},

	HeatRayHeat = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 10,
			noiseStrength = 0.75,
			noiseScaleSpace = 0.15,
			distanceFalloff = 1.5,
			windAffected = -1,
			riseRate = 0.2,
			pos2x = 100,
			pos2y = 1000,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 3,
			rampUp = 3,
			decay = 0,
			effectType = 0,
		},
	},
	HeatRayHeatXL = { --heaviest laserbeam (corkorg)
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 10,
			pos2x = 0,
			pos2y = 0,
			pos2z = 0,
			radius2 = 1,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.022,
			distanceFalloff = 0.2,
			effectStrength = 1.0,
			windAffected = -1,
			riseRate = 4.2,
			onlyModelMap = 0,
			--refractiveIndex = 1.15,
			lifeTime = 0,
			rampUp = 0,
			decay = 0,
			effectType = 7,
		},
	},

	TachyonBeam = {
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

	LightningBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 20,
			noiseStrength = 0.7,
			noiseScaleSpace = 0.05,
			distanceFalloff = 2.5,
			effectStrength = 4.0,
			windAffected = -1,
			riseRate = -0.6,
			pos2x = 100,
			pos2y = 1000,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 0,
			rampUp = 0,
			decay = 0,
			effectType = 0,
		},
	},

	EMPBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 10,
			noiseStrength = 1.0,
			noiseScaleSpace = 0.16,
			distanceFalloff = 1.0,
			effectStrength = 2.5,
			onlyModelMap = -1,
			--windAffected = 2, riseRate = 2,
			windAffected = -1,
			riseRate = -3.2,
			pos2x = 100,
			pos2y = 100,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 0,
			rampUp = 0,
			decay = 2,
			effectType = 0,
		},
	},
	EMPBeamXL = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 10,
			posz = 0,
			radius = 10,
			noiseStrength = 1.0,
			noiseScaleSpace = 0.12,
			distanceFalloff = 0.5,
			effectStrength = 3.0,
			--onlyModelMap = 1,
			--windAffected = 2, riseRate = 2,
			windAffected = -1,
			riseRate = -2.2,
			pos2x = 100,
			pos2y = 100,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 0,
			rampUp = 0,
			decay = 1,
			effectType = 0,
		},
	},

	AirBombProjectile = {
		distortionType = "cone",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 70,
			dirx = 0,
			diry = 1,
			dirz = 1.0,
			theta = 0.2,
			startRadius = 0.5,
			onlyModelMap = 1,
			noiseStrength = 1.45,
			noiseScaleSpace = 0.75,
			distanceFalloff = 1.8,
			onlyModelMap = 0,
			yoffset = 8,
			effectStrength = 2.0,
			windAffected = -1,
			riseRate = -0.3,
			rampUp = 15,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	MissileProjectile = {
		distortionType = "cone",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 100,
			dirx = 0,
			diry = 1,
			dirz = 1.0,
			theta = 0.1,
			startRadius = 0.5,
			onlyModelMap = 1,
			noiseStrength = 1.45,
			noiseScaleSpace = 0.75,
			distanceFalloff = 1.8,
			onlyModelMap = 0,
			yoffset = 8,
			effectStrength = 1.0,
			windAffected = -1,
			riseRate = -0.3,
			rampUp = 15,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	MissileProjectileXL = {
		distortionType = "cone",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 130,
			startRadius = 0.5,
			onlyModelMap = 1,
			dirx = 0,
			diry = 1,
			dirz = 1.0,
			theta = 0.08,
			noiseStrength = 4,
			noiseScaleSpace = 0.37,
			distanceFalloff = 1.8,
			onlyModelMap = 0,
			yoffset = 10,
			effectStrength = 1.2,
			windAffected = -1,
			riseRate = -0.3,
			rampUp = 4,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	MissileNukeProjectile = {
		distortionType = "cone",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 00,
			radius = 200,
			dirx = 0,
			diry = 1,
			dirz = 1.0,
			theta = 0.3,
			noiseStrength = 4,
			noiseScaleSpace = 0.3,
			distanceFalloff = 1.0,
			onlyModelMap = 0,
			rampUp = 30,
			yoffset = 8,
			lifeTime = 0,
			sustain = 0,
			effectType = 0,
		},
	},

	LaserAimProjectile = {
		distortionType = "cone", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 500,
			dirx = 1,
			diry = 0,
			dirz = 1,
			theta = 0.02, -- cone distortions only, specify direction and half-angle in radians
			lifeTime = 0,
			sustain = 1,
			effectType = 0,
		},
	},

	GroundShockWaveXS = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.6,
			noiseStrength = 0.35,
			noiseScaleSpace = 0.8,
			lifeTime = 12,
			decay = 8,
			rampUp = 4,
			onlyModelMap = 1,
			effectStrength = 1.2, --needed for shockwaves
			shockWidth = 1,
			refractiveIndex = 1.1,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},

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
	GroundShockWaveHeat = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		--fraction = 5, --doesn't work
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.1,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 16,
			decay = 13,
			rampUp = 3,
			onlyModelMap = 1,
			effectStrength = 0.8, --needed for shockwaves
			shockWidth = -1.9,
			refractiveIndex = -2.04,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},
	AirShockWaveCommander = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.9,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 13,
			refractiveIndex = 2.0,
			decay = 7,
			rampUp = 5,
			effectStrength = 4.0,
			startRadius = 0.24,
			shockWidth = -0.85, --needed for airshockwaves
			effectType = "airShockwave",
		},
	},
	GroundShockWaveCommander = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 2,
			noiseScaleSpace = 0.10,
			effectStrength = 1.5, --needed for shockwaves
			lifeTime = 20,
			decay = 10,
			rampUp = 10,
			shockWidth = 4,
			refractiveIndex = -2.1,
			startRadius = 0.16,
			effectType = "groundShockwave",
		},
	},
	GroundShockWaveCommanderSlow = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 1.5,
			noiseScaleSpace = 0.30,
			effectStrength = 0.7, --needed for shockwaves
			lifeTime = 100,
			decay = 75,
			rampUp = 25,
			shockWidth = 1,
			refractiveIndex = -10.1,
			startRadius = 0.15,
			effectType = "groundShockwave",
		},
	},

	GroundShockWaveNuke = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 2,
			noiseScaleSpace = 0.10,
			effectStrength = 1.0, --needed for shockwaves
			lifeTime = 100,
			decay = 25,
			rampUp = 5,
			shockWidth = 16,
			refractiveIndex = -1.1,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},

	GroundShockWaveFuzzy = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 1.0,
			onlyModelMap = 0,
			effectStrength = 1.2, --needed for shockwaves
			shockWidth = 3,
			startRadius = 0.24,
			lifeTime = 25,
			effectType = "groundShockwave",
		},
	},

	GroundAcidExplo = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.9,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.7,
			lifeTime = 200,
			decay = 150,
			rampUp = 50,
			effectStrength = 0.75, --needed for shockwaves
			windAffected = -0.5,
			riseRate = 6, --used for width of shockwave
			shockWidth = 6,
			refractiveIndex = -1.2,
			startRadius = 0.5,
			onlyModelMap = 1,
			effectType = "groundShockwave",
		},
	},

	ExploUnitAirShockWave = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.15,
			noiseStrength = 0.3,
			onlyModelMap = 0,
			lifeTime = 12,
			refractiveIndex = 1.04,
			decay = 5,
			rampUp = 1,
			effectStrength = 5.0,
			startRadius = 0.3,
			shockWidth = -0.70,
			effectType = "airShockwave",
		},
	},

	AirShockWaveXS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 1.1,
			noiseStrength = 0.01,
			onlyModelMap = 1,
			lifeTime = 7,
			refractiveIndex = 1.03,
			decay = 4,
			rampUp = 3,
			effectStrength = 2.0,
			startRadius = 0.20,
			shockWidth = -0.60, --needed for all distortions
			effectType = "airShockwave",
		},
	},
	-- AirShockWaveMG = { --for machineguns
	-- 	distortionType = 'point', -- or cone or beam
	-- 	distortionConfig = { posx = 0, posy = 0, posz = 0, radius = 150,
	-- 		noiseScaleSpace = 1.1, noiseStrength = 0.01, onlyModelMap = 1,
	-- 		lifeTime = 4, refractiveIndex = 1.03, decay = 2, rampUp = 1,
	-- 		effectStrength = 1.0, startRadius = 0.10, shockWidth = -0.90, --needed for all distortions
	-- 		effectType = "airShockwave", },
	-- },
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
	AirShockWaveDgun = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.5,
			noiseStrength = 1,
			onlyModelMap = 0,
			lifeTime = 30,
			refractiveIndex = -4.0,
			decay = 5,
			rampUp = 15,
			startRadius = 0.24,
			shockWidth = -0.95,
			effectStrength = 0.9, --needed for airshockwaves
			effectType = "airShockwave",
		},
	},
	AirShockWaveNuke = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.05,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 25,
			refractiveIndex = 1.1,
			decay = 20,
			rampUp = 1,
			effectStrength = 20.0,
			startRadius = 0.2,
			shockWidth = -0.70, --needed for airshockwaves
			effectType = "airShockwave",
		},
	},
	AirShockWaveNukeBlast = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 225,
			noiseScaleSpace = 0.3,
			noiseStrength = 0.5,
			onlyModelMap = 1,
			lifeTime = 150,
			refractiveIndex = 1.5,
			decay = 60,
			rampUp = 40,
			effectStrength = 1.0,
			startRadius = 0.05,
			shockWidth = 0.25,
			windAffected = 3,
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

	-- ALL CANNON explosion Classes

	ExploShockWaveXS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 100,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 4,
			refractiveIndex = 1.04,
			decay = 3,
			rampUp = 1,
			effectStrength = 3.0,
			startRadius = 0.4,
			shockWidth = -1.2,
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

	-- ALL UNIT Explosion Classes

	UnitExploShockWaveXS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 100,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 5,
			refractiveIndex = 1.07,
			decay = 4,
			rampUp = 1,
			effectStrength = 4.5,
			startRadius = 0.45,
			shockWidth = -0.50,
			effectType = "airShockwave",
		},
	},
	UnitExploShockWaveS = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 6,
			refractiveIndex = 1.05,
			decay = 4,
			rampUp = 2,
			effectStrength = 4.25,
			startRadius = 0.41,
			shockWidth = -0.55,
			effectType = "airShockwave",
		},
	},
	UnitExploShockWaveM = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 9,
			refractiveIndex = 1.045,
			decay = 5,
			rampUp = 2,
			effectStrength = 4.0,
			startRadius = 0.38,
			shockWidth = -0.60,
			effectType = "airShockwave",
		},
	},
	UnitExploShockWaveL = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 400,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 11,
			refractiveIndex = 1.041,
			decay = 5,
			rampUp = 3,
			effectStrength = 4.2,
			startRadius = 0.33,
			shockWidth = -0.61,
			effectType = "airShockwave",
		},
	},
	UnitExploShockWaveXL = {
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 480,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.4,
			onlyModelMap = 0,
			lifeTime = 14,
			refractiveIndex = 1.035,
			decay = 6,
			rampUp = 3,
			effectStrength = 4.5,
			startRadius = 0.20,
			shockWidth = -0.36,
			effectType = "airShockwave",
		},
	},

	UnitGroundShockWave = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.5,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 25,
			decay = 25,
			rampUp = 15,
			effectStrength = 1.5, --needed for shockwaves
			shockWidth = 3,
			refractiveIndex = -1.2,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},
	UnitGroundShockWaveXL = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.5,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 25,
			decay = 25,
			rampUp = 15,
			effectStrength = 1.5, --needed for shockwaves
			shockWidth = 3,
			refractiveIndex = -1.2,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},

	BuildingGroundShockWave = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.5,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 25,
			decay = 25,
			rampUp = 15,
			effectStrength = 1.5, --needed for shockwaves
			shockWidth = 3,
			refractiveIndex = -1.2,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},
	BuildingGroundShockWaveXL = {
		distortionType = "point", -- or cone or beam
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.5,
			noiseStrength = 0.5,
			noiseScaleSpace = 0.8,
			lifeTime = 25,
			decay = 25,
			rampUp = 15,
			effectStrength = 1.5, --needed for shockwaves
			shockWidth = 3,
			refractiveIndex = -1.2,
			startRadius = 0.24,
			effectType = "groundShockwave",
		},
	},
	BuildingExploEnergy = {
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 2,
			noiseScaleSpace = 0.95,
			distanceFalloff = 1.5,
			onlyModelMap = 0,
			startRadius = 0.3,
			lifeTime = 20,
			rampUp = 7,
			decay = 13,
			effectType = 0,
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
			effectStrength = 1.9,
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
			effectStrength = 2.2,
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

	AirShockWaveBeam = {
		distortionType = "beam", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.5,
			noiseStrength = 1.0,
			lifeTime = 15,
			refractiveIndex = 1.05,
			--
			effectStrength = 1.0, --needed for irshockwaves
			effectType = "airShockwave",
		},
	},

	TorpedoProjectile = {
		distortionType = "cone", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 300,
			dirx = 1,
			diry = 0,
			dirz = 1,
			theta = 0.10, -- cone distortions only, specify direction and half-angle in radians
			noiseStrength = 2,
			noiseScaleSpace = 0.90,
			distanceFalloff = 0.9,
			onlyModelMap = 0,
			lifeTime = 0,
			sustain = 1,
			effectType = 0,
		},
	},

	FlameProjectile = {
		distortionType = "point", -- or cone or beam
		fraction = 5, -- only spawn every nth distortion
		distortionConfig = {
			posx = 0,
			posy = 15,
			posz = 0,
			radius = 25,
			noiseStrength = 8,
			noiseScaleSpace = -0.30,
			distanceFalloff = 0.9,
			onlyModelMap = 0,
			windAffected = 0.2,
			riseRate = -0.5,
			lifeTime = 29,
			rampUp = 15,
			decay = 10,
			effectType = 0,
		},
	},
	FlameProjectileXL = {
		distortionType = "point", -- or cone or beam
		fraction = 3, -- only spawn every nth distortion (lowered from 8 -- cordemon/corcrwh have long flame ranges and 1-in-8 left visible gaps)
		distortionConfig = {
			posx = 0,
			posy = 45,
			posz = 0,
			radius = 25,
			noiseStrength = 4,
			noiseScaleSpace = -0.45,
			distanceFalloff = 1.6,
			onlyModelMap = 0,
			windAffected = 0.1,
			riseRate = -0.5,
			lifeTime = 40,
			rampUp = 30,
			decay = 30,
			effectType = 0,
		},
	},
	FireHeat = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1.3,
			noiseScaleSpace = 0.60,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			refractiveIndex = 0.9,
			windAffected = 1.3,
			riseRate = 1.5,
			lifeTime = 20,
			rampUp = 10,
			decay = 10,
			effectType = 0,
		},
	},

	ExplosionDistort = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 2,
			noiseScaleSpace = 0.95,
			distanceFalloff = 1.5,
			onlyModelMap = 0,
			startRadius = 0.3,
			lifeTime = 20,
			rampUp = 7,
			decay = 13,
			effectType = 0,
		},
	},

	ExplosionHeatXS = { -- spawned on explosions
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
			onlyModelMap = 0,
			lifeTime = 30,
			rampUp = 15,
			decay = 20,
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
			noiseStrength = 1,
			noiseScaleSpace = 0.75,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			lifeTime = 20,
			rampUp = 30,
			decay = 10,
			effectType = 0,
		},
	},
	ExplosionHeatFirewalker = { -- spawned on explosions
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
			lifeTime = 400,
			rampUp = 30,
			decay = 260,
			effectType = 0,
		},
	},
	ExplosionHeatLong = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
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
	ExplosionHeatNuke = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 75,
			noiseScaleSpace = 0.034,
			distanceFalloff = 0.5,
			onlyModelMap = 0,
			windAffected = -1,
			riseRate = 0.3,
			startRadius = 0.4,
			lifeTime = 12,
			rampUp = 2,
			decay = 10,
			effectType = 0,
		},
	},
	ExplosionRadiationNuke = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 20,
			noiseScaleSpace = 0.1,
			distanceFalloff = 0.5,
			onlyModelMap = 0,
			windAffected = -1,
			riseRate = -0.5,
			lifeTime = 200,
			rampUp = 100,
			decay = 100,
			effectType = 0,
		},
	},
	ExplosionRadiationDgun = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		fraction = 6,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 6,
			noiseScaleSpace = 0.55,
			distanceFalloff = 1.2,
			onlyModelMap = 1,
			windAffected = -1,
			riseRate = -0.5,
			lifeTime = 50,
			rampUp = 20,
			decay = 25,
			effectType = 0,
		},
	},

	JunoHeat = { -- unused
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
			onlyModelMap = 0,
			lifeTime = 60,
			rampUp = 30,
			decay = 30,
			effectType = 7,
		},
	},

	EMPShockWave = { -- Short distortion wave for EMP
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 2.5,
			noiseScaleSpace = 0.13,
			distanceFalloff = 0.1,
			onlyModelMap = 1,
			lifeTime = 20,
			effectStrength = -1.5,
			startRadius = 0.4,
			rampUp = 5,
			decay = 15,
			shockWidth = 8,
			effectType = 2,
		},
	},

	EMPNoise = { -- Circle area-distortion-effect for EMP
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 0.85,
			noiseScaleSpace = 0.1,
			distanceFalloff = 0.1,
			onlyModelMap = 1,
			startRadius = 0.60,
			shockWidth = 20,
			refractiveIndex = -1.2,
			effectStrength = 0.7,
			windAffected = -0.95,
			riseRate = -0.95,
			lifeTime = 80,
			rampUp = 10,
			decay = 30,
			effectType = 13,
		},
	},
	EMPRipples = { -- Circle area-distortion-effect for EMP
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseStrength = 6.0,
			noiseScaleSpace = 0.38,
			distanceFalloff = 0.1,
			onlyModelMap = -1,
			startRadius = 0.5,
			shockWidth = 1.05,
			refractiveIndex = -1.2,
			effectStrength = 5,
			windAffected = -1,
			riseRate = -1,
			lifeTime = 59,
			rampUp = 19,
			decay = 40,
			effectType = "groundShockwave",
		},
	},

	AirShockWaveEMP = { -- Noised/electric Shockwave ripple on units
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.15,
			noiseStrength = 0.8,
			onlyModelMap = 0,
			lifeTime = 12,
			refractiveIndex = 1.03,
			decay = 4,
			rampUp = 8,
			effectStrength = 1.75,
			shockWidth = -0.30, --needed for airshockwaves
			effectType = "airShockwave",
		},
	},

	JunoShockWave = { -- big distorted shockwave
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 2.5,
			noiseScaleSpace = 0.13,
			distanceFalloff = 0.1,
			onlyModelMap = 1,
			lifeTime = 40,
			effectStrength = -11,
			startRadius = 0.2,
			rampUp = 10,
			decay = 30,
			shockWidth = 14,
			effectType = 2,
		},
	},

	JunoNoise = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 600,
			noiseStrength = 0.45,
			noiseScaleSpace = 1.5,
			distanceFalloff = 0.1,
			onlyModelMap = 1,
			startRadius = 0.90,
			shockWidth = 20,
			refractiveIndex = -1.2,
			effectStrength = 0.7,
			windAffected = -0.5,
			riseRate = 2,
			lifeTime = 675,
			rampUp = 100,
			decay = 500,
			effectType = 13,
		},
	},

	ProjectileDgun = { -- spawned on explosions
		distortionType = "point", -- or cone or beam
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 20,
			noiseScaleSpace = -0.1,
			distanceFalloff = 0.5,
			onlyModelMap = 0,
			windAffected = -1,
			riseRate = 0,
			--magnificationRate = 8.0,
			lifeTime = 75,
			rampUp = 50,
			decay = 25,
			effectType = 0,
		},
	},

	MuzzleFlash = { -- spawned on projectilecreated
		distortionType = "point", -- or cone or beam
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			lifeTime = 6,
			sustain = 0.0035,
			effectType = 0,
		},
	},
}

local SizeRadius = {
	Quaco = 2.5,
	Zetto = 5,
	Atto = 10,
	Banthlaser = 13,
	Femto = 16,
	KorgLaser = 19,
	Pico = 26,
	Nano = 34,
	Micro = 44,
	DGun = 50,
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
	Juno = 450,
	Larger = 500,
	Largest = 650,
	Mega = 800,
	MegaXL = 1000,
	Armnuke = 1280,
	MegaXXL = 1500,
	Cornuke = 1920,
	Giga = 2000,
	Tera = 3500,
	Planetary = 5000,
}

local globalDamageMult = Spring.GetModOptions().multiplier_weapondamage or 1

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
local usedclasses = 0
local function GetDistortionClass(baseClassname, sizekey, additionaloverrides)
	local distortionClassKey = baseClassname .. (sizekey or "")
	if additionaloverrides and type(additionaloverrides) == "table" then
		for k, v in pairs(additionaloverrides) do
			distortionClassKey = distortionClassKey .. "_" .. tostring(k) .. "=" .. tostring(v)
		end
	end

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

local missileDistortionByCeg = {
	missiletrailtiny = {
		radius = 70,
		theta = 0.07,
		noiseStrength = 4.0,
		noiseScaleSpace = 0.85,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 10,
	},
	missiletrailsmall = {
		radius = 75,
		theta = 0.08,
		noiseStrength = 4.0,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 12,
	},
	["missiletrailsmall-simple"] = {
		radius = 75,
		theta = 0.08,
		noiseStrength = 4.0,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 12,
	},
	["missiletrailsmall-red"] = {
		radius = 75,
		theta = 0.08,
		noiseStrength = 4.0,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 12,
	},
	["missiletrailsmall-starburst"] = {
		radius = 75,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 12,
	},
	missiletrailfighter = {
		radius = 75,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 12,
	},
	missiletrailaa = {
		radius = 110,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 16,
	},
	missiletrailmedium = {
		radius = 110,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 16,
	},
	["missiletrailmedium-red"] = {
		radius = 110,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 16,
	},
	["missiletrailmedium-starburst"] = {
		radius = 110,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 16,
	},
	missiletrailviper = {
		radius = 110,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.75,
		distanceFalloff = 1.4,
		effectStrength = 2.5,
		yoffset = 16,
	},
	["missiletraillarge-red"] = {
		radius = 140,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.7,
		distanceFalloff = 1.4,
		effectStrength = 3.3,
		yoffset = 20,
	},
	["missiletrailaa-large"] = {
		radius = 140,
		theta = 0.08,
		noiseStrength = 4.5,
		noiseScaleSpace = 0.7,
		distanceFalloff = 1.4,
		effectStrength = 3.3,
		yoffset = 20,
	},
	missiletrailmship = {
		radius = 140,
		theta = 0.08,
		noiseStrength = 5.0,
		noiseScaleSpace = 0.7,
		distanceFalloff = 1.4,
		effectStrength = 3.3,
		yoffset = 20,
	},
	["missiletrail-juno"] = {
		radius = 140,
		theta = 0.08,
		noiseStrength = 5.0,
		noiseScaleSpace = 0.65,
		distanceFalloff = 1.2,
		effectStrength = 3.3,
		yoffset = 20,
	},
	["cruisemissiletrail-tacnuke"] = {
		radius = 160,
		theta = 0.08,
		noiseStrength = 5.0,
		noiseScaleSpace = 0.65,
		distanceFalloff = 1.2,
		effectStrength = 3.3,
		yoffset = 20,
	},
	["cruisemissiletrail-emp"] = {
		radius = 150,
		theta = 0.08,
		noiseStrength = 5.0,
		noiseScaleSpace = 0.65,
		distanceFalloff = 1.2,
		effectStrength = 3.3,
		yoffset = 20,
	},
	nuketrail = {
		radius = 230,
		theta = 0.08,
		noiseStrength = 5.0,
		noiseScaleSpace = 0.6,
		distanceFalloff = 1.0,
		effectStrength = 3.3,
		yoffset = 20,
	},
}

local function AssignDistortionsToAllWeapons()
	for weaponID = 0, #WeaponDefs do
		local weaponDef = WeaponDefs[weaponID]
		local wcp = weaponDef.customParams
		local damage = 100
		for cat = 0, #weaponDef.damages do
			if Game.armorTypes[cat] and Game.armorTypes[cat] == "default" then
				damage = weaponDef.damages[cat]
				break
			end
		end

		-- Start by collecting some common parameters of the weapon
		damage = (damage / globalDamageMult) + ((damage * (globalDamageMult - 1)) * 0.25)

		local projectileSpeed = weaponDef.weaponVelocity or 10
		local weaponRange = weaponDef.range or 0
		local areaofeffect = weaponDef.damageAreaOfEffect or 0
		--local weaponImpulse = weaponDef.impulseFactor or 0 (doesn't seem to work)
		local radius = ((areaofeffect * 0.7) + (areaofeffect * weaponDef.edgeEffectiveness * 1.1))
		local muzzleflashRadius = radius ^ 0.75 + (weaponRange * 0.015) + (projectileSpeed * 0.045) --for muzzleflashes
		--local effectiveRangeExplo = ((areaofeffect * 1.2) - ((1 - weaponDef.edgeEffectiveness) * areaofeffect * 0.5)) --+ (weaponImpulse * 1000)
		local effectiveRangeExplo = areaofeffect * (0.75 + (0.4 * math.sqrt(weaponDef.edgeEffectiveness)))
		--local effectiveUnitRangeExplo = areaofeffect * 2

		--local radius = (weaponDef.damageAreaOfEffect * weaponDef.edgeEffectiveness * 1.55)

		local muzzleFlash = true -- by default add muzzleflash to weapon being fired
		local explosionDistortion = true -- by default, add explosion distortion to weapon on explosion
		local sizeclass = GetClosestSizeClass(radius)
		local overrideTable = {}
		local antiair = string.find(weaponDef.cegTag, "aa") or false
		local scavenger = string.find(weaponDef.name, "_scav") or false
		local juno = string.find(weaponDef.name, "juno") or false
		--local isBuilding =
		local isUnitExplosion = string.find(weaponDef.name, "explosion") or false
		local isBuildingExplosion = string.find(weaponDef.name, "buildingexplosion") or false

		-- Assign projectileDistortions based on type, and decide weather muzzleflashes or explosiondistortions are needed
		if weaponDef.type == "LaserCannon" and wcp.burntime then
			--projectileDefDistortions[weaponID] = GetDistortionClass("FlameProjectile", "Smallish", overrideTable)

		elseif weaponDef.type == "BeamLaser" then
			muzzleFlash = false

			if string.find(weaponDef.name, "heat") then
				-- Heat rays get their own stronger distortion class
				local heatRadius = (1.5 * (weaponDef.size * weaponDef.size * weaponDef.size)) + (5 * radius)
				sizeclass = GetClosestSizeClass(heatRadius * 0.25)
				projectileDefDistortions[weaponID] = GetDistortionClass("HeatRayHeat", sizeclass, overrideTable)
			end
		elseif weaponDef.type == "LaserCannon" then
			-- take the name in lower-case
			local lname = weaponDef.name:lower()

			-- if it's a machine-gun or rapid-fire, give it NO distortion
			if
				lname:find("mg_weapon")
				or lname:find("legflak")
				or lname:find("machinegun")
				or lname:find("shotgun")
			then
				Spring.Echo("LaserCannon no distortion for " .. weaponDef.name)
				--projectileDefDistortions[weaponID] = GetDistortionClass("NoEffect", sizeclass, overrideTable)

				-- otherwise give it the regular cannon distortion
			else
				local sizeclass = GetClosestSizeClass(radius)
				projectileDefDistortions[weaponID] = GetDistortionClass("CannonProjectile", sizeclass, overrideTable)
			end
		elseif weaponDef.type == "DistortionningCannon" then
			--sizeclass = GetClosestSizeClass(33 + (radius*2.5))
			projectileDefDistortions[weaponID] = GetDistortionClass("LaserProjectile", sizeclass, overrideTable)
		elseif weaponDef.type == "MissileLauncher" then
			local tag = weaponDef.cegTag and weaponDef.cegTag:lower() or ""
			local thrusterOverrides = missileDistortionByCeg[tag]
			if thrusterOverrides then
				--Spring.Echo("[DistortionConfig] MissileLauncher " .. weaponDef.name .. " cegTag=" .. tag .. " radius=" .. thrusterOverrides.radius)
				projectileDefDistortions[weaponID] =
					GetDistortionClass("MissileProjectile", sizeclass, thrusterOverrides)
			else
				projectileDefDistortions[weaponID] = GetDistortionClass("MissileProjectile", sizeclass, overrideTable)
			end
		elseif weaponDef.type == "StarburstLauncher" then
			local tag = weaponDef.cegTag and weaponDef.cegTag:lower() or ""
			local thrusterOverrides = missileDistortionByCeg[tag]
			if thrusterOverrides then
				--Spring.Echo("[DistortionConfig] StarburstLauncher " .. weaponDef.name .. " cegTag=" .. tag .. " radius=" .. thrusterOverrides.radius)
				projectileDefDistortions[weaponID] =
					GetDistortionClass("MissileProjectile", sizeclass, thrusterOverrides)
			else
				projectileDefDistortions[weaponID] = GetDistortionClass("MissileProjectile", sizeclass, overrideTable)
			end
			sizeclass = GetClosestSizeClass(radius)
		elseif weaponDef.type == "Cannon" then
			--muzzleFlash = true
			sizeclass = GetClosestSizeClass(radius)
			--projectileDefDistortions[weaponID] = GetDistortionClass("CannonProjectile", sizeclass, overrideTable)
		elseif weaponDef.type == "DGun" then
			--muzzleFlash = true --doesnt work
			sizeclass = "DGun"

			projectileDefDistortions[weaponID] = GetDistortionClass("AirShockWaveDgun", sizeclass, overrideTable)
			--projectileDefDistortions[weaponID] = GetDistortionClass("CannonProjectile", sizeclass, overrideTable)
			projectileDefDistortions[weaponID].yOffset = 32
		elseif weaponDef.type == "TorpedoLauncher" then
			sizeclass = "Small"
			projectileDefDistortions[weaponID] = GetDistortionClass("TorpedoProjectile", sizeclass, overrideTable)
		elseif weaponDef.type == "Shield" then
			sizeclass = "Large"
			projectileDefDistortions[weaponID] = GetDistortionClass("CannonProjectile", sizeclass, overrideTable)
		elseif weaponDef.type == "AircraftBomb" then
			projectileDefDistortions[weaponID] =
				GetDistortionClass("AirBombProjectile", "Warm", sizeclass, overrideTable)
		end

		-- Add a muzzle flash if needed:
		if muzzleFlash then
			local mymuzzleFlash

			if damage < 100 then
				--Spring.Echo("Skipping muzzle flash for low damage:", damage)
			elseif damage < 275 then
				mymuzzleFlash =
					GetDistortionClass("MuzzleShockWaveXS", GetClosestSizeClass(muzzleflashRadius * 0.7), overrideTable)
				--mymuzzleflash.yOffset = 10 --This does not seem to work
				--mymuzzleflash.distortionConfig.radius = radius * 0.6 --What does this do?
			elseif damage <= 500 then
				mymuzzleFlash =
					GetDistortionClass("MuzzleShockWave", GetClosestSizeClass(muzzleflashRadius), overrideTable)
			else
				mymuzzleFlash =
					GetDistortionClass("MuzzleShockWaveXL", GetClosestSizeClass(muzzleflashRadius * 0.6), overrideTable)
			end
			muzzleFlashDistortions[weaponID] = { mymuzzleFlash } -- note that multiple distortions can be added
		end

		-- Add explosiondistortions if needed:
		if explosionDistortion then
			if weaponDef.type == "DGun" then
			elseif weaponDef.type == "Flame" then
				explosionDistortions[weaponID] =
					{ GetDistortionClass("FireHeat", GetClosestSizeClass(radius), overrideTable) }

				-- elseif weaponDef.type == 'LaserCannon' then -- No shockwaves for lasercannons
				-- 	explosionDistortions[weaponID] = {GetDistortionClass("AirShockWaveMG", GetClosestSizeClass(radius), overrideTable)}
			elseif weaponDef.type == "TorpedoLauncher" then
				explosionDistortions[weaponID] =
					{ GetDistortionClass("TorpedoShockWave", GetClosestSizeClass(radius), overrideTable) }
			elseif weaponDef.type == "BeamLaser" then
				sizeclass = GetClosestSizeClass(radius * 0.15) -- works
				overrideTable = { lifeTime = 2 } -- doesn't work
			elseif weaponDef.type == "DistortionningCannon" then
				sizeclass = GetClosestSizeClass(radius * 1.2)
			else
				if weaponDef.type == "AircraftBomb" then
					if weaponDef.paralyzer then
					else
						explosionDistortions[weaponID] =
							{ GetDistortionClass("AirShockWave", GetClosestSizeClass(radius), overrideTable) }
						explosionDistortions[weaponID] =
							{ GetDistortionClass("GroundShockWave", GetClosestSizeClass(radius), overrideTable) }
						explosionDistortions[weaponID] =
							{ GetDistortionClass("ExplosionHeat", GetClosestSizeClass(radius), overrideTable) }
					end
				end

				-- radius = ((weaponDef.damageAreaOfEffect*1.9) + (weaponDef.damageAreaOfEffect * weaponDef.edgeEffectiveness * 1.35))
				-- if string.find(weaponDef.name, 'juno') then
				-- 	radius = 675
				-- end

				-- UNIT explosions
				if weaponDef.customParams.unitexplosion then
					effectiveRangeExplo = effectiveRangeExplo * 2.1

					if string.find(weaponDef.name, "windboom") then
						effectiveRangeExplo = 40
						--areaofeffect = areaofeffect * 0.5
					end

					if string.find(weaponDef.name, "nanoboom") then
						effectiveRangeExplo = 58
						--areaofeffect = areaofeffect * 0.5
					end

					if string.find(weaponDef.name, "energystorage") then
						effectiveRangeExplo = effectiveRangeExplo * 0.6
					end

					if string.find(weaponDef.name, "geo") then --currently override
						effectiveRangeExplo = 100
					end

					if string.find(weaponDef.name, "building") then
						effectiveRangeExplo = effectiveRangeExplo * 0.5
					end

					if string.find(weaponDef.name, "penetrator") then
						effectiveRangeExplo = effectiveRangeExplo * 0.6
					end

					if string.find(weaponDef.name, "explosiont3") then
						effectiveRangeExplo = effectiveRangeExplo * 1.5
					end

					if effectiveRangeExplo < 24 then
						distortionClass = "UnitExploShockWaveXS"
					elseif effectiveRangeExplo < 48 then
						distortionClass = "UnitExploShockWaveS"
					elseif effectiveRangeExplo < 92 then
						distortionClass = "UnitExploShockWaveM"
					elseif effectiveRangeExplo < 184 then
						distortionClass = "UnitExploShockWaveL"
					else --
						distortionClass = "UnitExploShockWaveXL"
					end
				else -- regular CANNON explosions
					if effectiveRangeExplo < 24 then
						distortionClass = "ExploShockWaveXS"
					elseif effectiveRangeExplo < 48 then
						distortionClass = "ExploShockWaveS"
					elseif effectiveRangeExplo < 92 then
						distortionClass = "ExploShockWaveM"
					elseif effectiveRangeExplo < 184 then
						distortionClass = "ExploShockWaveL"
					else --
						distortionClass = "ExploShockWaveXL"
					end
				end

				if string.find(weaponDef.name, "flak") then
					areaofeffect = 0
				end

				-- Check weapon distortion class assignment (enter weapon name here)
				-- if string.find(weaponDef.name, 'cortruck_missile') then
				-- 	Spring.Echo('-==--===-', weaponDef.customParams.unitexplosion, distortionClass, effectiveRangeExplo, GetClosestSizeClass(effectiveRangeExplo), GetDistortionClass(distortionClass, GetClosestSizeClass(effectiveRangeExplo), overrideTable))
				-- end

				if not weaponDef.customParams.noexplosionlight and areaofeffect > 15 then --need to add noexplosiondistortion to units - now used same as lights
					explosionDistortions[weaponID] =
						{ GetDistortionClass(distortionClass, GetClosestSizeClass(effectiveRangeExplo), overrideTable) }
				end
			end
		end
	end
	Spring.Echo(Spring.GetGameFrame(), "DLGL4 weapons conf using", usedclasses, "distortion types")
end
AssignDistortionsToAllWeapons() -- disable this if it doesn't work

-----------------Manual Overrides--------------------
local explosionDistortionsNames = {}
local muzzleFlashDistortionsNames = {}
local projectileDefDistortionsNames = {}

projectileDefDistortionsNames.hoverarty_ata = GetDistortionClass("TachyonBeam", "Banthlaser")
projectileDefDistortionsNames.turretantiheavy_ata = GetDistortionClass("TachyonBeam", "Banthlaser")
projectileDefDistortionsNames.striderbantha_ata = GetDistortionClass("TachyonBeam", "Banthlaser")


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

-- convert weaponname -> weaponDefID
for name, distortionList in pairs(explosionDistortionsNames) do
	if WeaponDefNames[name] then
		Spring.Echo("ADDED", name)
		Spring.Echo("ADDED", name)
		Spring.Echo("ADDED", name)
		Spring.Echo("ADDED", name)
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
