unitDef = {
  unitname               = [[tankcon]],
  name                   = [[Welder]],
  description            = [[Armed Construction Tank, Builds at 7.5 m/s]],
  acceleration           = 0.066,
  brakeRate              = 1.5,
  buildCostMetal         = 200,
  buildDistance          = 180,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[tankcon.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 60 60]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
	aimposoffset   = [[0 0 0]],
	midposoffset   = [[0 -10 0]],
	modelradius    = [[30]],
  },

  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 2000,
  maxSlope               = 18,
  maxVelocity            = 2.1,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[welder.s3o]],
  script                 = [[tankcon.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  showNanoSpray          = false,
  sightDistance          = 300,
  trackOffset            = 3,
  trackStrength          = 6,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 38,
  turninplace            = 0,
  turnRate               = 625,
  workerTime             = 7.5,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Mini Laser]],
      areaOfEffect            = 8,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1200,
		light_radius = 120,
      },

      damage                  = {
        default = 9,
        planes  = 9,
        subs    = 0.7,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      thickness               = 2.5,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[welder_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ tankcon = unitDef })
