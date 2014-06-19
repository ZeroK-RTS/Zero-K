-- fanny
-- fanny_1
-- fanny_1_1

return {
  ["fanny"] = {
    e = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0, 0, i5]],
      },
    },
    n = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i5, 0, 0]],
      },
    },
    quadrant1 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i5, 0, 0i5]],
      },
    },
    quadrant2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i5, 0, 0i-5]],
      },
    },
    quadrant3 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i-5, 0, 0i-5]],
      },
    },
    quadrant4 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i-5, 0, 0i5]],
      },
    },
    s = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0, 0, 0 i-5]],
      },
    },
    w = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[10 i1]],
        explosiongenerator = [[custom:FANNY_1]],
        pos                = [[0 i-5, 0, 0]],
      },
    },
  },

  ["fanny_1"] = {
    dust = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:FANNY_1_1]],
        pos                = [[-200 r400, 0, -200 r400]],
      },
    },
  },

  ["fanny_1_1"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        alwaysvisible      = true,
        colormap           = [[0.22 0.18 0.15 1      0 0 0 0.01]],
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

}

