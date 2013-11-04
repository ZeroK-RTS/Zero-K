unitDef = {
  unitname               = [[cormak]],
  name                   = [[Outlaw]],
  description            = [[Riot Bot]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,
  buildPic               = [[cormak.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô dispersador]],
    description_es = [[Robot de alboroto]],
    description_fr = [[Robot ?meurier]],
    description_it = [[Robot da rissa]],
    description_de = [[Riot Roboter]],
    helptext       = [[The Outlaw emits an electromagnetic disruption pulse in a wide circle around it that damages and slows enemy units. Friendly units are unaffected.]],
    helptext_de    = [[Der Outlaw stößt einen elektromagnetischen Störungspuls, in einem weiten Kreis um sich herum, aus, welcher feindliche Einheiten schädigt und verlangsamt. Freundliche Einheiten sind davon aber nicht betroffen.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1050,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[behethud.s3o]],
  onoffable              = true,
  seismicSignature       = 4,
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
  turnRate               = 2000,
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
      areaOfEffect            = 550,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 0.1,
      },

      customParams           = {
	    lups_explodespeed = 1,
	    lups_explodelife = 0.6,
	    nofriendlyfire = 1,
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      explosionSpeed          = 11,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.95,
      soundHitVolume          = 1,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },

    FAKEGUN1 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 32,
      reloadtime              = 0.95,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },

    FAKEGUN2 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
	  avoidFriendly			  = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 300,
      reloadtime              = 0.95,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Outlaw]],
      blocking         = true,
      damage           = 1050,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 100,
      object           = [[behethud_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
    },

    HEAP  = {
      description      = [[Debris - Outlaw]],
      blocking         = false,
      damage           = 1050,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 50,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
    },

  },

}

return lowerkeys({ cormak = unitDef })
