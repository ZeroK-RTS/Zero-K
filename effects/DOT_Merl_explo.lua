return { DOT_Merl_Explo = {

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
			emitRotSpread = [[5 r20]],

			sizeGrowth = 0.0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 25,
			particleLifeSpread = 25,
			numParticles = 80,
			particleSpeed = 1,
			particleSpeedSpread = 5,
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

	Rauchwirbel = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[smokesmall]],
			colorMap = [[1.0 1.0 1.0 0.80
			             0.6 0.6 0.6 0.80
			             0.0 0.0 0.0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0.005, 0.001, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 90,

			sizeGrowth = [[0.5 r.5]],
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 12,
			particleLifeSpread = 32,
			numParticles = 12,
			particleSpeed = 0.5,
			particleSpeedSpread = 0.65,
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

	licht = {
		class = [[CSimpleGroundFlash]],
		properties = {
			texture = [[groundflash]],
			size = 30,
			sizeGrowth = 0,
			ttl = 8,
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
			emitRotSpread = [[5 r20]],

			sizeGrowth = 0.0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 25,
			particleLifeSpread = 25,
			numParticles = 80,
			particleSpeed = 1,
			particleSpeedSpread = 5,
			particleSize = 0.5,
			particleSizeSpread = 1,

			directional = false,
			useAirLos = true,
		},
		air = false,
		ground = false,
		water = true,
		underwater = true,
		count = 1,
	},

	WasserWirbel = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[smokesmall]],
			colorMap = [[1 1 1 0.80
			             0 0 0 0.01]],

			pos = [[0, 1, 0]],
			gravity = [[0, 0.001, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 40,

			sizeGrowth = [[0.5 r.5]],
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 12,
			particleLifeSpread = 32,
			numParticles = 24,
			particleSpeed = 0.5,
			particleSpeedSpread = 0.65,
			particleSize = 0.5,
			particleSizeSpread = 1,

			directional = false,
			useAirLos = true,
		},
		air = false,
		ground = false,
		water = true,
		underwater = true,
		count = 1,
	},

	Explo = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[redexplo]],
			colorMap = [[1 0.65 0.3 0.005
			             0 0.00 0.0 0.010]],

			pos = [[0, 1, 0]],
			gravity = [[0, -0.5, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 360,

			sizeGrowth = 0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 8,
			particleLifeSpread = 12,
			numParticles = 30,
			particleSpeed = 5,
			particleSpeedSpread = 3,
			particleSize = 0.5,
			particleSizeSpread = 6,

			directional = false,
			useAirLos = true,
		},
		air = true,
		ground = false,
		water = false,
		count = 1,
	},

	Explo2 = {
		class = [[CSimpleParticleSystem]],
		properties = {
			Texture = [[gunshot]],
			colorMap = [[1 0.65 0.3 0.005
			             1 0.40 0.2 0.005
			             0 0.00 0.0 0.010]],

			pos = [[0, 1, 0]],
			gravity = [[0, -1, 0]],
			emitVector = [[0, 1, 0]],
			emitRot = 0,
			emitRotSpread = 360,

			sizeGrowth = 0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 8,
			particleLifeSpread = 16,
			numParticles = 20,
			particleSpeed = 14,
			particleSpeedSpread = 3,
			particleSize = 8,
			particleSizeSpread = 6,

			directional = true,
			useAirLos = true,
		},
		air = true,
		ground = false,
		water = false,
		count = 1,
	},
}}
