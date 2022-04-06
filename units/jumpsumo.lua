return { jumpsumo = {
  unitname            = [[jumpsumo]],
  name                = [[Jugglenaut]],
  description         = [[Heavy Riot Jumper]],
  acceleration        = 0.3,
  activateWhenBuilt   = true,
  brakeRate           = 1.8,
  buildCostMetal      = 1700,
  builder             = false,
  buildPic            = [[jumpsumo.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets  = [[0 0 0]],
  collisionVolumeScales   = [[64 64 64]],
  collisionVolumeType     = [[ellipsoid]],
  selectionvolumeoffsets  = [[0 -16 0]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 0,
    can_target_allies  = 1,
    canjump            = 1,
    jump_range         = 360,
    jump_height        = 110,
    jump_speed         = 6,
    jump_delay         = 30,
    jump_reload        = 15,
    jump_from_midair   = 0,
    jump_rotate_midair = 0,
    aimposoffset   = [[0 6 0]],
    midposoffset   = [[0 6 0]],
    modelradius    = [[32]],
    lookahead      = 120,
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[t3jumpjetriot]],
  leaveTracks         = true,
  losEmitHeight       = 60,
  maxDamage           = 13500,
  maxSlope            = 36,
  maxVelocity         = 1.15,
  maxWaterDepth       = 22,
  movementClass       = [[KBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[m-9.s3o]],
  onoffable           = true,
  script              = [[jumpsumo.lua]],
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:sumosmoke]],
      [[custom:BEAMWEAPON_MUZZLE_ORANGE]],
    },

  },
  sightDistance       = 480,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[crossFoot]],
  trackWidth          = 66,
  turnRate            = 600,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[FAKELASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 30,
    },
    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
      mainDir            = [[-1 0 0]],
      maxAngleDif        = 222,
    },
    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 222,
    },
    {
      def                = [[GRAVITY_POS]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
      mainDir            = [[-1 0 0]],
      maxAngleDif        = 222,
    },
    {
      def                = [[GRAVITY_POS]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 222,
    },
    {
      def                = [[LANDING]],
      badTargetCategory  = [[]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[]],
    },
  },


  weaponDefs          = {

    FAKELASER     = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 0,
      },

      duration                = 0.1,
      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5.53,
      minIntensity            = 1,
      noSelfDamage            = true,
      proximityPriority       = 10,
      range                   = 440,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn5]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 900,
    },

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.033,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        impulse = [[-150]],

        light_color = [[0.33 0.33 1.28]],
        light_radius = 140,
      },

      damage                  = {
        default = 0.001,
        planes  = 0.001,
      },

      duration                = 0.0333,
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      proximityPriority       = -15,
      range                   = 440,
      reloadtime              = 0.2,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },


    GRAVITY_POS = {
      name                    = [[Repulsive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.033,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        impulse = [[150]],

        light_color = [[0.85 0.2 0.2]],
        light_radius = 140,
      },

      damage                  = {
        default = 0.001,
        planes  = 0.001,
      },

      duration                = 0.0333,
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      proximityPriority       = 15,
      range                   = 440,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },

    LANDING = {
      name                    = [[Jugglenaut Landing]],
      areaOfEffect            = 340,
      canattackground         = false,
      craterBoost             = 4,
      craterMult              = 6,

      damage                  = {
        default = 1001.1,
        planes  = 1001.1,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
      impulseBoost            = 0.5,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 5,
      reloadtime              = 13,
      soundHit                = [[krog_stomp]],
      soundStart              = [[krog_stomp]],
      soundStartVolume        = 3,
      turret                  = false,
      weaponType              = [[Cannon]],
      weaponVelocity          = 5,

      customParams            = {
        hidden = true
      }
    },

  },


  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[m-9_wreck.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
