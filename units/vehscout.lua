unitDef = {
  unitname               = [[vehscout]],
  name                   = [[Dart]],
  description            = [[Raider/Scout Vehicle]],
  acceleration           = 0.14,
  brakeRate              = 0.1555,
  buildCostMetal         = 35,
  builder                = false,
  buildPic               = [[vehscout.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 0 2]],
  collisionVolumeScales  = [[14 14 40]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
	modelradius    = [[7]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[vehiclescout]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 120,
  maxSlope               = 18,
  maxVelocity            = 5.09,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK2]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[vehscout.s3o]],
  script                 = [[vehscout.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  sightDistance          = 580,
  trackOffset            = 0,
  trackStrength          = 4,
  trackStretch           = 1,
  trackType              = [[Motorbike]],
  trackWidth             = 24,
  turninplace            = 0,
  turnRate               = 1097,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Laser]],
      areaOfEffect            = 8,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1000,
      },

      damage                  = {
        default = 55,
        planes  = 55,
        subs    = 3,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:beamweapon_hit_yellow_small]],
      fireStarter             = 50,
	  hardStop                = false,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 180,
      reloadtime              = 1,
      rgbColor                = [[1 1 0]],
      soundStart              = [[weapon/laser/small_laser_fire]],
      soundTrigger            = true,
      thickness               = 5.3619026473818,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1800,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[vehscout_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ vehscout = unitDef })
