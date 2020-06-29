return {
  ["gali_fade"] = {
    usedefaultexplosions = false,
    galifading = {
      air    = true,
      class  = [[CExploSpikeProjectile]],
      count  = 4,
      ground = true,
      water  = true,
      properties = {
        length       = 55,
        width        = 86,
        alpha        = 0.45,
        alphaDecay   = 0.0046,
        lengthGrowth = -25,
        dir          = [[0, 1.5 1.2r, 0]],
        color        = [[0.8, 0.3, 0.15]],
      },
    },
  },

  ["gali_spike"] = {
    usedefaultexplosions = false,
    gravspike1 = {
      air    = true,
      class  = [[CExploSpikeProjectile]],
      count  = 6,
      ground = true,
      water  = true,
      properties = {
        length         = 75,
        width        = 20,
        alpha        = 0.67,
        alphaDecay   = 0.008,
        lengthGrowth = 35,
        dir          = [[0, 1.8 i0.5, 0]],
        color        = [[0.2, 0.1, 1]],
      },
    },
    groundflash = {
      circlealpha  = 0.55,
      circlegrowth = 1.7,
      flashalpha   = 0.8,
      flashsize    = 55,
      ttl          = 80,
      color = { 0.45, 0.38, 0.82 },
    },
  },

  ["gali_smallspikes"] = {
    usedefaultexplosions = false,
    gravspike3 = {
      air    = true,
      class  = [[CExploSpikeProjectile]],
      count  = 1,
      ground = true,
      water  = true,
      properties = {
        length       = 5,
        width        = 5,
        alpha        = 0.67,
        alphaDecay   = 0.018,
        lengthGrowth = 28,
        dir          = [[0, 2.5 i0.8, 0]],
        color        = [[1, 1, 0.5]],
        pos          = [[0, 0, 0]],
      },
    },
    groundflash = {
      circlealpha  = 0.45,
      circlegrowth = 0.2,
      flashalpha   = 0.7,
      flashsize    = 6,
      ttl          = 110,
      color = { 0.85, 0.88, 0.12 },
    },
  },

 ["galisplode"] = {
    usedefaultexplosions = false,
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:ROME]],
        pos                = [[0,-8,  0]],
      },
    },
    foom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 2,
        explosiongenerator = [[custom:GALI_SPIKE]],
        pos                = [[0, 0,  0]],
      },
    },
    fade = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 7,
        explosiongenerator = [[custom:GALI_FADE]],
        pos                = [[0, 0,0]],
      },
    },
    spikes = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        explosiongenerator = [[custom:GALI_SMALLSPIKES]],
        pos                = [[-100 r200, 0,-100 r200]],
      },
    },
  },
}

