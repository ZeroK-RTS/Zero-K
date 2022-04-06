return { turretaalaser = {
  unitname                      = [[turretaalaser]],
  name                          = [[Razor]],
  description                   = [[Hardened Anti-Air Laser]],
  buildCostMetal                = 280,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[turretaalaser_aoplane.dds]],
  buildPic                      = [[turretaalaser.png]],
  category                      = [[FLOAT UNARMED STUPIDTARGET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[50 36 50]],
  collisionVolumeType            = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_target  = 2,
    bait_level_target_armor = 1,
    bait_level_default = 0,
  },

  damageModifier                = 0.333,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseaa]],
  levelGround                   = false,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[aapopup.s3o]],
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  script                        = [[turretaalaser.lua]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[AAGUN]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    AAGUN = {
      name                    = [[Anti-Air Laser]],
      accuracy                = 50,
      areaOfEffect            = 8,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        
        light_camera_height = 2600,
        light_radius = 220,
      },

      damage                  = {
        default = 1.49,
        planes  = 14.9,
      },

      duration                = 0.02,
      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:flash1orange]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      proximityPriority       = 4,
      range                   = 1000,
      reloadtime              = 0.1,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      thickness               = 2.25,
      tolerance               = 1000,
      turnRate                = 48000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[aapopup_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
