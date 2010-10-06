-- missiletrailred
-- missiletrailyellow

return {
  ["missiletrailred"] = {
    alwaysvisible      = false,
    usedefaultexplosions = false,
    largeflash = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[9.8 0.3 0.1 0.01 9.8 0.3 0.1 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = -20,
        sidetexture        = [[muzzleside]],
        size               = -6,
        sizegrowth         = 0.75,
        ttl                = 3,
      },
    },

    spikes = {
      air                = true,
      class              = [[explspike]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.25,
        color              = [[0.8, 0.1, 0]],
        dir                = [[-6 r12,-6 r12,-6 r12]],
        length             = 9,
        width              = 6,
      },
    },
  },

  ["missiletrailyellow"] = {
    alwaysvisible      = false,
    usedefaultexplosions = false,
    largeflash = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[0.9 0.9 0.4 0.01 0.8 0.8 0.3 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = -20,
        sidetexture        = [[muzzleside]],
        size               = -6,
        sizegrowth         = 0.75,
        ttl                = 1,
      },
    },

    spikes = {
      air                = true,
      class              = [[explspike]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        alphadecay         = 0.5,
        color              = [[0.9, 0.9, 0.5]],
        dir                = [[-6 r12,-6 r12,-6 r12]],
        length             = 5,
        width              = 3,
      },
    },
  },

}

