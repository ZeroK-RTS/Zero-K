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
      count              = 6,
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
      count              = 25,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = [[r14.1421 y10 -1 x10x10 y10 200 a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, 30, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10]],
        -- circle
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 200,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_1400]],
        pos                = [[r3.7606 y10 -1 x10x10x10x10 y10 200 a10 y10     r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,              2 x12 y12 -1 a12 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
        -- RADIUS y10 = 200 + -1 * rand(200^(1/4))^4
        -- ANGLE  y11 = rand(2 pi) - pi
        -- A = rand(1)
        
        -- theta = ANGLE
        -- phi = 2 * arcsin(sqrt(A))
        
        -- XZMULT = sin(phi) = sin(2 * arcsin(sqrt(A))) = 2*sqrt(1 - A) * sqrt(A)
        -- X = cos(ANGLE) * RADIUS * XZMULT
        -- Y = (1 - 2*A) * RADIUS
        -- Z = sin(ANGLE) * RADIUS * XZMULT
        
        -- Old-not-so-good sphere
        -- [[r6.3496 y10 -1 x10x10x10 y10 256 a10     y10 r6.2831 y11 -3.1415 a11 y11      r1 y12 -0.5 a12 y0 1 x0x0 p0.5 y0 -1 x12 y1 0 a1 a0 y0 -0.5 x0 y0 0.25 a0 p0.5 y0   -1 x12 y1 0.5 a1 y1 1 x1x1 p0.5 y1 0 a12 a1 y1 -0.5 x1 y1 0.75 a1 p0.5 y1 -1 x1 y1 0 a0 a1 y12 2.22144 x12 y12      -0.5x12x12 y0 0.0417x12x12x12x12 y1 -0.00139x12x12x12x12x12x12 y2 0.0000248015x12x12x12x12x12x12x12x12 y3 -0.000000275573x12x12x12x12x12x12x12x12x12x12 y4 0.00000000208768x12x12x12x12x12x12x12x12x12x12x12x12 y5 1 a0 a1 a2 a3 a4 a5 y13         -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,          -0.1667x12x12x12 y0 0.00833x12x12x12x12x12 y1 -0.000198412x12x12x12x12x12x12x12 y2 0.00000275573192x12x12x12x12x12x12x12x12x12 y3 -0.00000002505210838x12x12x12x12x12x12x12x12x12x12x12 y4 0 a12 a0 a1 a2 a3 a4 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
        -- RADIUS y10 = 256 + -1 * rand(6.3496)^3
        -- ANGLE  y11 = rand(2 pi) - pi
        -- PITCH  y12 = sqrt(-0.5*(sqrt((a - 0.5)^2) - a) + 0.25) - (sqrt(-0.5 *(sqrt((-a + 0.5)^2) + a) + 0.75)) * (pi*sqrt(2)/2)
        -- XZMULT y13 = cos(PITCH)
        -- X = cos(ANGLE) * RADIUS * XZMULT
        -- Y = sin(PITCH)
        -- Z = sin(ANGLE) * RADIUS * XZMULT
        -- cos and sine are the 12th order series expansions
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
      count              = 25,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[r14.1421 y10 -1 x10x10 y10 200 a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, 30, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 200,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_450]],
        pos                = [[r3.7606 y10 -1 x10x10x10x10 y10 200 a10 y10     r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,              2 x12 y12 -1 a12 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
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
        pos                = [[r10 y10 -1 x10x10 y10 100 a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, 30, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10]],
      },
    },
	redploom_long = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 45,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
        pos                = [[r4.64159 y10 -1 x10x10x10 y10 100 a10 y10     r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,              2 x12 y12 -1 a12 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
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
        airdrag            = 0.98,
        colormap           = [[0 0 0 0.007   .6 .6 .6 0.018     .6 .6 .6 0.015    .6 .6 .6 0.012   0 0 0 0.007]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x13,              2 x12 y12 -1 a12,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x13]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 500,	--minimum particle lifetime in frames
        particlelifespread = 900,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.6,
        particlespeedspread = 1.2,
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
        colormap           = [[0 0 0 0.007   .6 .6 .6 0.018     .6 .6 .6 0.015    .6 .6 .6 0.012   0 0 0 0.007]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x13,              2 x12 y12 -1 a12,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x13]],
        gravity            = [[0.001 r-0.002, -0.001 r0.002, 0.001 r-0.002]],
        numparticles       = 2,
        particlelife       = 200,	--minimum particle lifetime in frames
        particlelifespread = 400,	--max value of random lifetime added to each particle's lifetime
        particlesize       = 30,
        particlesizespread = 10,
        particlespeed      = 0.5,
        particlespeedspread = 1.2,
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
        colormap           = [[0 0 0 0.007   .6 .6 .6 0.018     .6 .6 .6 0.015    .6 .6 .6 0.012   0 0 0 0.007]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x13,              2 x12 y12 -1 a12,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x13]],
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
        colormap           = [[0 0 0 0.001   .6 .6 .6 0.03     .6 .6 .6 0.02    .6 .6 .6 0.02   0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 30,
        emitvector         = [[r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x13,              2 x12 y12 -1 a12,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x13]],
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
