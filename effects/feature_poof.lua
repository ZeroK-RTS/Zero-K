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
        gravity            = [[r-0.05 r0.05, -0.2 r0.05, r-0.05 r0.05]],
        numparticles       = [[1 d0.05]],
        particlelife       = 30,
        particlelifespread = 10,
        particlesize       = [[1 d0.25]],
        particlesizespread = [[d0.4]],
        particlespeed      = [[d0.05 r1]],
        particlespeedspread = 1,
        pos                = [[r-5 r5 xd2, r-25 r1 xd2, r-5 r5 xd2]],
        sizegrowth         = 1.2,
        sizemod            = 0.995,
        texture            = [[dirt]],
      },
    },
  },
}

