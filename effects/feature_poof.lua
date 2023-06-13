-- feature_poof

return {
  ["feature_poof_spawner"] = {
    poof01 = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = [[10]],
      ground             = true,
      properties = {
        delay              = [[i1 x0.1d]],
        damage             = [[d1]],
        explosionGenerator = [[custom:feature_poof]],
      },
    },
  },
  ["feature_poof"] = {
    poof01 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = [[1]],
      ground             = true,
      properties = {
        airdrag            = 0.975,
        alwaysvisible      = false,
        colormap           = [[0.8 0.65 0.55 1.0	0 0 0 0.0]],
        directional        = true,
        emitrot            = 180,
        emitrotspread      = 180,
        emitvector         = [[0, 1, 0]],
        gravity            = [[r-0.02 r0.02, -0.1 r0.05, r-0.02 r0.02]],
        numparticles       = [[1 d0.05]],
        particlelife       = 22,
        particlelifespread = 10,
        particlesize       = [[1.5 d0.2]],
        particlesizespread = [[d0.35]],
        particlespeed      = [[0.2 d0.04 r0.8]],
        particlespeedspread = 1,
        pos                = [[r-5d r10d, r-5d r10d, r-5d r10d]],
        sizegrowth         = 1.08,
        sizemod            = 0.995,
        texture            = [[dirt]],
      },
    },
  },
}

