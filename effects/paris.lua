-- paris_glow
-- paris
-- paris_gflash
-- paris_sphere

return {
  ["paris_glow"] = {
    glow = {
      air                = true,
      class              = [[CSimpleParticleSystem]],
      count              = 2,
      ground             = true,
      water              = true,
      properties = {
        airdrag            = 1,
        colormap           = [[0 0 0 0.01           0.8 0.8 0.8 0.9       0 0 0 0.01]],
        directional        = true,
        emitrot            = 0,
        emitrotspread      = 180,
        emitvector         = [[-0, 1, 0]],
        gravity            = [[0, 0.00, 0]],
        numparticles       = 1,
        particlelife       = 10,
        particlelifespread = 0,
        particlesize       = 60,
        particlesizespread = 10,
        particlespeed      = 1,
        particlespeedspread = 0,
        pos                = [[0, 2, 0]],
        sizegrowth         = 0,
        sizemod            = 1.0,
        texture            = [[circularthingy]],
      },
    },
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.5,
      flashsize          = 100,
      ttl                = 10,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.80000001192093,
        [3]  = 1,
      },
    },
  },

  ["paris"] = {
    dustring = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:GEORGE]],
        pos                = [[0, 0, 0]],
      },
    },
    gflash = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:PARIS_GFLASH]],
        pos                = [[0, 0, 0]],
      },
    },
    glow = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 0,
      ground             = true,
      water              = true,
      properties = {
        delay              = [[0 i0.5]],
        explosiongenerator = [[custom:PARIS_GLOW]],
        pos                = [[0, 0, 0]],
      },
    },
    shere = {
      air                = true,
      class              = [[CExpGenSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        delay              = 0,
        explosiongenerator = [[custom:PARIS_SPHERE]],
        pos                = [[0, 5, 0]],
      },
    },
  },

  ["paris_gflash"] = {
    groundflash = {
      circlealpha        = 0.5,
      circlegrowth       = 60,
      flashalpha         = 0,
      flashsize          = 30,
      ttl                = 20,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.80000001192093,
        [3]  = 1,
      },
    },
  },

  ["paris_sphere"] = {
    groundflash = {
      circlealpha        = 1,
      circlegrowth       = 0,
      flashalpha         = 0.5,
      flashsize          = 60,
      ttl                = 60,
      color = {
        [1]  = 0.80000001192093,
        [2]  = 0.80000001192093,
        [3]  = 1,
      },
    },
    pikez = {
      air                = true,
      class              = [[explspike]],
      count              = 15,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.8,
        alphadecay         = 0.15,
        color              = [[1.0,1.0,0.8]],
        dir                = [[-15 r30,-15 r30,-15 r30]],
        length             = 40,
        width              = 15,
      },
    },
    sphere = {
      air                = true,
      class              = [[CSpherePartSpawner]],
      count              = 1,
      ground             = true,
      water              = true,
      properties = {
        alpha              = 0.3,
        alwaysvisible      = false,
        color              = [[0.8,0.8,1]],
        expansionspeed     = 58,
        ttl                = 10,
      },
    },
  },

}

