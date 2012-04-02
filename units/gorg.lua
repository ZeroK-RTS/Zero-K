unitDef = {
  unitname               = [[gorg]],
  name                   = [[Jugglenaut]],
  description            = [[Heavy Assault Strider]],
  acceleration           = 0.0552,
  brakeRate              = 0.1375,
  buildCostEnergy        = 12000,
  buildCostMetal         = 12000,
  builder                = false,
  buildPic               = [[GORG.png]],
  buildTime              = 12000,
  canAttack              = true,
  canManualFire          = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -5 3]],
  collisionVolumeScales  = [[70 60 65]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Mechwarrior d'Assaut]],
	description_de = [[Schwerer Sturmroboter]],
    helptext       = [[The Jugglenaut is the big daddy to the Sumo. Where its smaller cousin sported the exotic heatray, the Jugg is even more bizzare with its three gravity guns complementing a standard laser cannon. This beast is slow and expensive, but seemingly impervious to enemy fire.]],
    helptext_fr    = [[Le Jugglenaut est un quadrip?de lourd et lent, mais ?xtr?mement solide. Il est ?quip? de deux canons laser ? haute fr?quence, et d'un double laser anti gravit? de technologie Newton. Il d?cole les unit?s ennemies du sol et les ?jecte en arri?re tout en les bombardant de ses tirs. Difficilement arr?table, voire la silhouette d'un Juggernaut ? l'horizon est une des pires chose que l'on puisse apercevoir.]],
	helptext_de    = [[Der Jugglenaut ist der große Bruder des Sumos. Er besitzt im Gegensatz zu diesem keinen exotischen Heat Ray, sondern drei nicht weniger verrückte Gravitationskanonen und eine einfache Laserkanone. Dieses Biest ist langsam und teuer, aber scheinbar völlig unbeeindruckt vom feindlichen Feuer.]],
  },

  explodeAs              = [[ESTOR_BUILDINGEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 1848,
  maxDamage              = 100000,
  maxSlope               = 36,
  maxVelocity            = 0.8325,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[GORG]],
  pieceTrailCEGRange     = 1,
  pieceTrailCEGTag       = [[trail_huge]],
  seismicSignature       = 4,
  selfDestructAs         = [[ESTOR_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  --script		 = [[gorg.lua]],
  side                   = [[CORE]],
  sightDistance          = 650,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[juggle]],
  trackWidth             = 64,
  turnRate               = 233,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0.2 0 1]],
      maxAngleDif		 = 150,
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },

    {
      def                = [[GRAVITY_NEG_SPECIAL]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif		 = 150,      
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },
	
    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[-0.2 0 1]],
	  maxAngleDif		 = 150,
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },

    --{
    --  def                = [[GRASER]],
    --},		
	
  },


  weaponDefs             = {

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
	    impulse = [[-125]],
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
      range                   = 550,
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
      -- This is just a marker weapon.
	  -- When the projectile hits the ground or explodes above ground the float effect will occur.
	  -- Units fly towards the impact position of this projectile.
	  -- So the projectile can be any weapon of any speed but:
	  -- * It must be a projectile (ie no Lightning or LaserCannon)
	  -- * There must only be one
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      commandFire             = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    massliftthrow = [[1]],
	    impulse = [[-125]],
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
      projectiles             = 1,
      range                   = 550,
      reloadtime              = 20,
      renderType              = 4,
      rgbColor                = [[1 0 1]],
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


    LASER       = {
      name                    = [[Heavy Laser Blaster]],
      areaOfEffect            = 24,
      canattackground         = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 2,
      },

      duration                = 0.04,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 30,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      range                   = 430,
      reloadtime              = 0.17,
      rgbColor                = [[1 0 0]],
	  soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/heavylaser_fire2]],
      sweepfire               = false,
      targetMoveError         = 0.1,
      thickness               = 4,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1720,
    },
	
    
    FAKELASER  = {
      name                    = [[Laser]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      collideFriendly         = false,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -0.001,
        subs    = -0.001,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      range                   = 400,
      reloadtime              = 8,
      rgbColor                = [[0 0 0]],
      soundTrigger            = true,
      targetMoveError         = 0.2,
      thickness               = 0.001,
      tolerance               = 0,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2300,
    },
	
    GRASER = {
      name                    = [[Light Graser]],
      areaOfEffect			  = 8,
      beamTime                = 0.01,
	  beamttl				  = 6,
	  canAttackGround		  = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 1,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 120,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 3.5,
      minIntensity            = 1,
      range                   = 430,
      reloadtime              = 1,
      rgbColor                = [[0.1 1 0.3]],
      soundStart              = [[weapon/laser/laser_burn10]],
      soundTrigger            = true,
      sweepfire               = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 3,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },	

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Jugglenaut]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 100000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[8]],
      hitdensity       = [[100]],
      metal            = 4800,
      object           = [[GORG_DEAD]],
      reclaimable      = true,
      reclaimTime      = 4800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Jugglenaut]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 100000,
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

return lowerkeys({ gorg = unitDef })
