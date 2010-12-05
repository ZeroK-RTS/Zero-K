-- napalm_expl
-- napalmfireball_piece3

return {
  ["napalm_expl"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 140,
      ttl                = 150,
      color = {
        [1]  = 0.69999998807907,
        [2]  = 0.30000001192093,
        [3]  = 0.10000000149012,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_piece3]],
        pos                = [[0, 0, 0]],
      },
    },
  },

  ["napalmfireball_piece3"] = {
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
        gravity            = [[0.001 r-0.002, 0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 130,
        particlelifespread = 20,
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
        explosiongenerator = [[custom:NAPALMFIREBALL_missile]],
        pos                = [[0 r200 r-200, 0 r200 r-200, 0 r200 r-200]],
      },
    },
  },
  
  ["napalmfireball_missile"] = {
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
        particlelife       = 350,	--minimum particle lifetime in frames
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

  ["firewalker_impact"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 256,
      ttl                = 450,
      color = {
        [1]  = 0.69999998807907,
        [2]  = 0.30000001192093,
        [3]  = 0.10000000149012,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_piece3]],
        pos                = [[0 r64 r-64, 0, 0 r64 r-64]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_firewalker]],
        pos                = [[0 r100 r-100, 0 r100 r-100, 0 r100 r-100]],
      },
    },
  },
  
  ["napalmfireball_firewalker"] = {
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
        particlelife       = 175,	--minimum particle lifetime in frames
        particlelifespread = 350,	--max value of random lifetime added to each particle's lifetime
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

