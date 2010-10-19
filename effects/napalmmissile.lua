return {
  ["napalmmissile"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 512,
      ttl                = 1000,
      color = {
        [1]  = 0.69999998807907,
        [2]  = 0.30000001192093,
        [3]  = 0.10000000149012,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_piece3]],
        pos                = [[0 r200 r-200, 0, 0 r200 r-200]], 	--random(0, 200) - random (0, 200)
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 180,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_long]],
        pos                = [[0 r200 r-200, 0 r200 r-200, 0 r200 r-200]],
      },
    },
  },
  
  ["napalmfireball_long"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1    .6 .6 .6 0.1   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 350,	--minimum particle lifetime
        particlelifespread = 650,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[10 r10, 30, -10 r10]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

}

