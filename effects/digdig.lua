-- dig3
-- digdig

return {
  ["dig3"] = {
    dirt = {
      air                = true,
      count              = 8,
      ground             = true,
      properties = {
        color              = [[.2, .15, .1]],
        pos                = [[-3 r6, r6, -3 r6]],
        size               = 10,
        slowdown           = 1,
        speed              = [[0.3 r-0.6, 1 r1.0, 0.3 r-0.6]],
      },
    },
  },

  ["digdig"] = {
    burst = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i5]],
        explosiongenerator = [[custom:dig3]],
        pos                = [[0, 0, 0]],
      },
    },
  },

}

