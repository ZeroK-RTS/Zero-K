-- laserbladestrike

return {
  ["laserbladestrike"] = {
    usedefaultexplosions = false,
    pikes = {
      air                = true,
      class              = [[explspike]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.09,
        color              = [[1,1,0.25]],
        dir                = [[-4 r4 r4, 1 r4, -4 r4 r4]],
        length             = 1,
        lengthgrowth       = 1,
        width              = 16,
      },
    },
    sparks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[1 0.5 0.5 0.01  0.5 0.5 1 0.01  0 0 0 0]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 80,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.2, 0]],
        numparticles       = 3,
        particlelife       = 20,
        particlelifespread = 5,
        particlesize       = 4,
        particlesizespread = 2,
        particlespeed      = 4,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[plasma]],
      },
    },
  },

}

