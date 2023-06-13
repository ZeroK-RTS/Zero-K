return { subtacmissile = {
  unitname               = [[subtacmissile]],
  name                   = [[Scylla]],
  description            = [[Tactical Nuke Missile Sub, Drains 20 m/s, 30 second stockpile]],
  acceleration           = 0.223,
  activateWhenBuilt      = true,
  brakeRate              = 2.33,
  buildCostMetal         = 3000,
  builder                = false,
  buildPic               = [[subtacmissile.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SUB SINK]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[30 25 110]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[15]],
    stockpiletime  = [[30]],
    stockpilecost  = [[600]],
    priority_misc  = 1, -- Medium
    no_auto_keep_target = 1,

    outline_x = 160,
    outline_y = 160,
    outline_yoff = 12,
  },

  explodeAs              = [[BIG_UNITEX]],
  fireState              = 0,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[subtacmissile]],
  maxDamage              = 3000,
  maxVelocity            = 2.79,
  minWaterDepth          = 15,
  movementClass          = [[UBOAT3]],
  moveState              = 0,
  noAutoFire             = false,
  objectName             = [[subtacmissile.s3o]],
  selfDestructAs         = [[BIG_UNITEX]],
  script                 = [[subtacmissile.lua]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 491,
  upright                = true,
  waterline              = 55,
  workerTime             = 0,

  weapons                = {
    {
      def                = [[TACNUKE]],
      badTargetCategory  = [[SWIM LAND SUB SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },
  },

  weaponDefs             = {
    TACNUKE        = {
      name                    = [[Tactical Nuke]],
      areaOfEffect            = 256,
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 4,
      craterMult              = 3.5,

      customParams = {
        burst = Shared.BURST_RELIABLE,
      },

      damage                  = {
        default = 3502.4,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:NUKE_150]],
      fireStarter             = 0,
      flightTime              = 10,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_tacnuke.s3o]],
      noSelfDamage            = true,
      range                   = 3000,
      reloadtime              = 1,
      smokeTrail              = true,
      soundHit                = [[explosion/mini_nuke]],
      soundStart              = [[weapon/missile/tacnuke_launch]],
      stockpile               = true,
      stockpileTime           = 10^5,
      tolerance               = 4000,
      turnrate                = 18000,
      waterWeapon             = true,
      weaponAcceleration      = 180,
      weaponTimer             = 4,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1200,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[subtacmissile_dead.s3o]],
      collisionVolumeOffsets = [[0 -5 0]],
      collisionVolumeScales  = [[30 25 110]],
      collisionVolumeType    = [[box]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
