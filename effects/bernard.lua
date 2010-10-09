-- bernard_1_1
-- bernard_1
-- bernard
-- bernard_1_1_1

return {
  ["bernard_1_1"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 8,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 0,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 100, 0]],
        sizegrowth         = [[20 r 10]],
        sizemod            = 1.0,
        texture            = [[dust]],
      },
    },
  },

  ["bernard_1"] = {
    dust = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:bernard_1_1]],
        pos                = [[-1000 r2000, 0, -1000 r2000]],
      },
    },
  },

  ["bernard"] = {
    e = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0, 0, i5]],
      },
    },
    n = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i5, 0, 0]],
      },
    },
    quadrant1 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i5, 0, 0i5]],
      },
    },
    quadrant2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i5, 0, 0i-5]],
      },
    },
    quadrant3 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i-5, 0, 0i-5]],
      },
    },
    quadrant4 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i-5, 0, 0i5]],
      },
    },
    s = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0, 0, 0 i-5]],
      },
    },
    w = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1000,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:bernard_1]],
        pos                = [[0 i-5, 0, 0]],
      },
    },
  },

  ["bernard_1_1_1"] = {
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

}

