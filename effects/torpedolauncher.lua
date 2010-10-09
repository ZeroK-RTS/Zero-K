-- placeholder

return {
  ["placeholder"] = {
    bubbles = {
      air                = false,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = false,
      water              = true,
      properties = {
        airdrag            = 0.6,
        colormap           = [[1 1 1 0.01 1 1 1 0.01 0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.2, 0]],
        numparticles       = 20,
        particlelife       = 60,
        particlelifespread = 40,
        particlesize       = 0.5,
        particlesizespread = 5,
        particlespeed      = 4,
        particlespeedspread = 8,
        pos                = [[0r20, 0r20, 0r20]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[bubble]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 1,
        color              = [[1,1,1]],
        expansionspeed     = 2,
        ttl                = 20,
      },
    },
  },

}

