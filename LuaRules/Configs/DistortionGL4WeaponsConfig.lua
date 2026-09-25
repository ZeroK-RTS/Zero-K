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
	distortionType = "point",
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
		distortionType = "point",
		alwaysVisible = false,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			distanceFalloff = 0.1,
			noiseStrength = 0.55,
			noiseScaleSpace = 0.8,
			distanceFalloff = 0.3,
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
		distortionType = "point",
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
		distortionType = "point",
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
	GroundShockWaveLanding = {
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			effectStrength = 1.6,
			distanceFalloff = 0.85,
			noiseStrength = 0.7,
			noiseScaleSpace = 0.7,
			lifeTime = 18,
			decay = 12,
			rampUp = 5,
			onlyModelMap = 1,
			shockWidth = 1.3,
			refractiveIndex = -1.2,
			startRadius = 0.2,
			effectType = "groundShockwave",
		},
	},

	ExploShockWaveXS = {
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.1,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 5,
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
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 6,
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
		distortionType = "point",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			noiseScaleSpace = 0.3,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 7,
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
			noiseScaleSpace = 0.38,
			distanceFalloff = 0.25,
			onlyModelMap = 1,
			startRadius = 0.60,
			shockWidth = 20,
			refractiveIndex = -1.2,
			windAffected = -2.95,
			riseRate = -2,
			lifeTime = 30,
			rampUp = 5,
			decay = 15,
			effectType = 0,
		},
	},
	empWobbleLong = {
		distortionType = "point",
		yOffset = 0,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 200,
			effectStrength = 0.25,
			noiseStrength = 0.95,
			noiseScaleSpace = 0.11,
			distanceFalloff = 0.25,
			onlyModelMap = 1,
			startRadius = 0.60,
			shockWidth = 20,
			refractiveIndex = -1.34,
			windAffected = -1.8,
			riseRate = -2,
			lifeTime = 200,
			rampUp = 5,
			decay = 120,
			effectType = 0,
		},
	},
	
	ExplosionHeat = { -- spawned on explosions
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 1.2,
			noiseScaleSpace = 0.12,
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
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
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.6,
			noiseStrength = 1,
			noiseScaleSpace = 0.52,
			distanceFalloff = 0.5,
			startRadius = 0.55,
			onlyModelMap = 0,
			lifeTime = 50,
			rampUp = 2,
			riseRate = 0.5,
			decay = 10,
			effectType = 0,
		},
	},
	ImplosionBomb = { 
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.2,
			noiseStrength = 0.2,
			onlyModelMap = 0,
			lifeTime = 14,
			distanceFalloff = 0.95,
			refractiveIndex = 1.3,
			decay = 6,
			rampUp = 5,
			effectStrength = -1.4,
			startRadius = 0.2,
			shockWidth = 0.9,
			effectType = "airShockwave",
		},
	},
	ImplosionSingu = { 
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.4,
			noiseStrength = 0.1,
			onlyModelMap = 0,
			distanceFalloff = 0.98,
			refractiveIndex = 1.5,
			lifeTime = 62,
			decay = 24,
			rampUp = 6,
			effectStrength = -1,
			startRadius = 0.9,
			shockWidth = -0.92,
			effectType = "airShockwave",
		},
	},
	TeleportOut = {
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.8,
			noiseStrength = 1.2,
			onlyModelMap = 0,
			lifeTime = 23,
			distanceFalloff = 0.95,
			refractiveIndex = 1.045,
			decay = 2,
			rampUp = 3,
			effectStrength = -0.25,
			startRadius = 0.6,
			shockWidth = -0.7,
			effectType = "airShockwave",
		},
	},
	TeleportIn = {
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.8,
			noiseStrength = 1.2,
			onlyModelMap = 0,
			lifeTime = 23,
			distanceFalloff = 0.95,
			refractiveIndex = 1.045,
			decay = 2,
			rampUp = 3,
			effectStrength = 0.5,
			startRadius = 0.6,
			shockWidth = -0.7,
			effectType = "airShockwave",
		},
	},
	SlowDamageImplosion = { 
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 150,
			noiseScaleSpace = 0.8,
			noiseStrength = 1.2,
			onlyModelMap = 0,
			lifeTime = 11,
			distanceFalloff = 0.8,
			refractiveIndex = 1.045,
			decay = 2,
			rampUp = 3,
			effectStrength = -0.25,
			startRadius = 0.6,
			shockWidth = 0.8,
			effectType = "airShockwave",
		},
	},
	DgunImplosion = { 
		distortionType = "point",
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
		distortionType = "point",
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
	GaussProjectile = { 
		distortionType = "beam",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			pos2x = 0,
			pos2y = -50,
			pos2z = 0,
			effectStrength = 1,
			noiseStrength = 1,
			noiseScaleSpace = 0.8,
			onlyModelMap = 0,
			lifeTime = 18,
			distanceFalloff = 0.9,
			refractiveIndex = 1.2,
			windAffected = -1,
			decay = 18,
			rampUp = 4,
			sustain = 18,
			startRadius = 0.7,
			shockWidth = 0,
			effectType = 0,
		},
	},
	FlameProjectile = { 
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			effectStrength = 1.2,
			noiseStrength = 1,
			noiseScaleSpace = 1.3,
			onlyModelMap = 0,
			lifeTime = 8,
			distanceFalloff = 1,
			refractiveIndex = 1.06,
			decay = 2,
			rampUp = 0,
			sustain = 4,
			riseRate = 0.2,
			startRadius = 0.2,
			shockWidth = 0,
			effectType = 0,
		},
	},
	SlowBeam = {
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.18,
			noiseScaleSpace = 0.24,
			onlyModelMap = 0,
			riseRate = -0.1,
			distanceFalloff = 0.5,
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
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.4,
			noiseScaleSpace = 0.03,
			onlyModelMap = 0,
			riseRate = -0.1,
			distanceFalloff = 0.5,
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
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.2,
			noiseStrength = 1.1,
			noiseScaleSpace = 0.35,
			distanceFalloff = 0.5,
			onlyModelMap = 0,
			riseRate = -3.4,
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
	ParticleBeam = {
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.2,
			noiseStrength = 1.7,
			noiseScaleSpace = 0.32,
			onlyModelMap = 0,
			riseRate = -7.8,
			distanceFalloff = 0.5,
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
	LightningBeam = {
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.1,
			noiseStrength = 3.5,
			noiseScaleSpace = 0.15,
			onlyModelMap = 0,
			riseRate = -3.4,
			windAffected = 12.57,
			distanceFalloff = 0.7,
			refractiveIndex = 3,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 16,
			sustain = 5,
			rampUp = 1,
			decay = 2,
			effectType = 7,
		},
	},
	HeavyLaser = {
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.35,
			noiseScaleSpace = 0.1,
			onlyModelMap = 0,
			riseRate = -5,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 4,
			sustain = 1,
			windAffected = 1,
			rampUp = 0,
			decay = 3,
			effectType = 7,
		},
	},
	MediumLaser = {
		distortionType = "beam",
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.3,
			noiseScaleSpace = 0.09,
			onlyModelMap = 0,
			riseRate = -4,
			pos2x = 100,
			pos2y = 500,
			pos2z = 100, -- beam distortions only, specifies the endpoint of the beam
			lifeTime = 4,
			sustain = 1,
			windAffected = 0.9,
			rampUp = 0,
			decay = 3,
			effectType = 7,
		},
	},
	ExplosionHeatFirewalker = { -- spawned on explosions
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			noiseStrength = 0.85,
			noiseScaleSpace = 0.6,
			distanceFalloff = 0.5,
			startRadius = 0.3,
			onlyModelMap = 0,
			lifeTime = 300, -- Standard 10 seconds, multiplied by other effects
			rampUp = 30,
			riseRate = 0.9,
			windAffected = -0.5,
			decay = 260,
			effectType = 0,
		},
	},
	ExplosionHeatLong = { -- spawned on explosions
		distortionType = "point",
		yOffset = 0, -- Y offsets are only ever used for explosions!
		alwaysVisible = true,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 1.1,
			noiseStrength = 1.1,
			noiseScaleSpace = 0.65,
			distanceFalloff = 0.5,
			startRadius = 0.8,
			onlyModelMap = 0,
			lifeTime = 1350,
			rampUp = 30,
			decay = 600,
			effectType = 0,
		},
	},
	ThermiteHeat = { 
		distortionType = "point",
		yOffset = 20,
		distortionConfig = {
			posx = 0,
			posy = 0,
			posz = 0,
			radius = 10,
			effectStrength = 0.4,
			noiseStrength = 0.8,
			noiseScaleSpace = 0.6,
			distanceFalloff = 0.7,
			startRadius = 0.3,
			onlyModelMap = 0,
			riseRate = 0.8,
			lifeTime = 2,
			rampUp = 0,
			decay = 0,
			effectType = 0,
		},
	},
}

