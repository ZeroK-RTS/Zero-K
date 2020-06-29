-- michelle_ne
-- michelle_w
-- michelle
-- michelle_s
-- michelle_pacemaker
-- michelle_e
-- michelle_se
-- michelle_sw
-- michelle_n
-- michelle_nw

local michelle_colormap = [[0.0 0.00 0.0 0.01
                            0.9 0.90 0.0 0.50
                            0.9 0.90 0.0 0.50
                            0.8 0.80 0.1 0.50
                            0.7 0.70 0.2 0.50
                            0.5 0.35 0.0 0.50
                            0.5 0.35 0.0 0.50
                            0.5 0.35 0.0 0.50
                            0.5 0.35 0.0 0.50
                            0.0 0.00 0.0 0.01]]

return {
  ["michelle_ne"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[1, 0, 1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_w"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[0, 0, -1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, -1]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle"] = {
    c = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i20]],
        explosiongenerator = [[custom:MICHELLE_PACEMAKER]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["michelle_s"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[-1, 0, 0]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_pacemaker"] = {
    e = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_E]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    n = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_N]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    ne = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_NE]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    nw = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_NW]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    s = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_S]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    se = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_SE]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    sw = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_SW]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
    w = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i8]],
        explosiongenerator = [[custom:MICHELLE_W]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
  },

  ["michelle_e"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[1, 0, 0]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_se"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[-1, 0, 1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_sw"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[-1, 0, -1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_n"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[0, 0, 1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

  ["michelle_nw"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = michelle_colormap,
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[1, 0, -1]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 50,
        particlesize       = 30,
        particlesizespread = 30,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

}

