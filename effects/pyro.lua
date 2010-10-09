-- pyrojump

return {
  ["pyrojump"] = {
    sparks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[1 1 0 0.01   1 1 0 0.01   1 0.5 0 0.01   0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 25,
        emitvector         = [[dir]],
        gravity            = [[0, -0.2, 0]],
        numparticles       = 2,
        particlelife       = 7,
        particlelifespread = 0,
        particlesize       = 12,
        particlesizespread = 0,
        particlespeed      = 6,
        particlespeedspread = 4,
        pos                = [[0, 1, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[plasma]],
      },
    },
  },

}

