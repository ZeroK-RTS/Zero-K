return { DOT_Merl_DExplo = {

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
			emitRotSpread = 50,

			sizeGrowth = 0.0,
			sizeMod = 1.0,

			airdrag = 1,
			particleLife = 25,
			particleLifeSpread = 25,
			numParticles = 80,
			particleSpeed = 1,
			particleSpeedSpread = 5,
			particleSize = 0.5,
			particleSizeSpread = 4,

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
			Texture = [[orangesmoke3]],
			colorMap = [[1.0 0.6 0.25 0.80
			             0.4 0.4 0.40 0.90
			             0.0 0.0 0.00 0.01]],

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

	licht = {
		class = [[CSimpleGroundFlash]],
		properties = {
			texture = [[groundflash]],
			size = 50,
			sizeGrowth = [[0 -.25]],
			ttl = 8,
			colorMap = [[1 1 1 1.00
			             0 0 0 0.01]],
		},
		air = false,
		ground = true,
		water = false,
		count = 1,
	},
} }
