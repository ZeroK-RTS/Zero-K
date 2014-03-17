unitDef = {
  unitname               = [[jumpblackhole2]],
  name                   = [[Hoarder]],
  description            = [[Assault/Riot Bot]],
  acceleration           = 0.35,
  brakeRate              = 0.35,
  buildCostEnergy        = 500,
  buildCostMetal         = 500,
  buildPic               = [[cormak.png]],
  buildTime              = 500,
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
    description_pl = [[Wyrzutnia czarnych dziur]],
    helptext       = [[The Hoarder is a riot/assault unit. It generates a vacuum that sucks in nearby units, clustering and holding them in place to help finish them off.]],
    helptext_pl    = [[Pociski Placeholdera zasysaja i utrzymuja w miejscu okoliczne jednostki, co pozwala je skutecznie wykonczyc.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotwideriot]],
  idleAutoHeal           = 30,
  idleTime               = 150,
  leaveTracks            = true,
  mass                   = 2570,
  maxDamage              = 3000,
  maxSlope               = 36,
  maxVelocity            = 2.1,
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
      areaOfEffect            = 240,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 8,
        planes  = 8,
        subs    = 0.1,
      },

      customParams           = {
	    nofriendlyfire = 1,
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      explosionSpeed          = 11,
      impulseBoost            = 0,
      impulseFactor           = -15,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 50,
      reloadtime              = 0.2,
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
        default = 4,
        planes  = 4,
        subs    = 5E-08,
      },

      customParams           = {
	    nofriendlyfire = 1,
	    falldamageimmunity = [[30]],
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = false,
      impulseBoost            = 0,
      impulseFactor           = -30,
      interceptedByShieldType = 1,
      range                   = 300,
      reloadtime              = 0.2,
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

    FAKEGUN2 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 300,
	  avoidFriendly			  = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 4,
        planes  = 4,
        subs    = 5E-08,
      },

      customParams           = {
	    nofriendlyfire = 1,
	    falldamageimmunity = [[30]],
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = false,
      interceptedByShieldType = 1,
      range                   = 300,
      impulseBoost            = 0,
      impulseFactor           = -30,
      reloadtime              = 0.2,
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
      description      = [[Wreckage - Placeholder2]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 3000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[m-5_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

	
    HEAP  = {
      description      = [[Debris - Placeholder2]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 3000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ jumpblackhole2 = unitDef })
