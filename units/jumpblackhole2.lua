unitDef = {
  unitname               = [[jumpblackhole2]],
  name                   = [[Hoarder]],
  description            = [[Assault/Riot Bot]],
  acceleration           = 0.35,
  brakeRate              = 1.05,
  buildCostMetal         = 100,
  buildPic               = [[cormak.png]],
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Robot ?meurier]],
    description_de = [[Riot Roboter]],
    helptext       = [[The Hoarder is a riot/assault unit. It generates a vacuum that sucks in nearby units, clustering and holding them in place to help finish them off.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotwideriot]],
  idleAutoHeal           = 30,
  idleTime               = 150,
  leaveTracks            = true,
  maxDamage              = 3000,
  maxSlope               = 36,
  maxVelocity            = 2.1,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[behethud.s3o]],
  onoffable              = true,
  selfDestructAs         = [[BIG_UNITEX]],
  script                 = [[cormak.lua]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RIOTBALL]],
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RIOT_SHELL_L]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  sightDistance          = 347,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1400,
  upright                = true,

  weapons                = {

    {
      def                = [[FAKEGUN1]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

    {
      def                = [[BLAST]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

    {
      def                = [[FAKEGUN2]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    BLAST    = {
      name                    = [[Disruptor Pulser]],
      areaOfEffect            = 220,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 400,
        planes  = 400,
        subs    = 0.1,
      },

      customParams           = {
	    nofriendlyfire = 1,
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:beamerray]],
      explosionSpeed          = 11,
      impulseBoost            = 0,
      impulseFactor           = -0,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 4,
      soundHitVolume          = 1,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },

    FAKEGUN1 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 300,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        planes  = 0,
        subs    = 0,
      },

      customParams           = {
	    nofriendlyfire = 1,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = false,
      impulseBoost            = 0,
      impulseFactor           = -0,
      interceptedByShieldType = 1,
      range                   = 400,
      reloadtime              = 4,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 400,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

    FAKEGUN2 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 300,
	  avoidFriendly			  = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        planes  = 0,
        subs    = 0,
      },

      customParams           = {
	    nofriendlyfire = 1,
	    falldamageimmunity = [[30]],
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = false,
      interceptedByShieldType = 1,
      range                   = 400,
      impulseBoost            = 0,
      impulseFactor           = -0,
      reloadtime              = 4,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 400,
      weaponTimer             = 0.0,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },

  },

  featureDefs           = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[m-5_dead.s3o]],
    },

	
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ jumpblackhole2 = unitDef })
