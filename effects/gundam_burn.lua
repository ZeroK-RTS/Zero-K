-- burn

return {
  ["burn"] = {
    groundflash = {
      circlealpha        = 0.1,
      circlegrowth       = 3,
      flashalpha         = 1,
      flashsize          = 12,
      ttl                = 8,
      color = { 0.8, 0.1, 0 },
    },
    searingflame = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.8,
        alwaysvisible      = true,
        colormap           = [[0.9 0.5 0.4 0.04
                               0.9 0.4 0.1 0.01
                               0.5 0.1 0.1 0.01]],
        directional        = true,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.01, 0]],
        numparticles       = 2,
        particlelife       = 10,
        particlelifespread = 5,
        particlesize       = 20,
        particlesizespread = 0,
        particlespeed      = 5,
        particlespeedspread = 5,
        pos                = [[0, 2, 0]],
        sizegrowth         = 1,
        sizemod            = 0.5,
        texture            = [[gunshot]],
        useairlos          = false,
      },
    },
    smokeandfire = {
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 0.70,
        alwaysvisible      = true,
        colormap           = [[0.1 0.1 0.1 0.01
                               0.5 0.3 0.0 0.05
                               0.5 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.5 0.5 0.5 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0.0, 1, 0.0]],
        gravity            = [[0.0, 2, 0.0]],
        numparticles       = 3,
        particlelife       = 10,
        particlelifespread = 4,
        particlesize       = 0,
        particlesizespread = 5,
        particlespeed      = 0,
        particlespeedspread = 2,
        pos                = [[0.0, 1, 0.0]],
        sizegrowth         = 3,
        sizemod            = 0.5,
        texture            = [[dirt]],
        useairlos          = true,
      },
    },
  },

}

