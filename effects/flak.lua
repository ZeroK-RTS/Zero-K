-- flak_hit_16
-- flak_burst_16
-- flak_hit_24
-- flak_burst_24
-- flak_trail

return {
  ["flak_hit_16"] = {
    bursts = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:FLAK_BURST_16]],
        pos                = [[-8 r16, -8 r16, -8 r16]],
      },
    },
  },

  ["flak_burst_16"] = {
    burst = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.75  0 0 0 0.75  0 0 0 0]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 0,
        particlespeed      = 0.1,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[4 r8]],
        sizemod            = 0.5,
        texture            = [[smokesmall]],
      },
    },
  },

  ["flak_hit_24"] = {
    bursts = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:FLAK_BURST_24]],
        pos                = [[-8 r16, -8 r16, -8 r16]],
      },
    },
  },

  ["flak_burst_24"] = {
    burst = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0 0 0 0.75  0 0 0 0.75  0 0 0 0]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 60,
        particlelifespread = 20,
        particlesize       = 1,
        particlesizespread = 0,
        particlespeed      = 0.1,
        particlespeedspread = 0,
        pos                = [[0, 0, 0]],
        sizegrowth         = [[8 r16]],
        sizemod            = 0.5,
        texture            = [[smokesmall]],
      },
    },
  },
  
  ["flak_trail"] = {
    burst = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 0.5,
        colormap           = [[0.9 0.7 0 0.3   0 0 0 0.75  0 0 0 0.75  0 0 0 0.75  0 0 0 0]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[dir]],
        gravity            = [[0, 0, 0]],
        numparticles       = 3,
        particlelife       = 12,
        particlelifespread = 5,
        particlesize       = 0.2,
        particlesizespread = 0.1,
        particlespeed      = 0.3,
        particlespeedspread = 0.3,
        pos                = [[10 r-20, 10 r-20, 10 r-20]],
        sizegrowth         = [[3 r3]],
        sizemod            = 0.5,
        texture            = [[smokesmall]],
      },
    },
  },

}

