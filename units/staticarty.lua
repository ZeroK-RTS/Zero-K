return { staticarty = {
  unitname                      = [[staticarty]],
  name                          = [[Cerberus]],
  description                   = [[Plasma Artillery Battery - Power by connecting to a 50 energy grid]],
  activateWhenBuilt             = true,
  buildCostMetal                = 2500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 8,
  buildingGroundDecalType       = [[staticarty_aoplane.dds]],
  buildPic                      = [[staticarty.png]],
  category                      = [[SINK]],
  corpse                        = [[DEAD]],

  customParams                  = {
    keeptooltip = [[any string I want]],
    neededlink  = 50,
    pylonrange  = 50,
    aimposoffset   = [[0 26 0]],
    midposoffset   = [[0 10 0]],
    bait_level_default = 1,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 5,
  highTrajectory                = 2,
  iconType                      = [[staticarty]],
  maxDamage                     = 3750,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[corbhmth.s3o]],
  onoffable                     = false,
  script                        = [[staticarty.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  
  sfxtypes               = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooo ooooo ooooo ooooo ooooo]],

  weapons                       = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs                    = {

    PLASMA = {
      name                    = [[Long-Range Plasma Battery]],
      areaOfEffect            = 192,
      avoidFeature            = false,
      avoidGround             = true,
      burst                   = 3,
      burstRate               = 0.133,
      craterBoost             = 1,
      craterMult              = 2,

      customParams            = {
        light_color = [[1.4 0.8 0.3]],
      },

      damage                  = {
        default = 601,
        planes  = 601,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:330rlexplode]],
      fireStarter             = 120,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      mygravity               = 0.1,
      range                   = 1850,
      reloadtime              = 10,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[explosion/ex_large5]],
      sprayangle              = 1024,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },


  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[corbhmth_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
