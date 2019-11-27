-- gate_teleport_smoke
-- gate_teleport
-- gate_teleport_circle_lightning
-- gate_teleport_glow
-- gate_teleport_rgroundflash
-- gate_teleport_circle_lightning_single
-- gate
-- gate_teleport_ygroundflash

return {
  ["gate_teleport_smoke"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
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

  ["gate_teleport"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:PARIS]],
        pos                = [[0, 0, 0]],
      },
    },

    glow = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[0 i2]],
        explosiongenerator = [[custom:GATE_TELEPORT_GLOW]],
        pos                = [[0, 0, 0]],
      },
    },
    rcircle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[55 i10]], -- [[110 i20]],
        explosiongenerator = [[custom:GATE_TELEPORT_RGROUNDFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[80r62]],
        explosiongenerator = [[custom:GATE_TELEPORT_SMOKE]],
        pos                = [[120 r-240, 0, 120 r-240]],
      },
    },
    ycircle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[30 r10]], -- [[60 r20]],
        explosiongenerator = [[custom:GATE_TELEPORT_YGROUNDFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gate_teleport_circle_lightning"] = {
    ["electric circle5"] = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GATE_TELEPORT_CIRCLE_LIGHTNING_SINGLE]],
        pos                = [[26 r-52, 0, 26 r-52]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.3,
      flashsize          = 46,
      ttl                = 3,
      underwater         = true,
      color = {
        [1]  = 0.5,
        [2]  = 0.5,
        [3]  = 1,
      },
    },
  },

  ["gate_teleport_glow"] = {
    glow = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
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
      ttl                = 90, --180,
	  underwater         = true,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.80000001192093,
        [3]  = 1,
      },
    },
  },

  ["gate_teleport_rgroundflash"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 150,
      ttl                = 60, --120,
      underwater         = true,
      color = {
        [1]  = 1,
        [2]  = 0.20000000298023,
        [3]  = 0,
      },
    },
  },

  ["gate_teleport_circle_lightning_single"] = {
    wezels = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
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

  ["gate"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GATE_TELEPORT]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gate_teleport_ygroundflash"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 150,
      ttl                = 75, --150,
      underwater         = true,
      color = {
        [1]  = 1,
        [2]  = 1,
        [3]  = 0.20000000298023,
      },
    },
  },
}

