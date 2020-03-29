function customSmoke(n)
    return {
        dirtg = {
            air                = true,
            class              = [[CSimpleParticleSystem]],
            count              = 2,
            ground             = true,
            water              = true,
            properties = {
                airdrag            = 0.99,
                --alwaysvisible      = true,
                colormap           = [[0.4 0.4 0.4 0.8
                               0.1 0.1 0.1 0.2
                               0 0 0 0]],
                directional        = true,
                emitrot            = 0,
                emitrotspread      = 0,
                emitvector         = [[dir]],
                emitmul            = 0.02,
                gravity            = [[0, 0.05, 0]],
                numparticles       = [[r4]],
                particlelife       = 60,
                particlelifespread = 30,
                particlesize       = 1,
                particlesizespread = 3,
                particlespeed      = 0.125,
                particlespeedspread = 0,
                pos                = [[-5 r10, -5 r10, -5 r10]],
                sizegrowth         = [[1 r0.5]],
                sizemod            = [[0.95 r0.02]],
                texture            = "csmoke"..n,
                useairlos          = false,
            },
        },
        bubbles_rising = {
            air                = true,
            class              = [[CSimpleParticleSystem]],
            count              = 1,
            ground             = false,
            water              = false,
            underwater         = true,
            properties = {
                airdrag            = 0.7,
                --alwaysvisible      = true,
                colormap           = [[0.9 0.9 0.9 0.9
                               0.8 0.8 0.8 0.2
                               0.8 0.8 0.8 0.1
                               0 0 0 0]],
                directional        = true,
                emitrot            = 45,
                emitrotspread      = 32,
                emitvector         = [[0, 1, 0]],
                gravity            = [[0, 0.2, 0]],
                numparticles       = [[r4]],
                particlelife       = 60,
                particlelifespread = 30,
                particlesize       = 1,
                particlesizespread = 3,
                particlespeed      = 1,
                particlespeedspread = 3,
                pos                = [[-5 r10, -5 r10, -5 r10]],
                sizegrowth         = [[0.5 r0.25]],
                sizemod            = [[0.98 r0.01]],
                texture            = [[randdots]],
                useairlos          = false,
            },
        },
    }
end

local smokes = {}

for i=0,11 do
    smokes['csmoke'..i] = customSmoke(i)
end

return smokes
