return { jumpscout = {
  unitname               = [[jumpscout]],
  name                   = [[Puppy]],
  description            = [[Walking Missile]],
  acceleration           = 0.72,
  activateWhenBuilt      = true,
  brakeRate              = 4.32,
  buildCostMetal         = 45,
  builder                = false,
  buildPic               = [[jumpscout.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 28]],
  selectionVolumeType    = [[ellipsoid]],

  customParams           = {
    bait_level_default = 1,
    modelradius    = [[10]],
    
    grey_goo = 1,
    grey_goo_spawn = "jumpscout",
    grey_goo_drain = 5,
    grey_goo_cost = 45,
    grey_goo_range = 120,
    jump_using_weapon = 1, -- Value is weapon number
    jump_self_damage = 15,
    selection_scale = 1, -- Maybe change later
    select_show_eco = 1,
  },

  explodeAs              = [[TINY_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotbomb]],
  leaveTracks            = true,
  maxDamage              = 80,
  maxSlope               = 36,
  maxVelocity            = 3.5,
  maxWaterDepth          = 15,
  movementClass          = [[SKBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING]],
  objectName             = [[puppy.s3o]],
  script                 = [[jumpscout.lua]],
  selfDestructAs         = [[TINY_BUILDINGEX]],
  selfDestructCountdown  = 5,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:digdig]],
    },

  },
  sightDistance          = 640,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.6,
  trackType              = [[ComTrack]],
  trackWidth             = 12,
  turnRate               = 2160,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    MISSILE = {
      name                    = [[Legless Puppy]],
      areaOfEffect            = 40,
      cegTag                  = [[VINDIBACK]],
      craterBoost             = 1,
      craterMult              = 2,

            customParams = {
                burst = Shared.BURST_RELIABLE,
            },

      damage                  = {
        default = 410.1,
        planes  = 410.1,
      },

      fireStarter             = 70,
      flightTime              = 0.8,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[puppymissile.s3o]],
      noSelfDamage            = true,
      range                   = 170,
      reloadtime              = 1.5,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startVelocity           = 300,
      tracks                  = true,
      turnRate                = 56000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2a.s3o]],
    },
    
    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },
  
} }
