return { staticradar = {
  unitname                      = [[staticradar]],
  name                          = [[Radar Tower]],
  description                   = [[Early Warning System]],
  activateWhenBuilt             = true,
  buildCostMetal                = 55,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticradar_aoplane.dds]],
  buildPic                      = [[staticradar.png]],
  canMove                       = true, -- for queuing orders during morph to mobile
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 -32 0]],
  collisionVolumeScales         = [[32 90 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],
  
  customParams = {
    morphto        = [[planelightscout]],
    morphtime      = 24,
    modelradius    = [[16]],
    priority_misc  = 2, -- High
    addfight       = 1,
    addpatrol      = 1,

    outline_x = 90,
    outline_y = 125,
    outline_yoff = 35,

    outline_sea_x = 90,
    outline_sea_y = 160,
    outline_sea_yoff = 20,
  },
  
  energyUse                     = 0.8,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[radar]],
  levelGround                   = false,
  maxDamage                     = 80,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[ARADARLVL1.s3o]],
  script                        = [[staticradar.lua]],
  onoffable                     = true,
  radarDistance                 = 2100,
  radarEmitHeight               = 32,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 800,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],
  
    sfxtypes               = {

    explosiongenerators = {
      [[custom:scanner_ping]]
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[ARADARLVL1_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
