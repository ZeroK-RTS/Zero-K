-- medium_fire2
-- medium_bursts2
-- exp_medium_building
-- exp_medium_building_small
-- medium_smoke

return {
  ["medium_fire2"] = {
    fire2 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
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
        gravity            = [[0, 0, 0]],
        numparticles       = 50,
        particlelife       = 15,
        particlelifespread = 35,
        particlesize       = 2,
        particlesizespread = 1,
        particlespeed      = 2,
        particlespeedspread = 4,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1.5,
        sizemod            = 0.985,
        texture            = [[orangesmoke3]],
      },
    },
  },

  ["medium_bursts2"] = {
    pikes = {
      air                = true,
      class              = [[explspike]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.1,
        color              = [[1.0,0.9,0.6]],
        dir                = [[-15 r30,-15 r30,-15 r30]],
        length             = 7,
        width              = 8,
      },
    },
  },

  ["exp_medium_building"] = {
    fire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
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
        gravity            = [[0, 0.001, 0]],
        numparticles       = 22,
        particlelife       = 20,
        particlelifespread = 40,
        particlesize       = 20,
        particlesizespread = 10,
        particlespeed      = 1.5,
        particlespeedspread = 5.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[orangesmoke3]],
      },
    },
    fire2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        delay              = 5,
        explosiongenerator = [[custom:medium_fire2]],
        pos                = [[0, 0, 0]],
      },
    },
    groundflash = {
      circlealpha        = 0,
      circlegrowth       = 0,
      flashalpha         = 0.6,
      flashsize          = 130,
      ttl                = 55,
      color = {
        [1]  = 1,
        [2]  = 0.85000002384186,
        [3]  = 0.44999998807907,
      },
    },
    pikes = {
      air                = true,
      class              = [[explspike]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.1,
        color              = [[1.0,0.9,0.6]],
        dir                = [[-15 r30,-15 r30,-15 r30]],
        length             = 6.5,
        width              = 8,
      },
    },
    pikes2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        delay              = 7,
        explosiongenerator = [[custom:medium_bursts2]],
        pos                = [[0, 0, 0]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        delay              = 20,
        explosiongenerator = [[custom:medium_smoke]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["exp_medium_building_small"] = {
    fire2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:EXP_MEDIUM_BUILDING]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["medium_smoke"] = {
    smoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        airdrag            = 0.96,
        colormap           = [[0.05 0.05 0.05 0.200
                               0.00 0.00 0.00 0.001]],
        directional        = false,
        emitrot            = 80,
        emitrotspread      = 10,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.0001, 0]],
        numparticles       = 50,
        particlelife       = 30,
        particlelifespread = 70,
        particlesize       = 2,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 6,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1.5,
        sizemod            = 0.985,
        texture            = [[orangesmoke3]],
      },
    },
  },

}

