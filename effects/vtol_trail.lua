-- raventrail

return {
  ["raventrail"] = {
    alwaysvisible      = false,
    usedefaultexplosions = false,
    largeflash = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[9.8 0.3 0.1 0.01 0.4 0.2 0.1 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = -33,
        sidetexture        = [[muzzleside]],
        size               = -6,
        sizegrowth         = 0.75,
        ttl                = 5,
      },
    },

    smoke_front = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[0.8 0.4 0.1 0.4 0.3 0.3 0.3 0.6 0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 50,
        emitvector         = [[dir]],
        gravity            = [[0.05 r-0.1, 0.05 r-0.1, 0.05 r-0.1]],
        numparticles       = 2,
        particlelife       = 20,
        particlelifespread = 0,
        particlesize       = 6,
        particlesizespread = 2,
        particlespeed      = 8,
        particlespeedspread = -4,
        pos                = [[0, 1, 3]],
        sizegrowth         = 1.5,
        sizemod            = 1.0,
        texture            = [[smoke]],
      },
    },
    spikes = {
      air                = true,
      class              = [[explspike]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.25,
        color              = [[0.8, 0.1, 0]],
        dir                = [[-6 r12,-6 r12,-6 r12]],
        length             = 22,
        width              = 10,
      },
    },
  },

}

