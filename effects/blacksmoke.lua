return {
  ["blacksmoke"] = {
    dirtg = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.7,
        --alwaysvisible      = true,
        colormap           = [[1.0 0.5 0 1.0
                               1.0 0.5 0 1.0
                               0.9 0.4 0 1.0
                               0.6 0.2 0 1.0
                               0.3 0.1 0 1.0
                               0.0 0.0 0 1.0
                               0.0 0.0 0 0.5
                               0.0 0.0 0 0.1]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.3, 0]],
        numparticles       = 4,
        particlelife       = 60,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 4,
        sizegrowth         = 1,
        sizemod            = 0.9,
        texture            = [[new_dirta]],
        useairlos          = false,
      },
    },
  },
  ["blacksmokebubbles"] = {
    dirtg = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      underwater         = false,
      properties = {
        airdrag            = 0.7,
        --alwaysvisible      = true,
        colormap           = [[1.0 0.5 0 1.0
                               1.0 0.5 0 1.0
                               0.9 0.4 0 1.0
                               0.6 0.2 0 1.0
                               0.3 0.1 0 1.0
                               0.0 0.0 0 1.0
                               0.0 0.0 0 0.5
                               0.0 0.0 0 0.1]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.3, 0]],
        numparticles       = 4,
        particlelife       = 60,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 4,
        sizegrowth         = 1,
        sizemod            = 0.9,
        texture            = [[new_dirta]],
        useairlos          = false,
      },
    },
    bubblesuw = {
      air                = false,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = false,
      water              = false,
      underwater         = true,
      properties = {
        airdrag            = 0.7,
        --alwaysvisible      = true,
        colormap           = [[1.0 1.0 1 0.5
                               0.5 0.5 1 0.8
                               0.0 0.0 0 0.0]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.3, 0]],
        numparticles       = 4,
        particlelife       = 60,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 4,
        sizegrowth         = 1,
        sizemod            = 0.9,
        texture            = [[randdots]],
        useairlos          = false,
      },
    },
  },
}
