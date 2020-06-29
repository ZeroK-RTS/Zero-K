-- norma_flames_smoke
-- norma
-- norma_flames_orange
-- norma_flames

return {
  ["norma_flames_smoke"] = {
    fire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0.0 0.0 0.0 0.01
                               0.1 0.1 0.1 0.70
                               0.0 0.0 0.0 0.10]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 30,
        particlelifespread = 15,
        particlesize       = 18,
        particlesizespread = 6,
        particlespeed      = 1,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[kTex1]],
      },
    },
  },

  ["norma"] = {
    hai = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i2]],
        explosiongenerator = [[custom:NORMA_FLAMES]],
        pos                = [[0, 1, 0]],
      },
    },
  },

  ["norma_flames_orange"] = {
    fire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0.00 0.00 0.00 0.01
                               0.54 0.30 0.04 0.70
                               0.27 0.15 0.02 0.35
                               0.00 0.00 0.00 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 15,
        particlelifespread = 15,
        particlesize       = 12,
        particlesizespread = 5,
        particlespeed      = 1,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[kTex1]],
      },
    },
  },

  ["norma_flames"] = {
    fire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1.0 1.00 0.30 0.40
                               1.0 0.30 0.15 1.00
                               0.8 0.27 0.13 1.00
                               0.4 0.13 0.07 0.60
                               0.1 0.00 0.00 0.20
                               0.0 0.00 0.00 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 15,
        particlelifespread = 15,
        particlesize       = 7,
        particlesizespread = 2,
        particlespeed      = 1,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[kTex1]],
      },
    },
    orangeness = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 10,
        explosiongenerator = [[custom:FIRE1_SMOKE1]],
        pos                = [[0, 10, 0]],
      },
    },
  },

}

