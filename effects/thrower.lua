-- thrower_shockwave
-- thrower_flash

local circleString = "r%.5f y10 -1 x10x10 y10 %d a10 y10      r6.283 y11 -3.1415 a11 y11 -0.5x11x11         y0 0.0417x11x11x11x11 y1 -0.00139x11x11x11x11x11x11 y2 0.0000248015x11x11x11x11x11x11x11x11 y3 -0.000000275573x11x11x11x11x11x11x11x11x11x11 y4 0.00000000208768x11x11x11x11x11x11x11x11x11x11x11x11 y5 1 a0 a1 a2 a3 a4 a5 x10, %d, -0.1667x11x11x11 y0 0.00833x11x11x11x11x11 y1 -0.000198412x11x11x11x11x11x11x11 y2 0.00000275573192x11x11x11x11x11x11x11x11x11 y3 -0.00000002505210838x11x11x11x11x11x11x11x11x11x11x11 y4 0 a11 a0 a1 a2 a3 a4 x10"

local function GetCircle(radius, yPos)
	radius = radius
	local weightedRadius = radius^(1/2)
	return circleString:format(weightedRadius, radius, yPos)
end

return {
  ["thrower_shockwave"] = {
    dirt = {
      count              = 12,
      air                = true,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        alphafalloff       = 2,
        alwaysvisible      = true,
        color              = [[0.2, 0.1, 0.05]],
        pos                = GetCircle(80, 1),
        size               = 20,
        speed              = [[r1.5 r-1.5, 2, r1.5 r-1.5]],
      },
    },
    groundflash = {
      air                = true,
      circlealpha        = 0.5,
      circlegrowth       = 8,
      flashalpha         = 0.9,
      flashsize          = 150,
      ground             = true,
      ttl                = 17,
      water              = true,
      underwater         = true,
      color = {
        [1]  = 0,
        [2]  = 0.5,
        [3]  = 0.2,
      },
    },
    poof00 = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 1,
      ground             = true,
      water              = true,
      underwater         = true,
      properties = {
        airdrag            = 0.8,
        colormap           = [[1.0 1.0 1.0 0.04	0.9 0.5 0.2 0.01	0.8 0.1 0.1 0.01]],
        directional        = false,
        emitrot            = 45,
        emitrotspread      = 32,
        emitvector         = [[0, 1, 0]],
        gravity            = [[0, -0.05, 0]],
        numparticles       = 16,
        particlelife       = 5,
        particlelifespread = 16,
        particlesize       = 25,
        particlesizespread = 0,
        particlespeed      = 10,
        particlespeedspread = 3,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0.5,
        sizemod            = 1,
        texture            = [[randdots]],
        useairlos          = false,
      },
    },
  },
}

