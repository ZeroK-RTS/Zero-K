return {
  ["heavy_cannon_muzzle"] = {
	muzzle = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:RAIDMUZZLE]],
        pos                = [[0, 0, 0]],
		dir				   = [[dir]],
      },
    },
	muzzle2 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:LEVLRMUZZLE]],
        pos                = [[0, 0, 0]],
		dir				   = [[dir]],
      },
    },	
  }, 
}