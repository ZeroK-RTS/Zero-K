-- vulcanfx

return {
  ["cyclopstrail"] = {
    alwaysvisible         = false,
    usedefaultexplosions = false,
    largeflash = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[0.9 0.1 0.9 0.01 0.5 0.1 0.8 0.01 0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = -1.5,
        sidetexture        = [[muzzleside]],
        size               = 2,
        sizegrowth         = 2,
        ttl                = 5,
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
        alphadecay         = 0.15,
        color              = [[0.9, 0.5, 0.9]],
        dir                = [[-6 r12,-6 r12,-6 r12]],
        length             = 1,
        width              = 4,
      },
    },
  }
}

