return {
  ["riotball"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = true,
      circlealpha        = 0.4,
      circlegrowth       = 7,
      flashalpha         = 0.2,
      flashsize          = 256,
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
        alpha              = 0.7,
        color              = [[0.3,0,0.4]],
        expansionspeed     = 6,
        ttl                = 32,
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
      ttl                = 45,
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
        ttl                = 40,
      },
    },
  },
}

