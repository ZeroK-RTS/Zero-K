-- solange
-- solange_pillar

return {
  ["solange"] = {
    nw = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 150,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        delay              = [[0  i4]],
        explosiongenerator = [[custom:SOLANGE_PILLAR]],
        pos                = [[20 r40, i20, -20 r40]],
      },
    },
  },

  ["solange_pillar"] = {
    rocks = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.97,
        alwaysvisible      = true,
        colormap           = [[0.0 0.00 0.0 0.01
                               0.9 0.90 0.0 0.50
                               0.9 0.90 0.0 0.50
                               0.8 0.80 0.1 0.50
                               0.7 0.70 0.2 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.5 0.35 0.0 0.50
                               0.0 0.00 0.0 0.01]],
        directional        = true,
        emitrot            = 90,
        emitrotspread      = 10,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0.001 r-0.002, 0.01 r-0.02, 0.001 r-0.002]],
        numparticles       = 1,
        particlelife       = 150,
        particlelifespread = 150,
        particlesize       = 90,
        particlesizespread = 90,
        particlespeed      = 3,
        particlespeedspread = 3,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.05,
        sizemod            = 1.0,
        texture            = [[fireball]],
      },
    },
  },

}

