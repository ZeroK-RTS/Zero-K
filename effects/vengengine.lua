-- vengengine

return {
  ["vengengine"] = {
    fluffy = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.9,
        useairlos       = false,
        colormap           = [[0.2 0.2 0.2 1 0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 4,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 20,
        particlelifespread = 0,
        particlesize       = [[10 i-0.9]],
        particlesizespread = 0,
        particlespeed      = [[2 i1.44]],
        particlespeedspread = 0.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.2,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

}

