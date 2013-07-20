unitDef = {
  unitname               = [[funnelweb]],
  name                   = [[Funnelweb]],
  description            = [[Very Heavy Support Spider]],
  acceleration           = 0.0552,
  activateWhenBuilt      = true,
  autoheal				 = 20,
  brakeRate              = 0.1375,
  buildCostEnergy        = 6000,
  buildCostMetal         = 6000,
  buildPic               = [[funnelweb.png]],
  buildTime              = 6000,
  canAttack              = true,
  canGuard               = true,
  canManualFire          = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -3 -5]],
  collisionVolumeScales  = [[70 60 85]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[The slow all-terrain Funnelweb is only (relatively) modestly armed and can only fire forwards, but features a powerful area shield and drone complement in addition to its unique gravity toss ability.]],
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 1848,
  maxDamage              = 16000,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[funnelweb.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
    },

  },
  script				 = [[funnelweb.lua]],
  side                   = [[CORE]],
  sightDistance          = 650,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 64,
  turnRate               = 240,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
	  maxAngleDif		 = 60,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif		 = 120,
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },	
	
    {
      def                = [[GRAVITY_NEG_SPECIAL]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	

    {
      def                = [[SHIELD]],
    },	
	
  },


  weaponDefs             = {

    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 2,
      burstrate               = 0.4,
      cegTag                  = [[gauss_tag_h]],
	  
	  customParams            = {
	    single_hit = [[1]],
	  },
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 400,
        planes  = 400,
        subs    = 20,
      },

      explosionGenerator      = [[custom:gauss_hit_h]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      minbarrelangle          = [[-15]],
      noExplode               = true,
      numbounce               = 40,
      range                   = 700,
      reloadtime              = 3,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 800,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2400,
    },
	
    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    impulse = [[-140]],
	  },
	  
      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      projectiles             = 2,
      proximityPriority       = -15,
      range                   = 400,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2750,
    },
	
    GRAVITY_NEG_SPECIAL = {
      name                    = [[Psychic Tank Float]],
      accuracy                = 10,
      alphaDecay              = 0.7,
      areaOfEffect            = 2,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideEnemy            = false,
      collideFeature          = false,
      collideFriendly         = false,
      collideGround           = false,
      collideNeutral          = false,
      burnblow                = true,
      craterBoost             = 0.15,
      craterMult              = 0.3,
      commandFire             = true,
	  
	  customParams            = {
	    massliftthrow = [[1]],
	  },
	  
      damage                  = {
        default = 0.01,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:GRAV]],
      lineOfSight             = true,
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 550,
      reloadtime              = 20,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
	  size                    = 0,
	  stages                  = 1,
      targetMoveError         = 0,
	  tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

    SHIELD = {
      name                    = [[Energy Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 10500,
      shieldPowerRegen        = 120,
      shieldPowerRegenEnergy  = 24,
      shieldRadius            = 400,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },	
	
  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Funnelweb]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 14000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[8]],
      hitdensity       = [[100]],
      metal            = 2400,
      object           = [[funnelweb_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 2400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Funnelweb]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 14000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[2]],
      hitdensity       = [[100]],
      metal            = 2400,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 2400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ funnelweb = unitDef })
