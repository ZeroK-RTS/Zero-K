local function GetPloomPos(pos)
	return {
	  air                = true,
	  class              = [[CExpGenSpawner]],
	  count              = 1,
	  ground             = true,
	  water              = true,
	  properties = {
		delay              = [[0]],
		explosiongenerator = [[custom:napalmfireball_480_small]],
		pos                = pos,
	  },
	}
end

local cegs = {
  ["napalm_phoenix"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 108,
      ttl                = 75,
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
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:NAPALMFIREBALL_75]],
        pos                = [[-20 r40, 30, -20 r40]],
      },
    },
  },
  ["napalm_koda"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 120,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    bigredploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_480_main]],
        pos                = [[0 0 0]],
      },
    },
    redploom_1 = GetPloomPos([[ 0 r10,  0 r10,  0 r10]]),
    redploom_2 = GetPloomPos([[ 42 r10,  35 r10,  0  r10]]),
    redploom_3 = GetPloomPos([[-42 r10,  35 r10,  0  r10]]),
    redploom_6 = GetPloomPos([[ 0  r10,  35 r10,  42 r10]]),
    redploom_7 = GetPloomPos([[ 0  r10,  35 r10, -42 r10]]),
  },
  ["napalm_pyro"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 128,
      ttl                = 440,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 9,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-35 r70, 30, -35 r70]],
      },
    },
  },
  ["napalm_koda_small_long"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 32,
      ttl                = 440,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_200]],
        pos                = [[-8 r16, 20, -8 16]],
      },
    },
  },
  ["napalm_infernal"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 110,
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
        pos                = [[-30 r60, 30, -30 r60]],
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
  },

  ["napalm_drp"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 0.8,
      flashsize          = 640,
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
        pos                = [[r17.3205 y10 -1 x10x10 y10 300 a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, 30, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10]],
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
        pos                = [[r4.1617 y10 -1 x10x10x10x10 y10 300 a10 y10     r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,              2 x12 y12 -1 a12 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
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

  ["napalm_firewalker_small"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 64,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 8,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i40]],
        explosiongenerator = [[custom:NAPALMFIREBALL_450]],
        pos                = [[-20 r40, 30, -20 r40]],
      },
    },
  },

  ["napalm_koda_small"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 52,
      ttl                = 60,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i10]],
        explosiongenerator = [[custom:NAPALMFIREBALL_45]],
        pos                = [[-10 r10, 25, -10 r10]],
      },
    },
  },

  ["napalm_gunshipbomb"] = {
    usedefaultexplosions = false,
    groundflash = {
      flashalpha         = 1,
      flashsize          = 120,
      ttl                = 480,
      color = {
        [1]  = 0.7,
        [2]  = 0.3,
        [3]  = 0.1,
      },
    },
    bigredploom_short = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_main_short]],
        pos                = [[0 12 0]],
      },
    },
    bigredploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_main]],
        pos                = [[0 12 0]],
      },
    },
    redploom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_600_big]],
        pos                = [[0 12 0]],
      },
    },
  },

  ["napalm_hellfire"] = {
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
        explosiongenerator = [[custom:NAPALMFIREBALL_600]],
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
        explosiongenerator = [[custom:NAPALMFIREBALL_1400]],
        pos                = [[r4.64159 y10 -1 x10x10x10 y10 100 a10 y10     r6.2831 y11 -3.1415 a11 y11    r1 y12    -1 x12 y0 1 a0 p0.5 y0 0 a12 p0.5 y1 2 x0 x1 y13       -0.5x11x11 y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10 x13,              2 x12 y12 -1 a12 x10,              -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10 x13]],
      },
    },
  },


  ["zeno_fireball"] = {
    miasma = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
		  properties = {
			  airdrag            = 1,
			  colormap           = [[0.3 0 1 0.05   0.25 0.1 1 0.05  0.5 0.2 1 0.14   0.5 0 1 0.13   0.05 0.022 0.05 0.05   0 0 0 0.01]],
			  directional        = false,
			  emitrot            = 0,
			  emitrotspread      = 40,
			  --emitvector         = [[0.3, 0.7, 0.3]],
			  gravity            = [[0, -0.1 r0.05, 0]],
			  numparticles       = 1,
			  particlelife       = [[20 d1]],
			  particlelifespread = 9,
			  particlesize       = [[10 d1]],
			  particlesizespread = 18.8,
			  particlespeed      = 150,
			  particlespeedspread = 0.6,
			  rotParams          = [[-24 r48, -60 r120, -180 r360]],
			  pos                = [[0 0 0]],
        size               = 400,
			  sizegrowth         = [[1 r1.9 d0.2]],
			  sizemod            = 1.0,
			  texture            = [[smoke]],
			  drawOrder          = 1,
			  castShadow         = false,
		  },
    },
    sparks_snow = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.85,
        colormap           = [[1 0.7 1 0.01   0.01 0.01 0.005 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 60,
        emitvector         = [[0, -1, 0]],
        gravity            = [[0, -0.15 i-0.05, 0]],
        numparticles       = 5,
        particlelife       = [[50 r25]],
        particlelifespread = 25,
        particlesize       = [[0.15 i0.1]],
        particlesizespread = 0.25,
        particlespeed      = 5,
        particlespeedspread = 3,
        pos                = [[10 r20, r20, 10 r20]],
        sizegrowth         = [[0.07]],
        sizemod            = 0.98,
        texture            = [[pinknovaexplo]],
      },
    },
  },


  ["nrlc_fireball"] = {
    flame = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
		  properties = {
			  airdrag            = 1,
			  colormap           = [[1 0.78 0.2 0.45   1.0 0.6 0.2 0.5  0.8 0.5 0.2 0.44   0.22 0.13 0.1 0.33   0.023 0.022 0.022 0.125   0 0 0 0.01]],
			  directional        = false,
			  emitrot            = 0,
			  emitrotspread      = 40,
			  --emitvector         = [[0.3, 0.7, 0.3]],
			  gravity            = [[0, 0.3 r0.15, 0]],
			  numparticles       = 1,
			  particlelife       = 36,
			  particlelifespread = 9,
			  particlesize       = [[18.4 d1]],
			  particlesizespread = 18.8,
			  particlespeed      = 150,
			  particlespeedspread = 0.6,
			  rotParams          = [[-24 r48, -60 r120, -180 r360]],
			  animParams         = [[10,10,30]],
			  pos                = [[0 0 0]],
        size               = 40,
			  sizegrowth         = [[4 r1.9]],
			  sizemod            = 0.94,
			  texture            = [[Smoke2]],
			  drawOrder          = 1,
			  castShadow         = true,
		  },
    },
  },

  ["nrlc_fireball_smol"] = {
    flame = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
		  properties = {
			  airdrag            = 0.97,
			  colormap           = [[1 0.78 0.2 0.9   1.0 0.6 0.2 1  0.8 0.5 0.2 0.88   0.22 0.13 0.1 0.66   0.023 0.022 0.022 0.25   0 0 0 0.01]],
			  directional        = false,
			  emitrot            = 70,
			  emitrotspread      = 40,
			  emitvector         = [[0.3, 0.7, 0.3]],
			  gravity            = [[0, 0.06 r0.05, 0]],
			  numparticles       = 1,
			  particlelife       = 24,
			  particlelifespread = 9,
			  particlesize       = 18.4,
			  particlesizespread = 18.8,
			  particlespeed      = 0.3,
			  particlespeedspread = 0.6,
			  rotParams          = [[-24 r48, -60 r120, -180 r360]],
			  animParams         = [[10,10,30]],
			  pos                = [[0 0 0]],
			  sizegrowth         = [[1.7 r1.9]],
			  sizemod            = 0.93,
			  texture            = [[Smoke2]],
			  drawOrder          = 1,
			  castShadow         = true,
		  },
    },
  },

  -- Fireball particles of various lifetimes
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

