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
  blastwing = {
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
      count              = 7,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_60]],
        pos                = [[-55 r110, 10 r30, -55 r110]],
      },
    },
    redploom_mid = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:napalmfireball_45]],
        pos                = [[-5 r10, 15 r5, -5 r10]],
      },
    },
    groundflash = {
      circlealpha        = 0.5,
      circlegrowth       = 0,
      flashalpha         = 0.8,
      flashsize          = 130,
      ttl                = 40,
      color = {
        [1]  = 1,
        [2]  = 0.69999998807907,
        [3]  = 0.20000000298023,
      },
    },
    star1 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 26,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 0.7 0.3 0.01    1 0.7 0.3 0.01    0.5 0.35 0.15 0.01    0.05 0.05 0.05 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 80,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.15, 0]],
        numparticles       = 2,
        particlelife       = 8,
        particlelifespread = 4,
        particlesize       = [[15 i0.8]],
        particlesizespread = 0,
        particlespeed      = [[11 i-0.25]],
        particlespeedspread = 2,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[-0.1 i0.015]],
        sizemod            = 1.0,
        texture            = [[plasma]],
      },
    },
  }
}

