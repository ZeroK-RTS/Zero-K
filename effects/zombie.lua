Spring = Spring or {}
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

return {
  ["zombie"] = {
    light = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 0.75 0 0.33  0 0 0 0.01]],
        size               = "d1",
        sizegrowth         = 0.5,
        texture            = [[groundflash]],
        ttl                = 32,
      },
    },
    light2 = {
      air                = true,
      class              = [[CSimpleGroundFlash]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        colormap           = [[0 0.75 0 0.33  0 0 0 0.01]],
        size               = "d1",
        sizegrowth         = -0.5,
        texture            = [[groundflash]],
        ttl                = 32,
      },
    },
    airpop = {
      air                = true,
      class              = [[heatcloud]],
      count              = 10,
      ground             = true,
      water              = true,
      unit				 = true,
      properties = {
        heat               = "18 r20",
        heatfalloff        = 0.6,
        maxheat            = 38,
        pos                = [[-2d 4dr, 0, -2d 4dr]],
        size               = "3r",
        sizegrowth         = -0.01,
        speed              = [[0, 1, 0]],
        texture            = [[greenlight]],
      },
    },
  },
}
