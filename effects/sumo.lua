return {
  ["sumosmoke"] = {
    muzzlesmoke = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 6,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[0.20 0.11 0.0 0.3 0.20 0.11 0.0 0.03     0 0 0 0.01]],
        directional        = false,
        emitrot            = 60,
        emitrotspread      = 0,
        emitvector         = [[0, -1, 0]],
        gravity            = [[0, 0.3, 0]],
        numparticles       = 1,
        particlelife       = 8,
        particlelifespread = 10,
        particlesize       = [[3 i-0.4]],
        particlesizespread = 1,
        particlespeed      = [[4 i-1]],
        particlespeedspread = 1,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.8,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },
  ["sumoland"] = {
    dustcloud = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.7,
        colormap           = [[0.52 0.41 0.21 1      0 0 0 0.01]],
        directional        = false,
        emitrot            = 90,
        emitrotspread      = 10,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0.03, 0]],
        numparticles       = 30,
        particlelife       = 50,
        particlelifespread = 0,
        particlesize       = 1,
        particlesizespread = 3,
        particlespeed      = 6,
        particlespeedspread = 12,
        pos                = [[0, -10, 0]],
        sizegrowth         = 1.7,
        sizemod            = 1,
        texture            = [[smokesmall]],
      },
    },
    dirt = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 30,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.995,
        alwaysvisible      = true,
        colormap           = [[0.22 0.18 0.15 1   0.22 0.18 0.15 1	 0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 70,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.1, 0]],
        numparticles       = 8,
        particlelife       = 190,
        particlelifespread = 0,
        particlesize       = [[1 r10]],
        particlesizespread = 0,
        particlespeed      = 3,
        particlespeedspread = 4,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[debris2]],
      },
    },
    fanny = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 30,
        explosiongenerator = [[custom:FANNY]],
        pos                = [[0, 0, 0]],
      },
    },
  },
}
