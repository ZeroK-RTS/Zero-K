-- gauss_hit_h
-- gauss_tag_l
-- gauss_tag_snipe
-- gauss_ring_l
-- gauss_tag_m
-- gauss_tag_h
-- gauss_ring_h
-- gauss_hit_l
-- gauss_ring_m
-- gauss_hit_m
-- gauss_ring_snipe
-- gauss_hit_l_purple
-- gauss_hit_m_purple

return {
  ["gauss_hit_h"] = {
    inner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_HIT_M]],
        pos                = [[0, 0, 0]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0.5,1,1]],
        expansionspeed     = 8,
        ttl                = 8,
      },
    },
  },

  ["gauss_tag_l"] = {
    tealflash = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.5 1 1 0.03    0 0 0 0.01]],
        size               = 80,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
    trail = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_L]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gauss_tag_snipe"] = {
    tealflash = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.5 1 1 0.01    0 0 0 0.01]],
        size               = 320,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 15,
      },
    },
    trail = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_SNIPE]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gauss_ring_l"] = {
    tealring = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 1 0.5 0.03    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[bluering]],
        length             = 0.15,
        sidetexture        = [[smoketrailthinner]],
        size               = 1,
        sizegrowth         = 15,
        ttl                = 15,
      },
    },
  },

  ["gauss_tag_m"] = {
    tealflash = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.5 1 1 0.05    0 0 0 0.01]],
        size               = 120,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
    trail = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_M]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gauss_tag_h"] = {
    tealflash = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.5 1 1 0.08    0 0 0 0.01]],
        size               = 160,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 10,
      },
    },
    trail = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 3,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_RING_H]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["gauss_ring_h"] = {
    tealring = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 1 0.5 0.05    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[bluering]],
        length             = 0.15,
        sidetexture        = [[smoketrailthinner]],
        size               = 1,
        sizegrowth         = 31,
        ttl                = 31,
      },
    },
  },

  ["gauss_hit_l"] = {
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0.5,1,1]],
        expansionspeed     = 4,
        ttl                = 8,
      },
    },
  },

  ["gauss_ring_m"] = {
    tealring = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 1 0.5 0.03    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[bluering]],
        length             = 0.15,
        sidetexture        = [[smoketrailthinner]],
        size               = 1,
        sizegrowth         = 23,
        ttl                = 23,
      },
    },
  },

  ["gauss_hit_m"] = {
    inner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_HIT_L]],
        pos                = [[0, 0, 0]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0.5,1,1]],
        expansionspeed     = 6,
        ttl                = 8,
      },
    },
  },

  ["gauss_ring_snipe"] = {
    tealring = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 0.02 0.01 0.01    0 0 0 0.01]],
        dir                = [[dir]],
        frontoffset        = 0,
        fronttexture       = [[bluering]],
        length             = 0.05,
        sidetexture        = [[smoketrailthinner]],
        size               = 1,
        sizegrowth         = 31,
        ttl                = 31,
      },
    },
  },

  ["gauss_hit_l_purple"] = {
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0.9,0.1,0.9]],
        expansionspeed     = 4,
        ttl                = 8,
      },
    },
  },  
  
  ["gauss_hit_m_purple"] = {
    inner = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        dir                = [[dir]],
        explosiongenerator = [[custom:GAUSS_HIT_L_PURPLE]],
        pos                = [[0, 0, 0]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0.9,0.1,0.9]],
        expansionspeed     = 6,
        ttl                = 8,
      },
    },
  },  
  
}