local SizeRadius = {
	Quaco = 8,
	Zetto = 10,
	Atto = 11,
	Banthlaser = 13,
	Femtoest = 19,
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
	SmallMedium = 180,
	Medium = 215,
	Mediumish = 235,
	Mediumer = 260,
	Mediumest = 285,
	MediumLarge = 320,
	Large = 400,
	Juno = 450,
	Larger = 500,
	Largest = 650,
	Mega = 760,
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
local marks = {}
local function MarkUnits(class, size)
	if not currentWeaponDefID then
		return
	end
	local wd = WeaponDefs[currentWeaponDefID]
	Spring.Echo(wd.name, class, size)
	local name = wd.name
	local data = name:split("_")
	local ud = data and data[1] and UnitDefNames[data[1]]
	if not ud then
		return
	end
	local units = Spring.GetTeamUnitsSorted(0)
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
	marks[unitID] = (marks[unitID] or 0) + 1
	local x, y, z = Spring.GetUnitPosition(unitID)
	Spring.MarkerAddPoint(x, y, z + 30 * (marks[unitID] - 1), class .. ", " .. (size or "???"))
end


local usedclasses = 0
local function GetDistortionClass(baseClassname, sizekey, strength, lifeScale)
	strength = strength or 1
	lifeScale = lifeScale or 1
	local distortionClassKey = baseClassname .. (sizekey or "") .. "_" .. (strength) .. "_" .. (lifeScale)
	if DEBUG_MODE then
		MarkUnits(baseClassname, sizekey)
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
		distortionConfig.effectStrength = (distortionConfig.effectStrength or 1) * strength
		distortionConfig.lifeTime = (distortionConfig.lifeTime or 1) * lifeScale
		if sizekey and SizeRadius[sizekey] then
			distortionConfig.radius = SizeRadius[sizekey]
		else
			print("Warning: sizekey or SizeRadius[sizekey] is nil!")
		end
	end
	return distortionClasses[distortionClassKey]
end

--------------------------------------------------------------------------------

local gibDistortion = {
	distortionType = "point",
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
local aaDamageCat, defaultDamageCat, shieldDamageCat = GetDamageCatIds()

local function IsWeaponAA(weaponDef)
	local aaDamage = weaponDef.damages[aaDamageCat]
	local defaultDamage = weaponDef.damages[defaultDamageCat]
	if not (aaDamage and defaultDamage) then
		return false
	end
	return (defaultDamage < aaDamage*0.11) and (defaultDamage > aaDamage*0.09)
end

local function AssignWeaponDistortions(weaponID)
	currentWeaponDefID = DEBUG_MODE and weaponID
	local weaponDef = WeaponDefs[weaponID]
	local weaponName = weaponDef.name
	if string.find(weaponName, "bogus") or string.find(weaponName, "fake") or weaponName == "noweapon" then
		return
	end
	local wcp = weaponDef.customParams
	local isAA = IsWeaponAA(weaponDef)
	local damage = weaponDef.damages[(isAA and aaDamageCat) or defaultDamageCat]
	if weaponDef.damages[shieldDamageCat] then
		damage = math.max(damage, weaponDef.damages[shieldDamageCat])
	end
	local isStunOrDisarm = wcp.disarmdamagemult or wcp.emp_paratime
	local stunTime = wcp.emp_paratime and tonumber(wcp.emp_paratime) or wcp.disarmtimer and tonumber(wcp.disarmtimer)

	-- Start by collecting some common parameters of the weapon
	local projectileSpeed = weaponDef.weaponVelocity or 10
	local weaponRange = weaponDef.range or 0
	local areaofeffect = weaponDef.damageAreaOfEffect or 0
	local radius = ((areaofeffect * 0.7) + (areaofeffect * weaponDef.edgeEffectiveness * 1.1))
	local effectiveRangeExplo = areaofeffect * (0.75 + (0.4 * math.sqrt(weaponDef.edgeEffectiveness)))
	local burstMult = tonumber(wcp.statsprojectiles) or ((tonumber(wcp.script_burst) or weaponDef.salvoSize) * weaponDef.projectiles)
	local rapidFire = weaponDef.reload < 0.6 or (weaponDef.reload < 8 and burstMult > 5)
	local particleBeam = string.find(weaponName, "particlebeam")

	local sizeclass = GetClosestSizeClass(radius)
	local overrideTable = {}
	local noExplodeEffect = false

	-- Assign projectileDistortions based on type, and decide weather muzzleflashes or explosiondistortions are needed
	if wcp.lups_noshockwave then
	elseif particleBeam then
		local lightningWidth = "Quaco"
		projectileDefDistortionsNames[weaponName] = GetDistortionClass("ParticleBeam", lightningWidth, 0.5)
	elseif wcp.single_hit_multi or wcp.single_hit then -- Gauss
		projectileDefDistortionsNames[weaponName] = GetDistortionClass("GaussProjectile", "Pico")
	elseif wcp.setunitsonfire and weaponDef.type == "LaserCannon" then -- Flamethrower
		projectileDefDistortionsNames[weaponName] = GetDistortionClass("FlameProjectile", "Smaller")
	elseif weaponDef.type == "LightningCannon" then
		local lightningWidth = (weaponRange > 200 or stunTime > 5) and "Banthlaser" or "Quaco"
		projectileDefDistortionsNames[weaponName] = GetDistortionClass("LightningBeam", lightningWidth)
	elseif weaponDef.type == "BeamLaser" then
		if wcp.timeslow_damagefactor or wcp.timeslow_onlyslow then
			noExplodeEffect = true
			if damage < 20 then -- Weapon contains real damage by this point, so this catches onlyslow too.
				projectileDefDistortionsNames[weaponName] = GetDistortionClass("SlowBeam", "Atto")
			else
				local size = weaponRange > 250 and "Atto" or "Quaco"
				projectileDefDistortionsNames[weaponName] = GetDistortionClass("DisruptorBeam", size)
			end
		elseif damage > 2500 then
			projectileDefDistortionsNames[weaponName] = GetDistortionClass("HeavyLaser", "Banthlaser")
		elseif damage > 700 then
			projectileDefDistortionsNames[weaponName] = GetDistortionClass("MediumLaser", "Zetto")
		end
	elseif weaponDef.type == "DGun" then
		sizeclass = "DGun"
		projectileDefDistortionsNames[weaponName] = GetDistortionClass("DgunProjectile", "Micro")
	end

	-- Add a muzzle flash if needed:
	if wcp.lups_noshockwave or wcp.no_muzzleshock or isStunOrDisarm then
	elseif areaofeffect > 45 and damage > 500 and weaponDef.type == "Cannon" then
		local size = weaponRange > 2500 and "Tiniest" or "Femtoest"
		local class = weaponRange > 2500 and "MuzzleShockWaveXL" or "MuzzleShockWave"
		muzzleFlashDistortionsNames[weaponName] = {
			GetDistortionClass(class, size),
		}
	end
	
	-- Add explosion distortions if needed:
	if wcp.lups_noshockwave then
	elseif (wcp.timeslow_damagefactor or wcp.timeslow_onlyslow) and wcp.nofriendlyfire then
		explosionDistortionsNames[weaponName] = {
			GetDistortionClass("DisruptionPulse", GetClosestSizeClass(effectiveRangeExplo)),
		}
	elseif weaponDef.type == "TorpedoLauncher" then
		explosionDistortionsNames[weaponName] = {
			GetDistortionClass("TorpedoShockWave", GetClosestSizeClass(radius)),
		}
	elseif (wcp.timeslow_damagefactor or wcp.timeslow_onlyslow) and not noExplodeEffect then
		explosionDistortionsNames[weaponName] = {
			GetDistortionClass("SlowDamageImplosion", GetClosestSizeClass(math.max(25, effectiveRangeExplo)*1.2)),
		}
	elseif weaponDef.type == "DGun" then
		explosionDistortionsNames[weaponName] = {
			GetDistortionClass("DgunImplosion", "Micro"),
		}
	elseif weaponDef.type == "AircraftBomb" then -- Only Phoenix
		explosionDistortionsNames[weaponName] = {
			GetDistortionClass("FireExplosionHeat", "SmallMedium"),
		}
	else
		local distortionClass
		if effectiveRangeExplo > 600 then
			distortionClass = "AirShockWaveNuke"
		elseif effectiveRangeExplo > 184 then
			distortionClass = "ExploShockWaveXL"
		elseif effectiveRangeExplo > 92 then
			distortionClass = "ExploShockWaveL"
		elseif effectiveRangeExplo > 60 then
			distortionClass = "ExploShockWaveM"
		elseif effectiveRangeExplo > 24 or wcp.death_explosion then
			distortionClass = "ExploShockWaveS"
		elseif effectiveRangeExplo > 10 or ((weaponDef.type == "Cannon" or weaponDef.type == "MissileLauncher") and weaponRange > 100) or particleBeam then
			distortionClass = "ExploShockWaveXS"
		end

		if distortionClass then
			local adjRadius = math.max(36, effectiveRangeExplo + 8)
			--MarkUnits(adjRadius,"")
			local strength = 1
			if isAA then
				adjRadius = adjRadius*0.7
				strength = 0.9
			end
			if rapidFire then
				adjRadius = adjRadius*0.8
				strength = 0.4
			end
			if weaponRange > 2200 and weaponDef.type == "StarburstLauncher" then
				adjRadius = adjRadius*1.7
			elseif wcp.death_explosion and damage > 1000 then
				adjRadius = adjRadius*1.5
			end
			local distorts = {
				GetDistortionClass(distortionClass, GetClosestSizeClass(adjRadius), strength)
			}
			if isStunOrDisarm then
				local empClass = ((stunTime or 0) > 8 and burstMult < 10 and "empWobbleLong") or "empWobble"
				local empSize = adjRadius * ((stunTime or 0) > 8 and 1 or 1.2)
				distorts[#distorts + 1] = GetDistortionClass(empClass, GetClosestSizeClass(empSize), strength)
			end
			explosionDistortionsNames[weaponName] = distorts
		end
	end
end

local function AssignDistortionsToAllWeapons()
	for weaponID = 0, #WeaponDefs do
		AssignWeaponDistortions(weaponID)
	end
	Spring.Echo(Spring.GetGameFrame(), "DLGL4 weapons conf using", usedclasses, "distortion types")
end
AssignDistortionsToAllWeapons() -- disable this if it doesn't work

-----------------Manual Overrides--------------------

-- Unique weapons
projectileDefDistortionsNames.jumpblackhole_black_hole = GetDistortionClass("BlackHole", "Micro")

explosionDistortionsNames.jumpblackhole_black_hole = {}
explosionDistortionsNames.jumpblackhole_black_hole[#explosionDistortionsNames.jumpblackhole_black_hole + 1] = GetDistortionClass("BlackHole", "Small")

projectileDefDistortionsNames.shieldfelon_shieldgun = GetDistortionClass("ShieldGunBeam", "Atto")

explosionDistortionsNames.shieldscout_clogger_explode = {}
explosionDistortionsNames.shieldscout_clogger_explode[#explosionDistortionsNames.shieldscout_clogger_explode + 1] = GetDistortionClass("ExploShockWaveS", "Pico")

explosionDistortionsNames.bomberassault_thermite_bomb = {
	GetDistortionClass("ThermiteHeat", "Pico")
}
explosionDistortionsNames.energysingu_singularity = {
	GetDistortionClass("ImplosionSingu", "Mega")
}
explosionDistortionsNames.bomberheavy_arm_pidr = {
	GetDistortionClass("ImplosionBomb", "Medium")
}

-- Ground fire needs special attention
explosionDistortionsNames.shieldbomb_shieldbomb_death = explosionDistortionsNames.shieldbomb_shieldbomb_death or {}
explosionDistortionsNames.shieldbomb_shieldbomb_death[#explosionDistortionsNames.shieldbomb_shieldbomb_death + 1] = GetDistortionClass("ExplosionHeat", "Medium")

explosionDistortionsNames.gunshipbomb_gunshipbomb_bomb = explosionDistortionsNames.gunshipbomb_gunshipbomb_bomb or {}
explosionDistortionsNames.gunshipbomb_gunshipbomb_bomb[#explosionDistortionsNames.gunshipbomb_gunshipbomb_bomb + 1] = GetDistortionClass("FireExplosionHeat", "Small")

explosionDistortionsNames.tankraid_napalm_bomblet = explosionDistortionsNames.tankraid_napalm_bomblet or {}
explosionDistortionsNames.tankraid_napalm_bomblet[#explosionDistortionsNames.tankraid_napalm_bomblet + 1] = GetDistortionClass("FireExplosionHeat", "Tiny")

explosionDistortionsNames.jumpraid_pyro_death = explosionDistortionsNames.jumpraid_pyro_death or {}
explosionDistortionsNames.jumpraid_pyro_death[#explosionDistortionsNames.jumpraid_pyro_death + 1] = GetDistortionClass("ExplosionHeatFirewalker", "Smallish", false, 1.3)

explosionDistortionsNames.jumparty_napalm_sprayer = {
	GetDistortionClass("ExplosionHeatFirewalker", "Small", false, 1.5),
}
explosionDistortionsNames.striderdante_napalm_rockets = {
	GetDistortionClass("FireExplosionHeat", "Smaller", false, 1.8),
}
explosionDistortionsNames.striderdante_napalm_rockets_salvo = {
	GetDistortionClass("FireExplosionHeat", "Smaller", false, 1.8),
}
explosionDistortionsNames.napalmmissile_weapon = {
	GetDistortionClass("ExplosionHeatLong", "Juno"),
}

-- Fancy explosions for huge artillery
explosionDistortionsNames.spidercrabe_arm_crabe_gauss = explosionDistortionsNames.spidercrabe_arm_crabe_gauss or {}
explosionDistortionsNames.spidercrabe_arm_crabe_gauss[#explosionDistortionsNames.spidercrabe_arm_crabe_gauss + 1] = GetDistortionClass("GroundShockWave", "Small")

explosionDistortionsNames.turretheavy_plasma = explosionDistortionsNames.turretheavy_plasma or {}
explosionDistortionsNames.turretheavy_plasma[#explosionDistortionsNames.turretheavy_plasma + 1] = GetDistortionClass("GroundShockWave", "Small")

explosionDistortionsNames.staticheavyarty_plasma = explosionDistortionsNames.staticheavyarty_plasma or {}
explosionDistortionsNames.staticheavyarty_plasma[#explosionDistortionsNames.staticheavyarty_plasma + 1] = GetDistortionClass("GroundShockWave", "Small")

explosionDistortionsNames.staticarty_plasma = explosionDistortionsNames.staticarty_plasma or {}
explosionDistortionsNames.staticarty_plasma[#explosionDistortionsNames.staticarty_plasma + 1] = GetDistortionClass("GroundShockWave", "Small")

-- Rescale some normal explosions that autodetect incorrectly
explosionDistortionsNames.jumpbomb_jumpbomb_death = {
	GetDistortionClass("ExploShockWaveL", "SmallMedium")
}
explosionDistortionsNames.tankriot_tawf_banisher = {
	GetDistortionClass("ExploShockWaveS", "Smallest")
}
explosionDistortionsNames.bomberprec_bombsabot = {
	GetDistortionClass("ExploShockWaveS", "Micro")
}
explosionDistortionsNames.shieldskirm_storm_rocket = {
	GetDistortionClass("ExploShockWaveS", "Micro", 0.8)
}
explosionDistortionsNames.spideremp_spider = {
	GetDistortionClass("ExploShockWaveS", "Smallest", 0.22),
	GetDistortionClass("empWobble", "Smallest"),
}

-- Precision weapons that deserve large distortions
explosionDistortionsNames.tankheavyassault_cor_gol = {
	GetDistortionClass("ExploShockWaveM", "Tiny", 1.8)
}
explosionDistortionsNames.cloaksnipe_shockrifle = {
	GetDistortionClass("ExploShockWaveM", "Tiny")
}
explosionDistortionsNames.vehheavyarty_cortruck_missile = {
	GetDistortionClass("ExploShockWaveS", "Nano")
}
explosionDistortionsNames.spiderantiheavy_spy = explosionDistortionsNames.spiderantiheavy_spy or {}
explosionDistortionsNames.spiderantiheavy_spy[#explosionDistortionsNames.spiderantiheavy_spy + 1] = GetDistortionClass("ExploShockWaveS", "Tiniest")

-- Goomba stomp
explosionDistortionsNames.jumpsumo_landing = {
	GetDistortionClass("GroundShockWaveLanding", "SmallMedium")
}
explosionDistortionsNames.striderdetriment_landing = {
	GetDistortionClass("GroundShockWaveLanding", "Mediumer", 1.8)
}

-- Slow pulses all need timing to match their CEG

explosionDistortionsNames.missileslow_weapon = {
	GetDistortionClass("SlowDamageImplosion", "Tiniest", 2, 2),
	GetDistortionClass("DisruptionPulse", "Large", 2),
}
explosionDistortionsNames.amphbomb_amphbomb_death = {
	GetDistortionClass("DisruptionPulse", "Mediumest", 1.4, 0.92),
}
explosionDistortionsNames.commweapon_disruptorbomb = {
	GetDistortionClass("DisruptionPulse", "Mediumest", 1.7, 1.8),
}

-- Disco Rave Party
explosionDistortionsNames.raveparty_red_killer = {
	GetDistortionClass("ExploShockWaveL", "Medium"),
}
explosionDistortionsNames.raveparty_orange_roaster = {
	GetDistortionClass("ExplosionHeatFirewalker", "Mega", false, 0.8),
}
explosionDistortionsNames.raveparty_green_stamper = {
	GetDistortionClass("ExploShockWaveXL", "Larger"),
}
explosionDistortionsNames.raveparty_blue_shocker = {
	GetDistortionClass("ExploShockWaveL", "Mediumer"),
	GetDistortionClass("empWobbleLong", "Mediumer"),
}
explosionDistortionsNames.raveparty_violet_slugger = {
	GetDistortionClass("DisruptionPulse", "Juno", 2, 3.4),
}

-- BIG NUKE
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
-- Generic event distortions

explosionDistortions.teleport_out = {
	GetDistortionClass("TeleportOut", "Smallest")
}
explosionDistortions.teleport_in = {
	GetDistortionClass("TeleportIn", "Smallest")
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Projectile Collection

return {
	muzzleFlashDistortions = muzzleFlashDistortions,
	projectileDefDistortions = projectileDefDistortions,
	explosionDistortions = explosionDistortions,
	gibDistortion = gibDistortion,
}
