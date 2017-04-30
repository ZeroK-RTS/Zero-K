-- heatray_shoverconer
-- redlaser_ak
-- yellowlaser_hlt
-- yellowlaser_can
-- orangelaser
-- stormtag
-- redlaser_llt
-- samtag
-- slashtag

return {
  ["heatray_shoverconer"] = {
    greenlaser = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.6 0.2 0.41 0.05   0 0 0 0.01]],
        size               = 160,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
  },

  ["redlaser_ak"] = {
    redlaser_light = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 0 0 0.05    0 0 0 0.01]],
        size               = 80,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 5,
      },
    },
  },

  ["yellowlaser_hlt"] = {
    yellowlaser = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 1 0 0.03    0 0 0 0.01]],
        size               = 320,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
  },

  ["yellowlaser_can"] = {
    yellowlaser = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 1 0 0.05    0 0 0 0.01]],
        size               = 160,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
  },

  ["orangelaser"] = {
    orangelaser = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 0.5 0 0.05    0 0 0 0.01]],
        size               = 120,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
  },

  ["stormtag"] = {
    fluffy = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.9,
        colormap           = [[1 1 1 1  1 1 1 1 0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 7,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 0,
        particlesize       = [[2.5 i-0.2]],
        particlesizespread = 0,
        particlespeed      = [[1 i0.10]],
        particlespeedspread = 0.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.2,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["redlaser_llt"] = {
    redlaser = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 0 0 0.03    0 0 0 0.01]],
        size               = 160,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
  },

  ["samtag"] = {
    fluffy = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.9,
        colormap           = [[1 1 1 1  1 1 1 1 0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 7,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 0,
        particlesize       = [[5 i-0.45]],
        particlesizespread = 0,
        particlespeed      = [[1 i0.72]],
        particlespeedspread = 0.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.2,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["slashtag"] = {
    fluffy = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[1 1 1 1  1 1 1 1 0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 3,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 30,
        particlelifespread = 0,
        particlesize       = [[5 i-0.45]],
        particlesizespread = 0,
        particlespeed      = [[-8 i4]],
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.2,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

}

