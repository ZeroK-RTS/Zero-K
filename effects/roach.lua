-- roachplosion

return {
  ["roachplosion"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:ROME]],
        pos                = [[0, 0,  0]],
      },
    },
    foom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:KLARA]],
        pos                = [[0, 0,  0]],
      },
    },
    groundflash = {
      circlealpha        = 0.5,
      circlegrowth       = 0,
      flashalpha         = 1,
      flashsize          = 150,
      ttl                = 40,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.20000000298023,
      },
    },
  },

}

