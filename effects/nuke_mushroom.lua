-- nuke_mushroom
-- nuke_mushroom_cap
-- nuke_mushroom_cap2
-- nuke_mushroom_cap3
-- nuke_mushroom_cap4
-- nuke_mushroom_ring

return {
  ["nuke_mushroom_cap"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.96,
        alwaysvisible      = true,
        colormap           = [[0.0 0.00 0.0 0.01
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.8 0.80 0.1 0.50
                               0.7 0.70 0.2 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.0 0.00 0.0 0.01]],
        directional        = true,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.0, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 80,
        particlelifespread = 20,
        particlesize       = 120,
        particlesizespread = 120,
        particlespeed      = 24,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["nuke_mushroom_cap3"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 0,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.98,
        alwaysvisible      = true,
        colormap           = [[0 0 0 0.01
                               1 1 1 1.00
                               1 1 1 1.00
                               1 1 1 1.00
                               1 1 1 1.00
                               1 1 1 1.00
                               0 0 0 0.01 ]],
        directional        = true,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        numparticles       = 1,
        particlelife       = 240,
        particlelifespread = 40,
        particlesize       = 60,
        particlesizespread = 60,
        particlespeed      = 24,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.98,
        alwaysvisible      = true,
        colormap           = [[0.0 0.0 0.0 0.01
                               1.0 0.7 0.3 0.90
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.00, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 240,
        particlelifespread = 40,
        particlesize       = 120,
        particlesizespread = 120,
        particlespeed      = 24,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["nuke_mushroom_cap4"] = {
    smoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.98,
        alwaysvisible      = true,
        colormap           = [[0.0 0.0 0.0 0.01
                               1.0 0.8 0.6 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.00, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 525,
        particlelifespread = 40,
        particlesize       = [[240 i24]],
        particlesizespread = 40,
        particlespeed      = [[24 i-2.3]],
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["nuke_mushroom_cap2"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.97,
        alwaysvisible      = true,
        colormap           = [[0.0 0.00 0.0 0.01
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.8 0.80 0.1 0.50
                               0.7 0.70 0.2 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.0 0.00 0.0 0.01]],
        directional        = true,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.05, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 160,
        particlelifespread = 40,
        particlesize       = 90,
        particlesizespread = 90,
        particlespeed      = 24,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = -0.1,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.98,
        alwaysvisible      = true,
        colormap           = [[0.0 0.0 0.0 0.01
                               1.0 0.7 0.3 0.60
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.00, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 190,
        particlelifespread = 40,
        particlesize       = 120,
        particlesizespread = 120,
        particlespeed      = 24,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["nuke_mushroom"] = {
    cap = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[0 i4]],
        explosiongenerator = [[custom:nuke_mushroom_cap]],
        pos                = [[-10 r20, 0 i20, -10 r20]],
      },
    },
    cap2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[200 i4]],
        explosiongenerator = [[custom:nuke_mushroom_cap2]],
        pos                = [[-10 r20, 1000 i20, -10 r20]],
      },
    },
    cap3 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[400 i4]],
        explosiongenerator = [[custom:nuke_mushroom_cap3]],
        pos                = [[-10 r20, 2000 i20, -10 r20]],
      },
    },
    cap4 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[600 i4]],
        explosiongenerator = [[custom:nuke_mushroom_cap4]],
        pos                = [[-10 r20, 3100 i5, -10 r20]],
      },
    },
    ring = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[330 i4]],
        explosiongenerator = [[custom:nuke_mushroom_ring]],
        pos                = [[-10 r20, 1500 i3, -10 r20]],
      },
    },
    nuke_rising_fireball_spawner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[0 i200]],
        explosiongenerator = [[custom:nuke_rising_fireball_spawner]],
        pos                = [[0, 0, 0]],
      },
    },
    nuke_rising_grey_smoke_spawner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[400 i200]],
        explosiongenerator = [[custom:nuke_rising_grey_smoke_spawner]],
        pos                = [[0, 0, 0]],
      },
    },
    nuke_rising_orange_smoke_spawner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[200 i200]],
        explosiongenerator = [[custom:nuke_rising_orange_smoke_spawner]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["nuke_mushroom_ring"] = {
    smoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.96,
        alwaysvisible      = true,
        colormap           = [[0.0 0.0 0.0 0.01
                               1.0 0.7 0.3 0.60
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.7 0.5 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               1.0 0.8 0.6 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.8 0.8 0.8 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 70,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.00, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 395,
        particlelifespread = 40,
        particlesize       = 120,
        particlesizespread = 120,
        particlespeed      = 48,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

}

