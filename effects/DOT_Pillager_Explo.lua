return { DOT_Pillager_Explo = {

	Dreck = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[smokesmall]],
			colorMap = [[.07 .05 .05 0.80
			             .00 .00 .00 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, -0.2, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 70,

			sizeGrowth = 0.0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 25,
			particleLifeSpread = 25,
			numParticles = 80,
			particleSpeed = 1,
			particleSpeedSpread = 5,
			particleSize = 0.5,
			particleSizeSpread = 8,

			directional = false,
			useAirLos = true,
		},
		air = false,
		ground = true,
		water = false,
		count = 1,
	},

	RauchWirbel = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[dirt]],
			colorMap = [[1 0.8 0.40 0.30
			             1 0.4 0.15 0.30
			             0 0.0 0.00 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0.005, 0.001, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = [[90 r90]],

			sizeGrowth = [[0.5 r.5]],
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 12,
			particleLifeSpread = 32,
			numParticles = 40,
			particleSpeed = 0.5,
			particleSpeedSpread = 2,
			particleSize = 0.5,
			particleSizeSpread = 1,

			directional = false,
			useAirLos = true,
		},
		air = false,
		ground = true,
		water = false,
		count = 1,
	},

	boom = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[bigexplo]],
			colorMap = [[1 0.5 0.3 0.01
			             0 0.0 0.0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, 0.01, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 90,

			sizeGrowth = [[0.75 r.75]],
			sizeMod = 1.0,

			airdrag = 0.95,
			particleLife = 8,
			particleLifeSpread = 32,
			numParticles = 32,
			particleSpeed = 0.5,
			particleSpeedSpread = 3,
			particleSize = 0.5,
			particleSizeSpread = 1,

			directional = false,
			useAirLos = true,
		},
		air = true,
		ground = true,
		water = false,
		count = 1,
	},

	Explo2 = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[gunshot]],
			colorMap = [[1 0.900 0.3 0.005
			             1 0.875 0.2 0.005
			             0 0.000 0.0 0.010]],

			pos = [[0, 1, 0]],
			gravity = [[0, 0, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 360,

			sizeGrowth = 0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 8,
			particleLifeSpread = 12,
			numParticles = 70,
			particleSpeed = 8,
			particleSpeedSpread = 6,
			particleSize = 1,
			particleSizeSpread = 3,

			directional = true,
			useAirLos = true,
		},
		air = true,
		ground = true,
		water = false,
		count = 1,
	},

	licht = {
		class = [[CSimpleGroundFlash]],
		properties = {
			texture = [[groundflash]],
			size = 70,
			sizeGrowth = [[0 -.25]],
			ttl = 12,
			colorMap = [[1 1 1 1.00
			             0 0 0 0.01]],
		},
		air = false,
		ground = true,
		water = false,
		count = 1,
	},

	Wasserding = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[smokesmall]],
			colorMap = [[1 1 1 0.80
			             0 0 0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, -0.2, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = [[7 r14]],

			sizeGrowth = 0.0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 25,
			particleLifeSpread = 25,
			numParticles = 80,
			particleSpeed = 0.5,
			particleSpeedSpread = [[5 r2]],
			particleSize = 1,
			particleSizeSpread = 3,

			directional = false,
			useAirLos = true,
		},
		air = false,
		ground = false,
		water = true,
		underwater = true,
		count = 1,
	},

	WasserWirbel2 = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[dirtplosion2]],
			colorMap = [[1 1 1 0.10
			             0 0 0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, 0, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = [[5 r40]],

			sizeGrowth = [[0.5 r.7]],
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 16,
			particleLifeSpread = 8,
			numParticles = 20,
			particleSpeed = 1,
			particleSpeedSpread = 4,
			particleSize = 3,
			particleSizeSpread = 12,

			directional = true,
			useAirLos = true,
		},
		air = false,
		ground = false,
		water = true,
		underwater = true,
		count = 2,
	},

	WasserWirbel = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[smokesmall]],
			colorMap = [[0 0 0 0.00
			             1 1 1 0.80
			             0 0 0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, 0, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = [[15 r40]],

			sizeGrowth = [[0.5 r.3]],
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 40,
			particleLifeSpread = 20,
			numParticles = 30,
			particleSpeed = 0.2,
			particleSpeedSpread = 3,
			particleSize = 0.02,
			particleSizeSpread = 0,

			directional = true,
			useAirLos = true,
		},
		air = false,
		ground = false,
		water = true,
		underwater = true,
		count = 1,
	},
} }
