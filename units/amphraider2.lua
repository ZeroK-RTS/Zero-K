unitDef = {
  unitname               = [[amphraider2]],
  name                   = [[Archer]],
  description            = [[Amphibious Raider/Skirmish Bot (Land)]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 260,
  buildCostMetal         = 260,
  buildPic               = [[amphraider2.png]],
  buildTime              = 260,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext	 = [[The Archer uses a powerful water cutting jet to hit enemies. While the water cannon loses firepower and range as its water tank empties, it can be refilled by standing in a body of water.]],
    maxwatertank = [[180]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 800,
  maxSlope               = 36,
  maxVelocity            = 2.3,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[amphraider2.s3o]],
  script                 = [[amphraider2.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:watercannon_muzzle]],
    },
  },

  sightDistance          = 500,
  sonarDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[WATERCANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    WATERCANNON = {
      name                    = [[Water Cannon]],
      alphaDecay              = 0,
      areaOfEffect            = 16,
      burst		     		  = 3,
      burstRate		          = 0.03,
      --cegTag		      = [[torpedo_trail]],
      --colormap                = [[0.6 0.8 1 1 0.6 0.8 1 1]],
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    impulse = [[20]],
		normaldamage = [[1]],
	  },

      damage                  = {
        default = 0.7,
        planes  = 0.7,
        subs    = 0.01,
      },

      explosionGenerator      = [[custom:none]], --watercannon_impact
      intensity               = 0.7,
      interceptedByShieldType = 1,
      myGravity		          = 0.65,
      noGap                   = false,
      noSelfDamage            = true,
      projectiles	          = 6,
	  proximityPriority       = 4,
      range                   = 400,
      reloadtime              = 0.1,
      rgbColor                = [[0.6 0.8 1]],
      rgbColor2               = [[0.6 0.8 1]],
      separation              = 2.5,
      stages		          = 5,
      --size                  = 0,
      sizeDecay               = 0,
      --soundStart            = [[weapon/hiss]],
      soundStartVolume        = 4,
      soundTrigger	          = true,
      targetBorder	          = true,
      texture1	              = [[wake]],
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 650,
    },

  },

  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Archer]],
      blocking         = true,
      damage           = 800,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 104,
      object           = [[amphraider2_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
    },

    HEAP      = {
      description      = [[Debris - Archer]],
      blocking         = false,
      damage           = 800,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 52,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
    },

  },

}

return lowerkeys({ amphraider2 = unitDef })
