-- smoke2
-- smoke

return {
  ["smoke2"] = {
    smoke1 = {
      air                = true,
      class              = [[smoke]],
      count              = 1,
      ground             = false,
      water              = false,
      properties = {
        agespeed           = 0.05,
        color              = 0.3,
        pos                = [[0.5 r-1, -20 r-10, 0.5 r-1]],
        size               = 2,
        sizeexpansion      = [[0.5 r0.5]],
        speed              = [[0.4 r-0.8, 0.8 r0.8, 0.4 r-0.8]],
        startsize          = 2,
      },
    },
  },

  ["smoke"] = {
    smoke1 = {
      air                = true,
      class              = [[smoke]],
      count              = 1,
      ground             = false,
      water              = false,
      properties = {
        agespeed           = 0.05,
        color              = 0.3,
        pos                = [[0.5 r-1, -20 r-10, 0.5 r-1]],
        size               = 2,
        sizeexpansion      = [[0.5 r0.5]],
        speed              = [[0.4 r-0.8, 0.8 r0.8, 0.4 r-0.8]],
        startsize          = 2,
      },
    },
  },

}

