return {
  ["scanner_ping"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = false,
      circlealpha        = 0.1,
      circlegrowth       = 3.6,
      flashalpha         = 0.1,
      flashsize          = 600,
      ttl                = 90,
      color = {
        [1]  = 0,
        [2]  = 0.5,
        [3]  = 1,
      },
    },
    ring1 = {
      air                = true,
      class              = [[CBitmapMuzzleFlame]],
      ground             = true,
      water              = true,
      count              = 1,
      properties = {
        colormap           = [[0.1 0.15 0.4 .1   .05 0.075 0.2 .1   0 0 0 0]],
        dir                = [[-0.01 r0.01, 1, -0.01 r0.01]],
        frontoffset        = 0,
        fronttexture       = [[shockwave]],
        length             = 1,
        pos                = [[0, 0, 0]],
        sidetexture        = [[null]],
        size               = 1,
        sizegrowth         = 600,
        ttl                = 60,
      },
    },
    --sphere = {
    --  air                = true,
    --  class              = [[CSpherePartSpawner]],
    --  count              = 1,
    --  ground             = true,
    --  water              = true,
    --  properties = {
    --    alpha              = 0.05,
    --    color              = [[0,0.5,1]],
    --    expansionspeed     = 10,
    --    ttl                = 60,
    --  },
    --},
  },
}

