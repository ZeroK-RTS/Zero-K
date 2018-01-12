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
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  highTrajectory         = 2,
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
      [[custom:thrower_shockwave]],
    },
  },

  sightDistance          = 660,
  sonarDistance          = 380,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 28,
  turnRate               = 1000,
  upright                = true,

  weapons                = {
    {
      def                = [[TELEPORT_GUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    TELEPORT_GUN = {
      name                    = [[Unit Launcher]],
      accuracy                = 350,
      areaOfEffect            = 220, -- UI
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
		lups_noshockwave = [[1]],
	  },
	  
      damage                  = {
        default = 0,
      },

      explosionSpeed          = 50,
	  intensity               = 0.9,
      interceptedByShieldType = 1,
      projectiles             = 1,
      range                   = 600,
      reloadtime              = 6,
      rgbColor                = [[0.05 0.45 0.95]],
      size                    = 0.005,
      soundStart              = [[weapon/blackhole_fire]],
      soundStartVolume        = 6000,
      soundHitVolume          = 6000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
      waterweapon             = true,
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
