return { subtacmissile = {
  unitname               = [[subtacmissile]],
  name                   = [[Scylla]],
  description            = [[Tactical Nuke Missile Sub, Drains 20 m/s, 30 second stockpile]],
  acceleration           = 0.186,
  activateWhenBuilt      = true,
  brakeRate              = 1.942,
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
    modelradius    = [[15]],
    stockpiletime  = [[30]],
    stockpilecost  = [[600]],
    priority_misc  = 1, -- Medium
  },

  explodeAs              = [[BIG_UNITEX]],
  fireState              = 0,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[subtacmissile]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 3000,
  maxVelocity            = 2.79,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[UBOAT3]],
  moveState              = 0,
  noAutoFire             = false,
  objectName             = [[SUBTACMISSILE]],
  selfDestructAs         = [[BIG_UNITEX]],
  script                 = [[subtacmissile.lua]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 307,
  upright                = true,
  waterline              = 25,
  workerTime             = 0,

  weapons                = {
    --{
    --  def = [[SUB_AMD_ROCKET]],
    --},

    {
      def                = [[TACNUKE]],
      badTargetCategory  = [[SWIM LAND SUB SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {

    SUB_AMD_ROCKET = {
      name                    = [[Anti-Nuke Missile]],
      areaOfEffect            = 420,
      collideFriendly         = false,
      coverage                = 1500,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1500,
        subs    = 75,
      },

      explosionGenerator      = [[custom:ANTINUKE]],
      fireStarter             = 100,
      flightTime              = 15,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      interceptor             = 1,
      model                   = [[antinukemissile.s3o]],
      noSelfDamage            = true,
      range                   = 3000,
      reloadtime              = 12,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startVelocity           = 400,
      tolerance               = 4000,
      tracks                  = true,
      turnrate                = 65535,
      waterWeapon             = true,
      weaponAcceleration      = 400,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1300,
    },


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
        subs    = 175,
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
