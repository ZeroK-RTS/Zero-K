-- glennis_sparkle
-- glennis
-- glennis_pow
-- glennis_pop
-- glennis_foom
-- glennis_poof

return {
  ["glennis_sparkle"] = {
    sparkle = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 40,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.90,
        colormap           = [[1 1 0.9 1.00
                               0 0 0.0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 0,
        particlesize       = 10,
        particlesizespread = 20,
        particlespeed      = 15,
        particlespeedspread = 5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[kspots]],
      },
    },
  },

  ["glennis"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GLENNIS_POP]],
        pos                = [[-0, 0, 0]],
      },
    },
    pikez = {
      air                = true,
      class              = [[explspike]],
      count              = 15,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.8,
        alphadecay         = 0.15,
        color              = [[1.0,0.7,0.3]],
        dir                = [[-15 r30,-15 r30,-15 r30]],
        length             = 30,
        width              = 12,
      },
    },
    pow = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GLENNIS_POW]],
        pos                = [[-0, 0, 0]],
      },
    },
    sparkle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GLENNIS_SPARKLE]],
        pos                = [[-0, 0, 0]],
      },
    },
  },

  ["glennis_pow"] = {
    poof = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[0.1 0.1 0.1 1.00
                               0.3 0.3 0.3 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 0,
        particlesize       = 1.5,
        particlesizespread = 0,
        particlespeed      = 0.01,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 2,
        sizemod            = 1.0,
        texture            = [[smoke]],
      },
    },
  },

  ["glennis_pop"] = {
    pop = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[1 1 1 1.00
                               1 1 1 1.00
                               0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = [[0.25 i1.1]],
        particlelifespread = 0,
        particlesize       = [[1 i0.3]],
        particlesizespread = 0,
        particlespeed      = [[2 i-0.2]],
        particlespeedspread = [[2 i-0.2]],
        pos                = [[0, 0, 0]],
        sizegrowth         = [[20 i-2]],
        sizemod            = 1.0,
        texture            = [[explosion]],
      },
    },
  },

  ["glennis_foom"] = {
    poof = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[1 1 1 1.00
                               1 1 1 1.00
                               0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 40,
        particlelifespread = 0,
        particlesize       = 1.5,
        particlesizespread = 0,
        particlespeed      = 6,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 2,
        sizemod            = 1.0,
        texture            = [[edge]],
      },
    },
  },

  ["glennis_poof"] = {
    poof = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[0.1 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.0 0.0 0.0 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 40,
        particlelifespread = 0,
        particlesize       = 1.5,
        particlesizespread = 0,
        particlespeed      = 6,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 2,
        sizemod            = 1.0,
        texture            = [[smoke2]],
      },
    },
  },

}

