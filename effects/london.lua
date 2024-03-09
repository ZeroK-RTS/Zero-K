-- london_flames
-- london_gflash
-- london
-- london_sphere
-- london_glow
-- london_flat

local effects = {
  ["london_flames"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 30,
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
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.0, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 180,
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

  ["london_gflash"] = {
    groundflash = {
      circlealpha        = 0.5,
      circlegrowth       = 30,
      flashalpha         = 0,
      flashsize          = 300,
      ttl                = 200,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.40000000596046,
      },
    },
  },

  ["london"] = {
    dustring = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 100,
        explosiongenerator = [[custom:LONDON_FLAMES]],
        pos                = [[0, 0, 0]],
      },
    },
    gflash = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 50,
        explosiongenerator = [[custom:LONDON_GFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
    glow = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[0 i10]],
        explosiongenerator = [[custom:LONDON_GLOW]],
        pos                = [[0, 0, 0]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 50,
        explosiongenerator = [[custom:LONDON_SPHERE]],
        pos                = [[0, 5, 0]],
      },
    },
    shroom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 100,
        explosiongenerator = [[custom:nuke_mushroom]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["london_sphere"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 1600,
      ttl                = 1200,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.20000000298023,
      },
    },
    --pikez = {
    --  air                = true,
    --  class              = [[explspike]],
    --  count              = 0,
    --  ground             = true,
    --  water              = true,
    --  underwater         = true,
    --  properties = {
    --    alpha              = 0.8,
    --    alphadecay         = 0.03,
    --    color              = [[1.0,1.0,0.8]],
    --    dir                = [[-15 r30,-15 r30,-15 r30]],
    --    length             = 4000,
    --    width              = 15,
    --  },
    --},
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        alpha              = 0.8,
        color              = [[0.8,0.8,0.6]],
        expansionspeed     = 30,
        ttl                = 100,
      },
    },
  },

  ["london_glow"] = {
    glow = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 3,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 1,
        alwaysvisible      = true,
        colormap           = [[0 0 0.0 0.01
                               1 1 0.8 0.90
                               0 0 0.0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[-0, 1, 0]],
        gravity            = [[0, 0.00, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 0,
        particlesize       = 1600,
        particlesizespread = 10,
        particlespeed      = 1,
        particlespeedspread = 0,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[diamondstar]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 1500,
      ttl                = 150,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.40000000596046,
      },
    },
  },

}

-- london
--  - LONDON_FLAMES: delay
--    - 30 flames spawned in a circle.
--  - LONDON_GFLASH: delay
--    - Circle flash.
--  - LONDON_GLOW: iterated delay, count 10
--    - Ground glow and flash.
--  - LONDON_SPHERE: delay, pos
--    - Expanding sphere. Also has a ground flash for some reason.
--  - NUKE_MUSHROOM: delay
--    - NUKE_MUSHROOM_CAP: Count 50, iterated delay and position.
--    - NUKE_MUSHROOM_CAP2: Count 50, iterated delay and position.
--    - NUKE_MUSHROOM_CAP3: Count 50, iterated delay and position.
--    - NUKE_MUSHROOM_CAP4: Count 50, iterated delay and position.
--    - NUKE_MUSHROOM_RING: Count 50, iterated delay and position.
--    - NUKE_RISING_FIREBALL_SPAWNER: Count 1 with pointless iterated delay. Rising fireball into the air.
--      - NUKE_RISING_FIREBALL_SUB: Count 150, iterated delay.
--    - NUKE_RISING_GREY_SMOKE_SPAWNER: Count 2 with iterated delay. Rising smoke cloud into the air.
--      - NUKE_RISING_GREY_SMOKE_SUB: Count 150, iterated delay.
--    - NUKE_RISING_ORANGE_SMOKE_SPAWNER: Count 1. Orange smoke.
--      - NUKE_RISING_ORANGE_SMOKE_SUB: Count 150, iterated delay.

effects.london_flat = {
	dustring = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 1,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = 100,
			explosiongenerator = [[custom:LONDON_FLAMES]],
			pos                = [[0, 0, 0]],
		},
	},
	gflash = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 1,
		ground             = true,
		water              = true,
		properties = {
			delay              = 50,
			explosiongenerator = [[custom:LONDON_GFLASH]],
			pos                = [[0, 0, 0]],
		},
	},
	glow = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 10,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[0 i10]],
			explosiongenerator = [[custom:LONDON_GLOW]],
			pos                = [[0, 0, 0]],
		},
	},
	sphere = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 1,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = 50,
			explosiongenerator = [[custom:LONDON_SPHERE]],
			pos                = [[0, 5, 0]],
		},
	},

	cap = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 50,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[100 i4]],
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
			delay              = [[300 i4]],
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
			delay              = [[500 i4]],
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
			delay              = [[700 i4]],
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
			delay              = [[430 i4]],
			explosiongenerator = [[custom:nuke_mushroom_ring]],
			pos                = [[-10 r20, 1500 i3, -10 r20]],
		},
	},

	nuke_rising_fireball_spawner = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 150,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[100  i4]],
			explosiongenerator = [[custom:nuke_rising_fireball_sub]],
			pos                = [[20 r40, i20, -20 r40]],
		},
	},

	nuke_rising_grey_smoke_spawner_1 = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 150,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[500  i4]],
			explosiongenerator = [[custom:nuke_rising_grey_smoke_sub]],
			pos                = [[20 r40, i20, -20 r40]],
		},
	},
	nuke_rising_grey_smoke_spawner_2 = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 150,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[700  i4]],
			explosiongenerator = [[custom:nuke_rising_grey_smoke_sub]],
			pos                = [[20 r40, i20, -20 r40]],
		},
	},

	nuke_rising_orange_smoke_spawner = {
		air                = true,
		class              = [[CExpGenSpawner]],
		count              = 150,
		ground             = true,
		water              = true,
		underwater         = true,
		properties = {
			delay              = [[300  i4]],
			explosiongenerator = [[custom:nuke_rising_orange_smoke_sub]],
			pos                = [[20 r40, i20, -20 r40]],
		},
	},
}

return effects
