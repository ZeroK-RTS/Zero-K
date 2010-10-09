-- tests

return {
  ["tests"] = {
    pikez = {
      air                = true,
      class              = [[explspike]],
      count              = 15,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.8,
        alphadecay         = 0.05,
        color              = [[1.0,1.0,0.8]],
        dir                = [[-15 r30,-15 r30,-15 r30]],
        length             = 40,
        width              = 15,
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        color              = [[0.8,0.8,0.6]],
        expansionspeed     = 10,
        ttl                = 40,
      },
    },
  },

}

