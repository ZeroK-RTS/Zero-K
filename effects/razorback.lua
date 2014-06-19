-- razorbackejector

return {
  ["razorbackejector"] = {
    usedefaultexplosions = false,
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
        numparticles       = 2,
        particlelife       = 60,
        particlelifespread = 0,
        particlesize       = 2.5,
        particlesizespread = 0,
        particlespeed      = 3,
        particlespeedspread = 3,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[shell]],
      },
    },
  },

}

