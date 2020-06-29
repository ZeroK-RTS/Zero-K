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
}