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
      def                = [[TELEPORT_GUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    TELEPORT_GUN = {
      name                    = [[Unit Launcher]],
      accuracy                = 350,
      areaOfEffect            = 300,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 100,
      craterMult              = 2,

	  customParams            = {
		light_color = [[0 0.5 1]],
		light_radius = 500,
	  },
	  
      damage                  = {
        default = 0,
      },

      explosionGenerator      = [[custom:black_hole_long]],
      explosionSpeed          = 50,
      impulseBoost            = 150,
      impulseFactor           = -2.5,
	  intensity               = 0.9,
      interceptedByShieldType = 1,
      projectiles             = 1,
      range                   = 600,
      reloadtime              = 6,
      rgbColor                = [[0.05 0.45 0.95]],
      size                    = 16,
      soundHit                = [[weapon/blackhole_impact]],
      soundStart              = [[weapon/blackhole_fire]],
      soundStartVolume        = 6000,
      soundHitVolume          = 6000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
      waterweapon			  = true,
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
