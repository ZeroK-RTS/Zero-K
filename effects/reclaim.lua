-- reclaimshards1
-- reclaimshards2
-- reclaimshards3

return {
  ["reclaimshards1"] = {
    shards = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.7,
        colormap           = [[0.6 0.6 0.6 1  0.2 0.2 0.2 1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 360,
        emitvector         = [[0,0,0]],
        gravity            = [[0,0.7,0]],
        numparticles       = 1,
        particlelife       = 5,
        particlelifespread = 14,
        particlesize       = 3,
        particlesizespread = 2,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0,-0.5,0]],
        sizegrowth         = -0.2,
        sizemod            = 1.0,
        texture            = [[shard1]],
      },
    },
  },

  ["reclaimshards2"] = {
    shards = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.7,
        colormap           = [[0.6 0.6 0.6 1  0.2 0.2 0.2 1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 360,
        emitvector         = [[0,0,0]],
        gravity            = [[0,0.7,0]],
        numparticles       = 1,
        particlelife       = 4,
        particlelifespread = 12,
        particlesize       = 3,
        particlesizespread = 2,
        particlespeed      = 2,
        particlespeedspread = 2,
        pos                = [[0,-0.25,0]],
        sizegrowth         = -0.15,
        sizemod            = 1.0,
        texture            = [[shard2]],
      },
    },
  },

  ["reclaimshards3"] = {
    shards = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.7,
        colormap           = [[0.6 0.6 0.6 1  0.2 0.2 0.2 1]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 360,
        emitvector         = [[0,0,0]],
        gravity            = [[0,0.7,0]],
        numparticles       = 1,
        particlelife       = 3,
        particlelifespread = 10,
        particlesize       = 3,
        particlesizespread = 2,
        particlespeed      = 2,
        particlespeedspread = 5,
        pos                = [[0,0,0]],
        sizegrowth         = -0.1,
        sizemod            = 1.0,
        texture            = [[shard3]],
      },
    },
  },

}

