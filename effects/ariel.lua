-- ariel_splosh
-- ariel_gurgle
-- ariel_fizz_bubble
-- ariel_splash
-- ariel_fizz
-- torplosion

return {
  ["ariel_splosh"] = {
    splosh = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[0.7 0.7 0.9 0.8    0.7 0.7 0.9 0.8     0.5 0.5 0.6 0.6     0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 15,
        particlelifespread = 0,
        particlesize       = 4,
        particlesizespread = 1,
        particlespeed      = 0.001,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1,
        sizemod            = 1.0,
        texture            = [[kfoam]],
      },
    },
  },

  ["ariel_gurgle"] = {
    splosh = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[0.6 0.6 0.9 0.9    0.6 0.6 0.9 0.9     0.4 0.4 0.6 0.6     0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 15,
        particlelifespread = 0,
        particlesize       = 4,
        particlesizespread = 1,
        particlespeed      = 0.001,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.6,
        sizemod            = 1.0,
        texture            = [[kfoam]],
      },
    },
  },

  ["ariel_fizz_bubble"] = {
    splosh = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[0.7 0.7 0.9 0.8    0.7 0.7 0.9 0.9   0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[-0.1 r0.2, 0.5, -0.1 r0.1]],
        numparticles       = 1,
        particlelife       = 30,
        particlelifespread = 0,
        particlesize       = 0.5,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.01,
        sizemod            = 1.0,
        texture            = [[bubble]],
      },
    },
  },

  ["ariel_splash"] = {
    splosh = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[0.8 0.8 0.9 0.9     0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 20,
        particlelifespread = 20,
        particlesize       = 8,
        particlesizespread = 8,
        particlespeed      = 0.001,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = -0.26,
        sizemod            = 1.0,
        texture            = [[kfoam]],
      },
    },
  },

  ["ariel_fizz"] = {
    fizz = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r20]],
        explosiongenerator = [[custom:ARIEL_FIZZ_BUBBLE]],
        pos                = [[0,  0 i1, 0]],
      },
    },
  },

  ["torplosion"] = {
    fizz = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 25,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[5  r25]],
        explosiongenerator = [[custom:ARIEL_FIZZ]],
        pos                = [[-10 r20,   -10 r20,  -10 r20]],
      },
    },
    gurgle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[3  r10]],
        explosiongenerator = [[custom:ARIEL_SPLASH]],
        pos                = [[-10 r20,   -10 r20,  -10 r20]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.6,
        color              = [[0.7,0.7,0.9]],
        expansionspeed     = 4,
        ttl                = 8,
      },
    },
    splash = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[15 r4]],
        explosiongenerator = [[custom:ARIEL_SPLASH]],
        pos                = [[-5 r10,   -5 r10,  -5 r10]],
      },
    },
    splosh = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0  i0]],
        explosiongenerator = [[custom:ARIEL_SPLOSH]],
        pos                = [[-10 r20,   -10 r20,  -10 r20]],
      },
    },
  },

}

