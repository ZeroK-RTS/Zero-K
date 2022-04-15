return { turretemp = {
  unitname                      = [[turretemp]],
  name                          = [[Faraday]],
  description                   = [[EMP Turret]],
  buildCostMetal                = 260,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[turretemp_aoplane.dds]],
  buildPic                      = [[turretemp.png]],
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 75 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 1,
    bait_level_target_armor = 1,
    aimposoffset   = [[0 12 0]],
    modelradius    = [[16]],
    aim_lookahead  = 50,
    dynamic_colvol = [[1]],

    outline_x = 64,
    outline_y = 95,
    outline_yoff = 32,
  },

  damageModifier                = 0.333,
  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defensespecial]],
  levelGround                   = false,
  maxDamage                     = 1600,
  maxSlope                      = 36,
  maxWaterDepth                 = 0,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[armartic.s3o]],
  script                        = [[turretemp.lua]],
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  sightDistance                 = 554, -- Range*1.1 + 48 for radar overshoot
  useBuildingGroundDecal        = true,
  yardMap                       = [[oo oo]],

  weapons                       = {

    {
      def                = [[arm_det_weapon]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs                    = {

    arm_det_weapon = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 160,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 0,
      
      customParams            = {
        light_color = [[0.75 0.75 0.56]],
        light_radius = 220,
      },

      damage                  = {
        default = 1100,
      },

      duration                = 8,
      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 2,
      range                   = 460,
      reloadtime              = 2.9,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[armartic_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
