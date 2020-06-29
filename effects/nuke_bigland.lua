
return {
	["nukebigland"] = {
		--This is the Nuke - it consists of a Ground Explosion going up
		--a Shockwave going outwards
		--a Smokepillar forming and slowly disspipating
		-- 1 Seconds Explosion
		-- 2 Seconds Arrival of Shockwave- Formation of Explodecloud
		-- 5 Seconds Shockwave at 1,5 km - after this has ended the nuke is fully developed
		-- 20 Seconds total

		-- Nuke Explosion ===================================================================================
		groundflash = {
			alwaysvisible = true,
			circlealpha = 1,
			circlegrowth = 4,
			flashalpha = 4.2,
			flashsize = 322,
			ttl = 150,
			water = true,
			ground = true,
			air = true,
			color = {0.9, 0.2, 0 },
		},
		explosionspike = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 1,
			ground = true,
			properties = {
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[1.0 1.0 1.0 0.04	0.9 0.5 0.2 0.01	0.8 0.1 0.1 0.01]],
				directional = true,
				emitrot = 45,
				emitrotspread = 32,
				emitvector = [[0, 1, 0]],
				gravity = [[0, -0.05, 0]],
				numparticles = 8,
				particlelife = 10,
				particlelifespread = 5,
				particlesize = 20,
				particlesizespread = 0,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0, 2, 0]],
				sizegrowth = 5,
				sizemod = 1.0,
				texture = [[flashside1]],
				useairlos = false,
			},
		},
		explosionsfx = {
			air = true,
			class = [[heatcloud]],
			count = 2,
			ground = true,
			water = true,
			properties = {
				alwaysvisible = true,
				heat = 10,
				emitvector = [[0, 1, 0]],
				heatfalloff = 0.1,
				maxheat = 15,
				pos = [[r-2 r2, 5, r-2 r2]],
				size = 1,
				sizegrowth = 9,
				speed = [[0, 1 0, 0]],
				texture = [[uglynovaexplo]],
			},
		},
		glowingrad = {
			air = true,
			class = [[heatcloud]],
			count = 1,
			ground = true,
			water = true,
			properties = {
				alwaysvisible = true,
				heat = 10,
				heatfalloff = 0.3,
				maxheat = 15,
				emitvector = [[0, 1, 0]],
				pos = [[r-2 r2, 5, r-2 r2]],
				size = 3,
				sizegrowth = 25,
				speed = [[0, 1 0, 0]],
				texture = [[flare]],
			},
		},
		light = {
			air = true,
			class = [[explspike]],
			count = 44,
			ground = true,
			water = true,
			properties = {
				alpha = 0.9,
				alphadecay = 0.02,
				color = [[1,0.8,0.5]],
				dir = [[-15 r50,-15 r50,-15 r50]],
				length = 2,
				width = 86,
			},
		},
		-- /Nuke Explosion ===================================================================================
		-- Smoke ===================================================================================
		smoke = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 1,
			ground = true,
			water = true,
			properties = {
				airdrag = 0.95,
				alwaysvisible = true,
				colormap = [[
				0.9 0.2 0 	0.05
				0.8 0.2 0 0.05
				0.2 0.1 0	0.35
				0.4 0.3 0.3 0.6
				0.15 0.15 0.16 0.5
				0.15 0.15 0.16 0.4
				0.15 0.15 0.16 0.3
				0.15 0.15 0.16 0.2
				0.15 0.15 0.16 0.2
				0 0 0 0.0]],
				directional = true,
				emitrot = 90,
				emitrotspread = 3,
				emitvector = [[0, 1, 0]],
				gravity = [[0, 0.00001, 0]],
				numparticles = 25,
				particlelife = 450,
				particlelifespread =	 150,
				particlesize = 5,
				particlesizespread = 15,
				particlespeed = 1,
				particlespeedspread = 5,
				pos = [[r-120r120, 0, r-120r120]],
				sizegrowth = 0.2002,
				sizemod = 1.000000,
				texture = [[dirt]],
				useairlos = true,
			},
		},
		smokemuzzleflame = {
			class = [[CBitmapMuzzleFlame]],
			count = 3,
			underwater = 1,
			water = true,
			ground = true,
			air = true,
			properties = {
				colormap = [[
				0.9 0.2 0 	0.025
				0.8 0.2 0 0.5
				0.2 0.1 0	0.6
				0.4 0.3 0.3 0.7
				0.15 0.15 0.16 0.5
				0.15 0.15 0.16 0.4
				0.15 0.15 0.16 0.3
				0.15 0.15 0.16 0.2
				0.15 0.15 0.16 0.2
				0 0 0 0.0]],
				dir = [[0r0.01r-0.01, 0.2r0.8, 0r0.01r-0.01]],
				frontoffset = 0.001,
				pos = [[0, 10, 0]],
				fronttexture = [[dirt]],
				length = 0,
				sidetexture = [[]],
				size = 240,
				sizegrowth = 0.3,
				ttl = 575,
			},
		},
		-- /Smoke ===================================================================================
		-- Rising Explosion =========================================================================
		pillarofFire = {
			class = [[CBitmapMuzzleFlame]],
			count = 3,
			underwater = 1,
			water = true,
			ground = true,
			air = true,
			properties = {
				colormap = [[
				0.9 0.2 0 	0.02
				0.8 0.2 0 	0.02
				0.75 0.2 0	0.025
				0.8 0.2 0 	0.025
				0.75 0.2 0	0.02
				0.8 0.2 0 	0.02
				0 0 0 0.0]],
				dir = [[0r0.02r-0.02, 0.2r0.8, 0r0.02r-0.02]],
				pos = [[r-6r6, 0, r-6r6]],
				frontoffset = 0,
				fronttexture = [[dirt]],
				length =50,
				sidetexture = [[flashside1]],
				size = 15,
				sizegrowth = 4.55,
				ttl = 150,
			},
		},
		fireballup = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 4,
			ground = true,
			properties = {
				emitrot = 0,
				emitrotspread = 3,
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[	1.0 1.0 1.0 0.01
								0.9 0.5 0.2 0.01
								0.8 0.1 0.1 0.01
								0.8 0.1 0.1 0.0]],
				directional = true,
				emitvector = [[0r0.01r-0.01, 2r0.5, 0r0.01r-0.01]],
				gravity = [[0, 0.1r0.05, 0]],
				numparticles = 1,
				particlelife = 150,
				particlelifespread = 25,
				particlesize = 20,
				particlesizespread = 25,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0r5r-5, 25, 0r5r-5]],
				sizegrowth = 0.00000001,
				sizemod = 1.0,
				texture = [[redexplo]],
				useairlos = false,
			},
		},
		fireballupred = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 4,
			ground = true,
			properties = {
				emitrot = 0,
				emitrotspread = 3,
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[	1.0 1.0 1.0 0.01
								0.9 0.5 0.2 0.01
								0.8 0.1 0.1 0.01
								0.8 0.1 0.1 0.0]],
				directional = true,
				emitvector = [[0r0.01r-0.01, 2r0.5, 0r0.01r-0.01]],
				gravity = [[0, 0.1r0.05, 0]],
				numparticles = 1,
				particlelife = 150,
				particlelifespread = 25,
				particlesize = 20,
				particlesizespread = 25,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0r5r-5, 25, 0r5r-5]],
				sizegrowth = 0.00000001,
				sizemod = 1.0,
				texture = [[bigexplo]],
				useairlos = false,
			},
		},
		-- /Rising Explosion ============================================================================
		-- Smokepillar===================================================================================
		smokecaterpillar = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 8,
			ground = true,
			properties = {
				emitrot = 0,
				emitrotspread = 3,
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[
				0.9 0.2 0 	0.05
				0.8 0.2 0 0.05
				0.8 0.2 0 0.05
				0.2 0.1 0	0.35
				0.2 0.1 0	0.35
				0.4 0.3 0.3 0.6
				0.15 0.15 0.16 0.5
				0.15 0.15 0.16 0.4
				0.15 0.15 0.16 0.3
				0.15 0.15 0.16 0.2
				0.15 0.15 0.16 0.2
				0 0 0 0.0]],
				directional = true,
				emitvector = [[0r0.01r-0.01, 2r0.5, 0r0.01r-0.01]],
				gravity = [[0, 0.07r0.025, 0]],
				delay              = [[0 i5]],
				explosiongenerator = [[custom:NUKEPILLAR]],
				numparticles = 1,
				particlelife = 500,
				particlelifespread = 25,
				particlesize = 20,
				particlesizespread = 25,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0r5r-5, 25, 0r5r-5]],
				sizegrowth = 0.00000001,
				sizemod = 1.0,
				texture = [[dirt]],
				useairlos = false,
			},
		},
		staitonarySmokeLower = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 8,
			ground = true,
			properties = {
				emitrot = 0,
				emitrotspread = 3,
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[
				0.9 0.2 0 		0.05
				0.8 0.2 0 		0.05
				0.8 0.2 0 		0.05
				0.2 0.1 0		0.35
				0.2 0.1 0		0.35
				0.4 0.3 0.3 	0.6
				0.15 0.15 0.16 0.5
				0.15 0.15 0.16 0.4
				0.15 0.15 0.16 0.3
				0.15 0.15 0.16 0.2
				0.15 0.15 0.16 0.2
				0 0 0 0.0]],
				directional = true,
				emitvector = [[0r0.01r-0.01, 2r0.5, 0r0.01r-0.01]],
				gravity = [[0, 0, 0]],
				numparticles = 1,
				particlelife = 500,
				particlelifespread = 25,
				particlesize = 20,
				particlesizespread = 25,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0r5r-5, 15r130, 0r5r-5]],
				sizegrowth = 0.00000001,
				sizemod = 1.0,
				texture = [[dirt]],
				useairlos = false,
			},
		},
		staitonarySmokeHigher = {
			air = true,
			class = [[CSimpleParticleSystem]],
			count = 8,
			ground = true,
			properties = {
				emitrot = 0,
				emitrotspread = 3,
				airdrag = 0.8,
				alwaysvisible = true,
				colormap = [[
				0 0 0  	0
				0 0 0  	0
				0 0 0  	0
				0.9 0.2 0 	0.05
				0.8 0.2 0 	0.15
				0.8 0.2 0 	0.25
				0.2 0.1 0	0.35
				0.2 0.1 0	0.35
				0.4 0.3 0.3 0.6
				0.15 0.15 0.16 0.5
				0.15 0.15 0.16 0.4
				0.15 0.15 0.16 0.3
				0.15 0.15 0.16 0.2
				0 0 0 0.0]],
				directional = true,
				emitvector = [[0r0.01r-0.01, 2r0.5, 0r0.01r-0.01]],
				gravity = [[0, 0.035, 0]],
				numparticles = 1,
				particlelife = 500,
				particlelifespread = 25,
				particlesize = 20,
				particlesizespread = 25,
				particlespeed = 5,
				particlespeedspread = 5,
				pos = [[0r5r-5, 50, 0r5r-5]],
				sizegrowth = 0.00000001,
				sizemod = 1.0,
				texture = [[dirt]],
				useairlos = false,
			},
		},
		-- /Smokepillar==================================================================================
		-- Cloudring==================================================================================
			cloudring = {
			class = [[CBitmapMuzzleFlame]],
			count = 12,
			underwater = 1,
			water = true,
			ground = true,
			air = true,
			properties = {
				colormap = [[
				0 0 0 0
				0 0 0 0
				0 0 0 0
				0 0 0 0
				0.9 0.2 0 		0.025
				0.8 0.2 0	 	0.5
				0.8 0.2 0	 	0.5
				0.2 0.1 0		0.6
				0.4 0.3 0.3 	0.7
				0.15 0.15 0.16 	0.6
				0.15 0.15 0.16 	0.5
				0.15 0.15 0.16 	0.4
				0.15 0.15 0.16 	0.2
				0 0 0 0.0]],
				dir = [[0r0.05r-0.05, 0.2r0.8, 0r0.05r-0.05]],
				frontoffset = -0.1,
				pos = [[0, 160r15r-15, 0]],
				fronttexture = [[dirt]],
				length = 64,
				sidetexture = [[dirt]],
				size = 100,
				sizegrowth = 0.3,
				ttl = 575,
			},
		},
		-- /Cloudring==================================================================================
	},
}
