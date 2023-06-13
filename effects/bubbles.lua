return {
    ["bubbles_medium"]= {
        bubbles_rising = {
            air                = false,
            class              = [[CSimpleParticleSystem]],
            count              = 1,
            ground             = false,
            water              = true,
            underwater         = true,
            properties = {
                airdrag            = [[0.9]],
                --alwaysvisible      = true,
                colormap           = [[0.9 0.9 0.9 0.9
                               0.8 0.8 0.8 0.2
                               0.8 0.8 0.8 0.1
                               0 0 0 0]],
                directional        = true,
                emitrot            = 45,
                emitrotspread      = 32,
                emitvector         = [[0, 1, 0]],
                gravity            = [[0, 0 d0.1 x0.1, 0]],
                numparticles       = [[r4]],
                particlelife       = [[10 d0.5]],
                particlelifespread = 10,
                particlesize       = 1,
                particlesizespread = 3,
                particlespeed      = 1,
                particlespeedspread = 3,
                pos                = [[-5 r10, -5 r10, -5 r10]],
                sizegrowth         = [[0.3 r0.2]],
                sizemod            = [[0.98 r0.01]],
                texture            = [[randdots]],
                useairlos          = false,
            },
        },
    },
    ["bubbles_small"]= {
        bubbles_rising = {
            air                = false,
            class              = [[CSimpleParticleSystem]],
            count              = 2,
            ground             = false,
            water              = false,
            underwater         = true,
            properties = {
                airdrag            = [[0.95]],
                --alwaysvisible      = true,
                colormap           = [[0.9 0.9 0.9 0.8
                               0.8 0.8 0.8 0.2
                               0.5 0.5 0.5 0.1
                               0 0 0 0]],
                directional        = true,
                emitrot            = 0,
                emitrotspread      = 50,
                emitvector         = [[0, 1, 0]],
                gravity            = [[0, 0.04, 0]],
                numparticles       = [[r3]],
                particlelife       = 10,
                particlelifespread = 6,
                particlesize       = 0.8,
                particlesizespread = 1,
                particlespeed      = 0.5,
                particlespeedspread = 0.3,
                pos                = [[-4 r8, -4 r8, -4 r8]],
                sizegrowth         = 0.03,
                sizemod            = [[0.98 r0.01]],
                texture            = [[circularthingy]],
                useairlos          = false,
            },
        },
    },
}
