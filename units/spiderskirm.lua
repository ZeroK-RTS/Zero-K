return { spiderskirm = {
  unitname               = [[spiderskirm]],
  name                   = [[Recluse]],
  description            = [[Skirmisher Spider (Indirect Fire)]],
  acceleration           = 0.78,
  brakeRate              = 4.68,
  buildCostMetal         = 280,
  buildPic               = [[spiderskirm.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    midposoffset   = [[0 -5 0]],
    aim_lookahead  = 160,
    bait_level_default = 0,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderskirm]],
  leaveTracks            = true,
  maxDamage              = 650,
  maxSlope               = 72,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SATELLITE SUB]],
  objectName             = [[recluse.s3o]],
  script                 = [[spiderskirm.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 627,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 52,
  turnRate               = 1680,

  weapons                = {

    {
      def                = [[ADV_ROCKET]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs             = {

    ADV_ROCKET = {
      name                    = [[Rocket Volley]],
      areaOfEffect            = 48,
      burst                   = 3,
      burstrate               = 0.3,
      cegTag                  = [[rocket_trail_bar]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 2500,
        light_color = [[0.90 0.65 0.30]],
        light_radius = 250,
      },

      damage                  = {
        default = 135,
        planes  = 135,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 70,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[recluse_missile.s3o]],
      noSelfDamage            = true,
      predictBoost            = 0.75,
      range                   = 570,
      reloadtime              = 4,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_small13]],
      soundStart              = [[weapon/missile/missile_fire4]],
      soundTrigger            = true,
      startVelocity           = 150,
      trajectoryHeight        = 1.5,
      turnRate                = 4000,
      turret                  = true,
      weaponAcceleration      = 150,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
      wobble                  = 9000,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[50 30 50]],
      collisionVolumeType    = [[ellipsoid]],
      object           = [[recluse_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
