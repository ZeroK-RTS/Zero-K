-- trail_huge0

return {
  ["trail_huge0"] = {
    fireball1 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      underwater         = 1,
      useairlos          = true,
      water              = true,
      properties = {
        airdrag            = 0.945,
        colormap           = [[0.2 0.4 0.25 0.2    0.2 0.15 0.05 0.2    0 0 0 0.25     0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 20,
        particlelifespread = 50,
        particlesize       = 13,
        particlesizespread = 10,
        particlespeed      = 0,
        particlespeedspread = 1.5,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.2,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

}

