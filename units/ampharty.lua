unitDef = {
  unitname               = [[ampharty]],
  name                   = [[Kraken]],
  description            = [[Amphibious Skirmisher/Artillery Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostMetal         = 240,
  buildPic               = [[ampharty.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 10,
    amph_submerged_at = 40,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphtorpskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 440,
  maxSlope               = 36,
  maxVelocity            = 1.8,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[behecrash.s3o]],
  script                 = [[ampharty.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  sightDistance          = 660,
  sonarDistance          = 380,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1000,
  upright                = true,

  weapons                = {
    {
      def                = [[GRENADE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

	GRENADE = {
      name                    = [[Grenade Launcher]],
      accuracy                = 200,
      areaOfEffect            = 48,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 80,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      fireStarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      model                   = [[diskball.s3o]],
      projectiles             = 2,
      range                   = 680,
      reloadtime              = 3,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      soundStartVolume        = 2,
      soundTrigger			= true,
      sprayangle              = 512,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
	},

	TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 70,
        subs    = 70,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      flightTime              = 6,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[diskball.s3o]],
      noSelfDamage            = true,
      range                   = 440,
      reloadtime              = 1.5,
      soundHit                = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torpedofast]],
      startVelocity           = 120,
      tolerance               = 1000,
      tracks                  = false,
      turnRate                = 100000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 25,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 180,
    },

  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[behecrash_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ ampharty = unitDef })
