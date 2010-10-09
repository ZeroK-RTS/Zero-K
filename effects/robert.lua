-- robert_1
-- robert_1_1
-- robert_1_1_1
-- robert

return {
  ["robert_1"] = {
    dust = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:ROBERT_1_1]],
        pos                = [[-200 r400, 0, -200 r400]],
      },
    },
  },

  ["robert_1_1"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0.72 0.61 0.41 1      0 0 0 0.01]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.5, 0]],
        numparticles       = 1,
        particlelife       = 5,
        particlelifespread = 10,
        particlesize       = 5,
        particlesizespread = 10,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 3, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[kfoom]],
      },
    },
  },

  ["robert_1_1_1"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0.72 0.61 0.41 1      0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[-0, 1, 0]],
        gravity            = [[0, 0.05, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 20,
        particlesize       = 5,
        particlesizespread = 10,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0.02,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["robert"] = {
    e = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0, 0, i10]],
      },
    },
    n = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i10, 0, 0]],
      },
    },
    quadrant1 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i10, 0, 0i10]],
      },
    },
    quadrant2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i10, 0, 0i-10]],
      },
    },
    quadrant3 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i-10, 0, 0i-10]],
      },
    },
    quadrant4 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i-10, 0, 0i10]],
      },
    },
    s = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0, 0, 0 i-10]],
      },
    },
    w = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:ROBERT_1]],
        pos                = [[0 i-10, 0, 0]],
      },
    },
  },

}

