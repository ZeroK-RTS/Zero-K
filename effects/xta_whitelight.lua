-- whitelight

return {
  ["whitelight"] = {
    useairlos          = false,
    usedefaultexplosions = false,
    groundflash = {
      air                = true,
      alwaysvisible      = false,
      circlealpha        = 0.1,
      circlegrowth       = 0.1,
      count              = 1,
      flashalpha         = 1,
      flashsize          = 30,
      ground             = true,
      ttl                = 400,
      water              = true,
      color = {
        [1]  = 1,
        [2]  = 1,
        [3]  = 1,
      },
    },
    heatcloud = {
      air                = true,
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        heat               = 25,
        heatfalloff        = 1.14,
        maxheat            = 25,
        pos                = [[0, 0.0, 0]],
        size               = [[12.0 r1]],
        sizegrowth         = [[0.08 r.16]],
        sizemod            = 0,
        sizemodmod         = 0,
        speed              = [[0.05 r-0.1, 0.05 r-0.1, 0.05 r-0.1]],
        texture            = [[WhiteLight]],
        useairlos          = false,
      },
    },
  },

}

