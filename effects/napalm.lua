-- napalm_expl
-- napalmfireball_piece3
-- napalmmissile
-- napalmmissilehalfduration
-- napalmfireball_missile
-- firewalker_impact
-- napalmfireball_firewalker

return {
  ["napalm_koda"] = {
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
      count              = 4,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-10 r20, 30, -10 r20]],
      },
    },
  },
  ["napalm_missile"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 512,
      ttl                = 1400,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 20,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = [[r16 y10 -1 x10x10 y10 256 a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, 30, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10]],
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
        explosiongenerator = [[custom:NAPALMFIREBALL_1400]],
        pos                = [[r6.3496 y10 -1 x10x10x10 y10 256 a10     y10 r6.2831 y11 -3.1415 a11 y11       r3.1415 y12 -1.570 a12 y12         -0.5x12x12 y0 0.0417x12x12x12x12 y1 -0.00139x12x12x12x12x12x12 y2 0.0000248015x12x12x12x12x12x12x12x12 y3 -0.000000275573x12x12x12x12x12x12x12x12x12x12 y4 0.00000000208768x12x12x12x12x12x12x12x12x12x12x12x12 y5 1 a0 a1 a2 a3 a4 a5 y13         -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,          -0.1667x12x12x12 y0 0.00833x12x12x12x12x12 y1 -0.000198412x12x12x12x12x12x12x12 y2 0.00000275573192x12x12x12x12x12x12x12x12x12 y3 -0.00000002505210838x12x12x12x12x12x12x12x12x12x12x12 y4 0 a12 a0 a1 a2 a3 a4 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
        -- 6.3496 = 256^(1/3)
        -- y10 = radius
        -- y11 = angle
        -- y12 = pitch
        -- y13 = cos(pitch)
        -- cos and sine are the 12th order series expansions
        --  -0.1667x12x12x12 y0 0.00833x12x12x12x12x12 y1 -0.000198412x12x12x12x12x12x12x12 y2 0.00000275573192x12x12x12x12x12x12x12x12x12 y3 -0.00000002505210838x12x12x12x12x12x12x12x12x12x12x12 y4 0 a12 a0 a1 a2 a3 a4 y12        1.570 x12 y12
      },
    },
  },
  
  ["napalm_drp"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 512,
      ttl                = 450,
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
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[0 r200 r-200, 30, 0 r200 r-200]], 	--random(0, 200) - random (0, 200)
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
        explosiongenerator = [[custom:NAPALMFIREBALL_450]],
        pos                = [[0 r200 r-200, 0 r200 r-200, 0 r200 r-200]],
      },
    },
  },
  
  ["napalm_firewalker"] = {
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
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[0 r100 r-100, 30, 0 r100 r-100]], 	--random(0, 200) - random (0, 200)
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 40,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = [[0 r100 r-100, 0 r100 r-100, 0 r100 r-100]],
      },
    },
  },
  
  -- Fireball particles of various lifetimes
  ["napalmfireball_1400"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.06     .6 .6 .6 0.05    .6 .6 .6 0.05   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 500,	--minimum particle lifetime in frames
        particlelifespread = 900,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[-10 r20, 0, -10 r20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
  ["napalmfireball_600"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.06     .6 .6 .6 0.05    .6 .6 .6 0.05   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 200,	--minimum particle lifetime in frames
        particlelifespread = 400,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[-10 r20, 0, -10 r20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
  ["napalmfireball_450"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.06     .6 .6 .6 0.05    .6 .6 .6 0.05   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 100,	--minimum particle lifetime in frames
        particlelifespread = 250,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[-10 r20, 0, -10 r20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
  ["napalmfireball_200"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.09     .6 .6 .6 0.08    .6 .6 .6 0.05   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 60,
        particlelifespread = 140,
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.0,
        pos                = [[-10 r20, 0, -10 r20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
  -- A version of Sak's effect
  ["firewalker_impact"] = {
    usedefaultexplosions = false,
	redground = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 22,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 r20 i20]],
        explosiongenerator = [[custom:redground]],
        pos                = [[20 r-40, -100, 20 r-40]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 50,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i9]],
        explosiongenerator = [[custom:NAPALMFIREBALL_firewalker]],
        pos                = [[100 r-200, 5, 100 r-200]],
      },
    },
  },
  ["redground"] = {
      groundflash = {
      flashalpha         = 0.7,
      flashsize          = 200,
      ttl                = 100,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
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
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.01   .6 .6 .6 0.1     .6 .6 .6 0.1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 90,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.3 r0.6, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 50,	--minimum particle lifetime in frames
        particlelifespread = 50,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.8,
        particlespeedspread = 1.2,
        pos                = [[10 r-20, 0, 10 r-20]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },
}
