-- wolvflash
-- wolvmuzzle1
-- wolvmuzzle0

return {
  ["wolvflash"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.9,
      flashsize          = 60,
      ttl                = 8,
      color = {
        [1]  = 1,
        [2]  = 0.5,
        [3]  = 0,
      },
    },
  },

  ["wolvmuzzle1"] = {
    shells = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.97,
        colormap           = [[1 1 1 1   1 1 1 1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[dir]],
        gravity            = [[0, -0.5, 0]],
        numparticles       = 1,
        particlelife       = 25,
        particlelifespread = 0,
        particlesize       = 5,
        particlesizespread = 0,
        particlespeed      = 6,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[shell]],
      },
    },
  },

  ["wolvmuzzle0"] = {
    muzzleflash = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 0.7 0.2 0.01    1 0.7 0.2 0.01    0 0 0 0.01]],
        directional        = true,
        emitrot            = 30,
        emitrotspread      = 70,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 20,
        particlelife       = 15,
        particlelifespread = 0,
        particlesize       = 1,
        particlesizespread = 3,
        particlespeed      = 0.5,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[plasma]],
      },
    },
    muzzlesmoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[1 0.6 0 1    0.4 0.4 0.4 1    0.05 0.05 0.05 0.1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 30,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 20,
        particlelife       = 50,
        particlelifespread = 0,
        particlesize       = 10,
        particlesizespread = 3,
        particlespeed      = 1,
        particlespeedspread = 6,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[orangesmoke]],
      },
    },
  },

}

