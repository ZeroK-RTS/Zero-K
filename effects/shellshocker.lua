-- shellshockflash
-- shellshockgound
-- shellshockshells

return {
  ["shellshockflash"] = {
    muzzleflash = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 3,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 5,
        particlelifespread = 0,
        particlesize       = 0.1,
        particlesizespread = 3,
        particlespeed      = [[0.01 i7]],
        particlespeedspread = 1,
        pos                = [[0, 1, 0]],
        sizegrowth         = [[3 i3]],
        sizemod            = 1.0,
        texture            = [[kfoam]],
      },
    },
    muzzlesmoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[1 0.6 0 1    0.4 0.4 0.4 1    0.05 0.05 0.05 0.1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 10,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 50,
        particlelifespread = 0,
        particlesize       = [[15 i-0.9]],
        particlesizespread = 1,
        particlespeed      = [[10 i-1]],
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[orangesmoke2]],
      },
    },
  },

  ["shellshockgound"] = {
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

  ["shellshockshells"] = {
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

}

