-- heatray_ceg
-- heatray_hit

return {
  ["heatray_ceg"] = {
    light = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[1 0.5 0 0.03  0 0 0 0.01]],
        size               = 80,
        sizegrowth         = 0,
        texture            = [[groundflash]],
        ttl                = 5,
      },
    },
  },

  ["heatray_hit"] = {
    usedefaultexplosions = false,
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = -0.15,
      flashalpha         = 0.6,
      flashsize          = 10,
      ttl                = 40,
      color = {
        [1]  = 1,
        [2]  = 0.5,
        [3]  = 0,
      },
    },
  },

}

