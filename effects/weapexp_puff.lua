-- weapexp_puff
-- puff_fire2

return {
  ["weapexp_puff"] = {
    fire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 0,
      water              = false,
      properties = {
        airdrag            = 0.93,
        colormap           = [[1.00 1.00 1.00 0.250
                               1.00 0.80 0.50 0.250
                               0.08 0.08 0.08 0.300
                               0.00 0.00 0.00 0.001]],
        directional        = false,
        emitrot            = 52,
        emitrotspread      = 38,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.05, 0]],
        numparticles       = 9,
        particlelife       = 20,
        particlelifespread = 40,
        particlesize       = 7,
        particlesizespread = 3,
        particlespeed      = 0.5,
        particlespeedspread = 1.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.7,
        sizemod            = 1.0,
        texture            = [[orangesmoke3]],
      },
    },
    fire2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 0,
      water              = false,
      properties = {
        delay              = 5,
        explosiongenerator = [[custom:puff_fire2]],
        pos                = [[0, 0, 0]],
      },
    },
    groundflash = {
      circlealpha        = 0,
      circlegrowth       = 0,
      flashalpha         = 0.35,
      flashsize          = 80,
      ttl                = 50,
      color = {
        [1]  = 1,
        [2]  = 0.89999997615814,
        [3]  = 0.34999999403954,
      },
    },
    pikes = {
      air                = true,
      class              = [[explspike]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.1,
        color              = [[1.0,0.9,0.6]],
        dir                = [[-5 r10,-5 r10,-5 r10]],
        length             = 4.5,
        width              = 3,
      },
    },
    sparks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      useairlos          = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[1 0.5 0.0 0.05
                               1 0.7 0.5 0.05
                               0 0.0 0.0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 80,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.4, 0]],
        numparticles       = 5,
        particlelife       = 15,
        particlelifespread = 0,
        particlesize       = 4,
        particlesizespread = 5,
        particlespeed      = 6,
        particlespeedspread = 4,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[plasma]],
      },
    },
  },

  ["puff_fire2"] = {
    fire2 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 0,
      water              = false,
      properties = {
        airdrag            = 0.96,
        colormap           = [[0.00 0.00 0.00 0.001
                               0.00 0.00 0.00 0.001
                               0.10 0.10 0.10 0.100
                               0.10 0.10 0.10 0.200
                               0.05 0.05 0.05 0.200
                               0.00 0.00 0.00 0.001]],
        directional        = false,
        emitrot            = 80,
        emitrotspread      = 10,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.05, 0]],
        numparticles       = 4,
        particlelife       = 15,
        particlelifespread = 35,
        particlesize       = 3,
        particlesizespread = 2,
        particlespeed      = 0.6,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.7,
        sizemod            = 0.985,
        texture            = [[orangesmoke3]],
      },
    },
  },

}

