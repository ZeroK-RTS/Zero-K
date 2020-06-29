local fx = {
  ["light_green"] = {
    light = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 2,
        particlesize       = 6,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[-0.02 r0.01, -0.02 r0.01, -0.02 r0.01]],
        sizegrowth         = 0,
        sizemod            = 1,
        texture            = [[greenlight]],
      },
    },
  },
  ["light_red"] = {
    light = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 2,
        particlesize       = 6,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[-0.02 r0.01, -0.02 r0.01, -0.02 r0.01]],
        sizegrowth         = 0,
        sizemod            = 1,
        texture            = [[redlight]],
      },
    },
  },

  ["light_blue"] = {
    light = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[1 1 1 1  0 0 0 0.01]],
        directional        = false,
        emitrot            = 0,
        emitrotspread      = 0,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, 0, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 2,
        particlesize       = 6,
        particlesizespread = 1,
        particlespeed      = 0,
        particlespeedspread = 0,
        pos                = [[-0.02 r0.01, -0.02 r0.01, -0.02 r0.01]],
        sizegrowth         = 0,
        sizemod            = 1,
        texture            = [[bluelight]],
      },
    },
  },
}

local altforms = {
  light_red_short = {
    source = "light_red",
    modifications = {
      light = {
	properties = {particlelife = 5},
      },
    },
  },
  light_green_short = {
    source = "light_green",
    modifications = {
      light = {
	properties = {particlelife = 5},
      },
    },
  },
  light_blue_short = {
    source = "light_blue",
    modifications = {
      light = {
	properties = {particlelife = 5},
      },
    },
  },
  light_blue_big_short = {
    source = "light_blue",
    modifications = {
      light = {
	properties = {particlelife = 5, particlesize = 12},
      },
    },
  },
}

local suMergeTable = Spring.Utilities.MergeTable
for cegName, info in pairs(altforms) do
  fx[cegName] = suMergeTable(info.modifications, fx[info.source], true)
end

return fx
