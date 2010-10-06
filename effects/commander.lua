-- comgate_teleport_smoke
-- comgate_teleport
-- comgate_teleport_circle_lightning
-- comgate_teleport_glow
-- comgate_teleport_rgroundflash
-- comgate_teleport_circle_lightning_single
-- comgate
-- comgate_teleport_ygroundflash

return {
  ["comgate_teleport_smoke"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0 0 0 0.01  0.3 0.3 0.3 0.3      0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[-0, 1, 0]],
        gravity            = [[0, 0.2, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 0,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["comgate_teleport"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 85,
        explosiongenerator = [[custom:PARIS]],
        pos                = [[0, 0, 0]],
      },
    },
    ["electric circle0"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[21 r106]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[300 r-600, 0, 300 r-600]],
      },
    },
    ["electric circle1"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 450,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[22 r140]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[200 r-400, 0, 200 r-400]],
      },
    },
    ["electric circle2"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 730,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[06 r162]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[120 r-240, 0, 120 r-240]],
      },
    },
    ["electric circle3"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 3500,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r195]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[72 r-144, 0, 72 r-144]],
      },
    },
    ["electric circle4"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 33,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[195 r110]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[72 r-144, 0, 72 r-144]],
      },
    },
    ["electric circle5"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 33,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[305 r600]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[72 r-144, 0, 72 r-144]],
      },
    },
    glow = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 5,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i5]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_GLOW]],
        pos                = [[0, 0, 0]],
      },
    },
    rcircle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[210 i20]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_RGROUNDFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 200,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[180r162]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_SMOKE]],
        pos                = [[120 r-240, 0, 120 r-240]],
      },
    },
    ycircle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[160 r20]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_YGROUNDFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["comgate_teleport_circle_lightning"] = {
    ["electric circle5"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING_SINGLE]],
        pos                = [[26 r-52, 0, 26 r-52]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.3,
      flashsize          = 46,
      ttl                = 3,
      color = {
        [1]  = 0.5,
        [2]  = 0.5,
        [3]  = 1,
      },
    },
  },

  ["comgate_teleport_glow"] = {
    glow = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0 0 0 0.01   1 1 1 1             0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[-0, 1, 0]],
        gravity            = [[0, 0.00, 0]],
        numparticles       = 1,
        particlelife       = 200,
        particlelifespread = 0,
        particlesize       = 100,
        particlesizespread = 10,
        particlespeed      = 0.1,
        particlespeedspread = 0,
        pos                = [[0, 60, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[circularthingy]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 200,
      ttl                = 200,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.80000001192093,
        [3]  = 1,
      },
    },
  },

  ["comgate_teleport_rgroundflash"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 150,
      ttl                = 200,
      color = {
        [1]  = 1,
        [2]  = 0.20000000298023,
        [3]  = 0,
      },
    },
  },

  ["comgate_teleport_circle_lightning_single"] = {
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

  ["comgate"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:COMGATE_TELEPORT]],
        pos                = [[0, 0, 0]],
      },
    },
    ["electric circle4"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 0,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r7]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[r-40, 0, r-40]],
      },
    },
    ["electric circle5"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 0,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[50 r17]],
        explosiongenerator = [[custom:COMGATE_TELEPORT_CIRCLE_LIGHTNING]],
        pos                = [[40 r-40, 0,12 r-40]],
      },
    },
  },

  ["comgate_teleport_ygroundflash"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 150,
      ttl                = 200,
      color = {
        [1]  = 1,
        [2]  = 1,
        [3]  = 0.20000000298023,
      },
    },
  },

}

