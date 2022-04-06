return { turretgauss = {
  unitname                      = [[turretgauss]],
  name                          = [[Gauss]],
  description                   = [[Popup gauss turret, regenerates when closed (Anti-Sub)]],
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[gauss_aoplate.dds]],
  buildPic                      = [[turretgauss.png]],
  canMove                       = false,
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[32 65 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 1,
    bait_level_target_armor = 1,
    modelradius    = [[15]],
    midposoffset   = [[0 15 0]],
    aimposoffset   = [[0 36 0]],
    armored_regen  = [[10]],
    dynamic_colvol = [[1]],
  },

  damageModifier                = 0.333,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defense]],
  levelGround                   = false,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0, -- model-derived would be 305: 35 elmo legs + 6x45 elmo pillar segments should be enough for everyone
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[gauss.dae]],
  script                        = [[turretgauss.lua]],
  selfDestructAs                = [[SMALL_BUILDINGEX]],
 
  sfxtypes               = {
    explosiongenerators = {
      [[custom:flashmuzzle1]],
    },
  },

  sightDistance                 = 664, -- Range*1.1 + 48 for radar overshoot
  useBuildingGroundDecal        = true,
  yardmap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams = {
        burst = Shared.BURST_RELIABLE,

        single_hit = true,
      },

      damage                  = {
        default = 200.1,
        planes  = 200.1,
      },
      
      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 560,
      reloadtime              = 2.1,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 3,
      soundStart              = [[weapon/gauss_fire]],
      soundStartVolume        = 2.5,
      stages                  = 32,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1200,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[gauss_91_dead1.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
