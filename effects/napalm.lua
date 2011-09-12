-- napalm_expl
-- napalmfireball_piece3
-- napalmmissile
-- napalmmissilehalfduration
-- napalmfireball_missile
-- firewalker_impact
-- napalmfireball_firewalker

return {
  ["napalm_expl"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 80,
      ttl                = 330,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_piece3]],
        pos                = [[-10 r20, 0, -10 r20]],
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
        pos                = [[-10 r20, 10, -10 r20]],
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
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
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
  
  ["napalmlargeshort"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 512,
      ttl                = 500,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
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
      count              = 100,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_missile_small]],
        pos                = [[0 r200 r-200, 0 r200 r-200, 0 r200 r-200]],
      },
    },
  },
  
  ["firewalkernapalm"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 256,
      ttl                = 500,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 15,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_piece3]],
        pos                = [[0 r100 r-100, 0, 0 r100 r-100]], 	--random(0, 200) - random (0, 200)
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 60,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_missile_small]],
        pos                = [[0 r100 r-100, 0 r100 r-100, 0 r100 r-100]],
      },
    },
  },
  
  ["napalmfireball_missile_small"] = {
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
        particlelife       = 100,	--minimum particle lifetime in frames
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
    balls = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.03 r-0.06, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 500,	--minimum particle lifetime in frames
        particlelifespread = 100,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 90,
        particlesizespread = 10,
        particlespeed      = 0.8,
        particlespeedspread = 1.2,
        pos                = [[50 r-100, 50 r-50, 50 r-100]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
	redground = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r20 i20]],
        explosiongenerator = [[custom:redground128]],
        pos                = [[20 r-40, -80, 20 r-40]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 75,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i8]],
        explosiongenerator = [[custom:NAPALMFIREBALL]],
        pos                = [[100 r-200, 100 r-200, 100 r-200]],
      },
    },
  },
  
  ["napalmmissile_impact"] = {
  usedefaultexplosions = false,
    balls = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 9,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.03 r-0.06, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 1000,	--minimum particle lifetime in frames
        particlelifespread = 200,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 90,
        particlesizespread = 10,
        particlespeed      = 0.8,
        particlespeedspread = 1.2,
        pos                = [[100 r-200, 100 r-100, 100 r-200]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
	redground = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 66,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r20 i20]],
        explosiongenerator = [[custom:redground256]],
        pos                = [[20 r-40, -80, 20 r-40]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 320,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i4]],
        explosiongenerator = [[custom:NAPALMFIREBALL]],
        pos                = [[200 r-400, 100 r-200, 200 r-400]],
      },
    },
  },
  
  ["redground128"] = {
      groundflash = {
      flashalpha         = 0.7,
      flashsize          = 150,
      ttl                = 100,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
  },
  
  ["redground256"] = {
      groundflash = {
      flashalpha         = 0.7,
      flashsize          = 300,
      ttl                = 100,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
  },
  
  ["napalmfireball"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.3 r0.6, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 50,	--minimum particle lifetime in frames
        particlelifespread = 50,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.8,
        particlespeedspread = 1.2,
        pos                = [[10 r-20, 0, 10 r-20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[flame]],
      },
    },
  },
  
}

