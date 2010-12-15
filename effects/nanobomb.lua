-- nanobomb

return {
  ["nanobomb"] = {
    usedefaultexplosions = false,
    groundflash = {
      alwaysvisible      = false,
      circlealpha        = 1,
      circlegrowth       = 10,
      flashalpha         = 0.5,
      flashsize          = 100,
      ttl                = 15,
      color = {
        [1]  = 0,
        [2]  = 1,
        [3]  = 0,
      },
    },
    ring = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.9,
        alwaysvisible      = true,
        colormap           = [[0 1 0 0  0 1 0.75 1  0 0.75 0.5 1  0.75 1 0.75 1  0 0 0 0]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 5,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.2, 0]],
        numparticles       = 64,
        particlelife       = 10,
        particlelifespread = 5,
        particlesize       = 4,
        particlesizespread = 4,
        particlespeed      = 16,
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 8,
        sizemod            = 0.5,
        texture            = [[smokesmall]],
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.5,
        color              = [[0,1,0.5]],
        expansionspeed     = 15,
        ttl                = 10,
      },
    },
  },

}

