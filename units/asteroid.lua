return { asteroid = {
  name                          = [[Asteroid]],
  description                   = [[Space Rock]],
  builder                       = false,
  buildPic                      = [[asteroid.png]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],
  footprintX                    = 2,
  footprintZ                    = 2,
  health                        = 500,
  isFeature                     = true,
  levelGround                   = false,
  maxSlope                      = 255,
  maxWaterDepth                 = 0,
  metalCost                     = 50,
  objectName                    = [[asteroid.s3o]],
  script                        = [[asteroid.lua]],
  sightDistance                 = 1,
  upright                       = false,
  workerTime                    = 0,
  yardMap                       = [[ff ff]],

  customParams        = {
  },

  featureDefs                   = {

    DEAD = {
      description      = [[Asteroid]],
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[asteroid.s3o]],
    },
    
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },
    

  },

} }