local altforms = {
   napalmfireball_150 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 50, particlelifespread = 100},
      },
    },
  },
  napalmfireball_75 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 25, particlelifespread = 50},
      },
    },
  },
  napalmfireball_450 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 150, particlelifespread = 300},
      },
    },
  },
  napalmfireball_45 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
      properties = {
        particlelife = 35,
        particlelifespread = 12,
        particlesize       = 38,
        particlesizespread = 16,},
      },
    },
  },
  napalmfireball_450_long = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 180, particlelifespread = 300},
      },
    },
  },
  napalmfireball_450_big = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	    properties = {particlelife = 50, particlelifespread = 80, particlesize = 40, particlesizespread = 20,},
      },
    },
  },
  napalmfireball_600 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 200, particlelifespread = 400},
      },
    },
  },
  napalmfireball_600_main_short = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .5 .5 .5 0.08     .5 .5 .5 0.06    .4 .4 .4 0.05   0 0 0 0.003]],
	    properties = {particlelife = 90, particlelifespread = 40, particlesize = 100, particlesizespread = 25,},
      },
    },
  },
  napalmfireball_600_main = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .5 .5 .5 0.08     .5 .5 .5 0.06    .4 .4 .4 0.05   0 0 0 0.003]],
	    properties = {particlelife = 380, particlelifespread = 50, particlesize = 80, particlesizespread = 25,
        numparticles       = 1,},
      },
    },
  },
  napalmfireball_600_big = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.001   .3 .3 .3 0.01     .3 .3 .3 0.025    .2 .2 .2 0.018   0 0 0 0.001]],
	    properties = {particlelife = 700, particlelifespread = 200, particlesize = 70, particlesizespread = 30},
      },
    },
  },
  napalmfireball_480_main = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.002   .35 .35 .35 0.010     .25 .25 .25 0.08    .12 .12 .12 0.06   0 0 0 0.003]],
	    properties = {particlelife = 470, particlelifespread = 30, particlesize = 110, particlesizespread = 25,},
      },
    },
  },
  napalmfireball_480_small = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		colormap   = [[0 0 0 0.001   .2 .2 .2 0.035     .2 .2 .2 0.025   .12 .12 .12 0.018   0 0 0 0.001]],
	    properties = {particlelife = 200, particlelifespread = 280, particlesize = 28, particlesizespread = 12,},
      },
    },
  },
  napalmfireball_750 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 250, particlelifespread = 500},
      },
    },
  },
  napalmfireball_840 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
	properties = {particlelife = 280, particlelifespread = 560},
      },
    },
  },
  napalmfireball_1400 = {
    source = "napalmfireball_200",
    modifications = {
      rocks = {
		properties = {
		  airdrag            = 0.98,
		  colormap           = [[0 0 0 0.005   .6 .6 .6 0.015     .6 .6 .6 0.012    .6 .6 .6 0.010   0 0 0 0.005]],
		  particlelife       = 500,	--minimum particle lifetime in frames
		  particlelifespread = 900,	--max value of random lifetime added to each particle's lifetime
		  particlespeed      = 0.6,
		  particlespeedspread = 1.2,
		},
      }
    }
  },
  napalm_firewalker_long = {
    source = "napalm_firewalker",
    modifications = {
      redploom_long = {
	properties = {
	  explosiongenerator = [[custom:NAPALMFIREBALL_840]],
	},
      },
    },
  },
}

local suMergeTable = Spring.Utilities.MergeTable
for cegName, info in pairs(altforms) do
  cegs[cegName] = suMergeTable(info.modifications, cegs[info.source], true)
end

return cegs
