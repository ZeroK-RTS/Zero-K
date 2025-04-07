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
				airdrag             = .99,
				alwaysvisible       = false,
				colormap            = [[0.45 0.25 0 0.01  0.45 0.25 0 0.01]],
				directional         = true,
				emitvector          = [[dir]],
        gravity             = [[dir]],
				numparticles        = 1,
				particlelife        = 2,
				particlesize        = 60,
				particlespeed       = 0.01,
				sizegrowth          = 40,
				sizemod             = 1,
				texture             = [[glow]],
			},
		},
    

    firetrail = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
				colormap            = [[0 0 0 0.01  0 0 0 0.01  0 0 0 0.01  0 0 0 0.01  0 0 0 0.01  0.45 0.25 0 0.01  0.9 0.5 0 0.01  0.45 0.25 0 0.01  0.27 0.15 0 0.01  0 0 0 0.01]],
        directional        = true,
        emitvector         = [[dir]],
        gravity            = [[-0.3r0.6 -0.3r0.6 -0.3r0.6]],
        numparticles       = 1,
        particlelife       = 7,
        particlelifespread = 5,
        particlesize       = 0.01,
        particlesizespread = 3,
        particlespeed      = 0,
        particlespeedspread = 1.2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.5,
        sizemod            = 1.0,
        texture            = [[smoke]],
      },
    },

	},

}

