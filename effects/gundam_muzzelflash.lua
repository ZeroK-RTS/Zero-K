-- shotgun
-- bluemuzzle
-- gundam_large_muzzle_flash_fx
-- megapartflash
-- smallvulcan
-- redmuzzle
-- yellowmuzzelflash
-- beammuzzle
-- vulcan

return {
  ["shotgun"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.0 1 0.03
                               1 0.7 0 0.00
                               0 0.0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[shotgunflare]],
        length             = 6,
        sidetexture        = [[shotgunside]],
        size               = 5,
        sizegrowth         = 3,
        ttl                = 2,
      },
    },
    searingflame = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 0.7 0 0.00
                               1 0.7 0 0.01]],
        directional        = true,
        emitrot            = 3,
        emitrotspread      = 1,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 8,
        particlelife       = 10,
        particlelifespread = 5,
        particlesize       = 1,
        particlesizespread = 0,
        particlespeed      = 20,
        particlespeedspread = 10,
        pos                = [[0, 0, 0]],
        sizegrowth         = 1,
        sizemod            = 1,
        texture            = [[gunshot]],
        useairlos          = false,
      },
    },
    whiteglow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 5,
        maxheat            = 15,
        pos                = [[0, 0, 0]],
        size               = 1,
        sizegrowth         = 40,
        speed              = [[0, 0, 0]],
        texture            = [[laserend]],
      },
    },
  },

  ["bluemuzzle"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.00 1.0 0.01
                               0 0.55 0.5 0.01
                               0 0.00 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[flash3]],
        length             = 30,
        sidetexture        = [[shot]],
        size               = 10,
        sizegrowth         = 1,
        ttl                = 3,
      },
    },
  },

  ["gundam_large_muzzle_flash_fx"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[0.9 0.8 0.1 0.01
                               0.0 0.0 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[muzzlefront]],
        length             = 50,
        sidetexture        = [[muzzleside]],
        size               = 9,
        sizegrowth         = -1,
        ttl                = 10,
      },
    },
    whiteglow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 3.5,
        maxheat            = 15,
        pos                = [[0, 0, 0]],
        size               = 5,
        sizegrowth         = 40,
        speed              = [[0, 0, 0]],
        texture            = [[laserend]],
      },
    },
  },

  ["megapartflash"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.0 1.0 0.01
                               1 0.5 0.8 0.01
                               0 0.0 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.05,
        fronttexture       = [[flash3]],
        length             = 20,
        sidetexture        = [[shot]],
        size               = 10,
        sizegrowth         = 1,
        ttl                = 3,
      },
    },
    redpuff = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1.0 0.6 0.0 0.01
                               0.9 0.8 0.7 0.03
                               0.0 0.0 0.0 0.01]],
        directional        = true,
        emitrot            = 1,
        emitrotspread      = 5,
        emitvector         = [[dir]],
        gravity            = [[0.0, 0, .0]],
        numparticles       = 3,
        particlelife       = 1,
        particlelifespread = 2,
        particlesize       = 1,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 3,
        pos                = [[0.0, 1, 0.0]],
        sizegrowth         = 0.9,
        sizemod            = 1,
        texture            = [[dirt]],
        useairlos          = true,
      },
    },
  },

  ["smallvulcan"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.0 1.0 0.01
                               1 0.5 0.1 0.01
                               0 0.0 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.05,
        fronttexture       = [[flash3]],
        length             = 5,
        sidetexture        = [[shot]],
        size               = 2,
        sizegrowth         = 1,
        ttl                = 2,
      },
    },
  },

  ["redmuzzle"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.0 1.00 0.01
                               1 0.9 0.36 0.01
                               0 0.0 0.00 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.05,
        fronttexture       = [[flash3]],
        length             = 30,
        sidetexture        = [[shot]],
        size               = 10,
        sizegrowth         = 1,
        ttl                = 7,
      },
    },
    whiteglow = {
      air                = true,
      class              = [[heatcloud]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 10,
        heatfalloff        = 3.5,
        maxheat            = 15,
        pos                = [[0, 0, 0]],
        size               = 5,
        sizegrowth         = 40,
        speed              = [[0, 0, 0]],
        texture            = [[laserend]],
      },
    },
  },

  ["yellowmuzzelflash"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 0.7 0.4 0.01
                               1 0.5 0.2 0.01
                               0 0.0 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.05,
        fronttexture       = [[flash3]],
        length             = 30,
        sidetexture        = [[shot]],
        size               = 9,
        sizegrowth         = 1,
        ttl                = 1,
      },
    },
  },

  ["beammuzzle"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 1.0 1 0.01
                               1 0.2 1 0.01
                               0 0.0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[flash3]],
        length             = 50,
        sidetexture        = [[shot]],
        size               = 20,
        sizegrowth         = -1,
        ttl                = 5,
      },
    },
  },

  ["vulcan"] = {
    bitmapmuzzleflame = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        colormap           = [[1 0.6 0.9 0.01
                               1 0.5 0.8 0.01
                               0 0.0 0.0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0.05,
        fronttexture       = [[flash3]],
        length             = 30,
        sidetexture        = [[shot]],
        size               = 5,
        sizegrowth         = 1,
        ttl                = 1.5,
      },
    },
    smokeandfire = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      water              = true,
      properties = {
        airdrag            = 0.70,
        colormap           = [[0.1 0.1 0.1 0.01
                               0.5 0.3 0.0 0.05
                               0.5 0.1 0.1 1.00
                               0.1 0.1 0.1 1.00
                               0.5 0.5 0.5 1.00
                               0.0 0.0 0.0 0.01]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0.0, 1, 0.0]],
        gravity            = [[0.0, 2, 0.0]],
        numparticles       = 3,
        particlelife       = 10,
        particlelifespread = 4,
        particlesize       = 0,
        particlesizespread = 5,
        particlespeed      = 0,
        particlespeedspread = 2,
        pos                = [[0.0, 1, 0.0]],
        sizegrowth         = 3,
        sizemod            = 0.5,
        texture            = [[dirt]],
        useairlos          = true,
      },
    },
  },

}

