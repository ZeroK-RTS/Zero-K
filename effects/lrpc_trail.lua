-- vulcanfx

return {
  ["vulcanfx"] = {
    usedefaultexplosions = false,
		
    glare               = {
			class      = [[CSimpleParticleSystem]],
			count      = 1,
			ground     = true,
			air        = true,
			unit       = true,
			water      = true,
			underwater = true,
			properties = {
				airdrag             = 0.3,
				alwaysvisible       = false,
				colormap            = [[0.9 0.5 0 0.01  0 0 0 0.01]],
				directional         = true,
				emitvector          = [[dir]],
				numparticles        = 1,
				particlelife        = 3,
				particlesize        = 60,
				particlespeed       = 0,
				sizegrowth          = 40,
				sizemod             = 1,
				texture             = [[glow2]],
			},
		},
    
		front                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.09 0.05 0 0.01  0.05 0.045 0 0.01  0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = -1.5,
				sidetexture  = [[plasma]],
				size         = 90,
				ttl          = 1,
			},
		},
    
		mid                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.09 0.05 0 0.01  0.05 0.045 0 0.01  0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = -2,
				sidetexture  = [[smoothtrail]],
				size         = 20,
				ttl          = 1,
			},
		},
    
		shaft                = {
			air        = true,
			class      = [[CBitmapMuzzleFlame]],
			count      = 1,
			ground     = true,
			underwater = 1,
			water      = true,
			properties = {
				colormap     = [[0.09 0.05 0 0.01  0.05 0.045 0 0.01  0 0 0 0.01]],
				dir          = [[dir]],
				frontoffset  = 0,
				fronttexture = [[null]],
				length       = -3,
				sidetexture  = [[smoothtrail]],
				size         = 20,
				sizegrowth   = -0.2,
				ttl          = 10,
			},
		},
	},

}

