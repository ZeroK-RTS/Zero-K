-- red_strobe

return {
  ["red_strobe"] = {
    red = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 2,
        particlesize       = 4,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[-0.02 r0.01, -0.02 r0.01, -0.02 r0.01]],
        sizegrowth         = 0,
        sizemod            = 1,
        texture            = [[redlight]],
      },
    },
  },

}

