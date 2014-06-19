-- hltradiate0
-- hltradiate

return {
  ["hltradiate0"] = {
    pollute = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[1 1 1 1     0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[dir]],
        gravity            = [[0, 0.5, 0]],
        numparticles       = 1,
        particlelife       = 30,
        particlelifespread = 0,
        particlesize       = 2,
        particlesizespread = 0,
        particlespeed      = 7,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = 0.8,
        sizemod            = 1.0,
        texture            = [[smokesmall]],
      },
    },
  },

  ["hltradiate"] = {
    boom = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 10,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i1]],
        explosiongenerator = [[custom:HLTRADIATE_VAPOR]],
        pos                = [[-0, 0, 0]],
      },
    },
  },

}

