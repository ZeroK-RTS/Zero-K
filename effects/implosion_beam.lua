-- implosion_beam

return {
  ["implosion_beam"] = {
    pop = {
      air                = true,
      class              = [[heatcloud]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alwaysvisible      = true,
        heat               = 10,
        heatfalloff        = 0.5,
        maxheat            = 15,
        pos                = [[r-2 r2, 5, r-2 r2]],
        size               = 128,
        sizegrowth         = 1,
        speed              = [[0, 1 0, 0]],
        texture            = [[pinknovaexplo]],
      },
    },
  },

}

