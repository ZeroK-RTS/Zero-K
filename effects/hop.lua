--hop
return {
   ["hop"] = {
    usedefaultexplosions = false,

    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              =  11,
        explosiongenerator = [[custom:BigBulletImpact]],
        pos                = [[0,19,0]],
      },
    },
    dirt = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:dirt]],
        pos                = [[0,0,0]],
      },
    },
    smoke = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 14,
        explosiongenerator = [[custom:smoke2]],
        pos                = [[0,23,0]],
      },
    },
    fanny = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 40,
        explosiongenerator = [[custom:fanny]],
        pos                = [[0,-1,0]],
      },
    },
    smoke2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 12,
        explosiongenerator = [[custom:klara_smokejets]],
        pos                = [[0,20,0]],
      },
    },
    },
  }
