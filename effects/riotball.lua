return {
  ["riotball"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = true,
      circlealpha        = 0.4,
      circlegrowth       = 7,
      flashalpha         = 0.2,
      flashsize          = 300,
      ttl                = 45,
      color = {
        [1]  = 0.3,
        [2]  = 0,
        [3]  = 0.4,
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
        color              = [[0.3,0,0.4]],
        expansionspeed     = 3,
        ttl                = 150,
      },
    },
  },
  
  ["riotball_dark"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = true,
      circlealpha        = 0.4,
      circlegrowth       = 7,
      flashalpha         = 0.2,
      flashsize          = 300,
      ttl                = 45,
      color = {
        [1]  = 0.15,
        [2]  = 0,
        [3]  = 0.2,
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
        color              = [[0.15,0,0.2]],
        expansionspeed     = 3,
        ttl                = 150,
      },
    },
    ring1 = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0.3 0 0.4 .1   .15 0 0.2 .1   0 0 0 0]],
        dir                = [[-1 r1, 1, -1 r1]],
        frontoffset        = 0,
        fronttexture       = [[shockwave]],
        length             = 1,
        pos                = [[0, 0, 0]],
        sidetexture        = [[null]],
        size               = 1,
        sizegrowth         = 175,
        ttl                = 18,
      },
    },	
  },  
  
  ["riotballplus"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = true,
      circlealpha        = 0.4,
      circlegrowth       = 7,
      flashalpha         = 0.5,
      flashsize          = 256,
      ttl                = 45,
      color = {
        [1]  = 0,
        [2]  = 1,
        [3]  = 1,
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
        color              = [[0,1,1]],
        expansionspeed     = 6,
        ttl                = 32,
      },
    },
  },
  
  ["riotballplus2_purple"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = true,
      circlealpha        = 0.4,
      circlegrowth       = 7,
      flashalpha         = 0.5,
      flashsize          = 320,
      ttl                = 64,
      color = {
        [1]  = 1,
        [2]  = 0,
        [3]  = 1,
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
        color              = [[1,0,1]],
        expansionspeed     = 6,
        ttl                = 45,
      },
    },
  },
}

