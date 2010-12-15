-- barney_1_1
-- barney
-- barney_1

return {
  ["barney_1_1"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.3,
      flashsize          = 36,
      ttl                = 3,
      color = {
        [1]  = 0.5,
        [2]  = 0.5,
        [3]  = 1,
      },
    },
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[1 1 1 0.01     1 1 1 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.01 r-0.02, 0.01 r-0.02, 0.01 r-0.01]],
        numparticles       = 1,
        particlelife       = 2,
        particlelifespread = 0,
        particlesize       = 10,
        particlesizespread = 30,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 1, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[lightb]],
      },
    },
  },

  ["barney"] = {
    e = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0, 0, i3]],
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
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i3, 0, 0]],
      },
    },
    quadrant1 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i3, 0, 0i3]],
      },
    },
    quadrant2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i3, 0, 0i-3]],
      },
    },
    quadrant3 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i-3, 0, 0i-3]],
      },
    },
    quadrant4 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i-3, 0, 0i3]],
      },
    },
    s = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0, 0, 0 i-3]],
      },
    },
    w = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0.20]],
        explosiongenerator = [[custom:BARNEY_1]],
        pos                = [[0 i-3, 0, 0]],
      },
    },
  },

  ["barney_1"] = {
    dust = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:BARNEY_1_1]],
        pos                = [[-100 r200, 0, -100 r200]],
      },
    },
  },

}

