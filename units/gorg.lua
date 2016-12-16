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
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[70 60 65]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Mechwarrior d'Assaut]],
	description_de = [[Schwerer Sturmroboter]],
    helptext       = [[The Jugglenaut is the big daddy to the Sumo. Where its smaller cousin sported the exotic disruptor beams, the Jugg is even more bizzare with its three gravity guns and a standard laser cannon complementing a negative gravity core that can be activated to lift up and throw nearby units. This beast is slow and expensive, but seemingly impervious to enemy fire.]],
    helptext_fr    = [[Le Jugglenaut est un quadrip?de lourd et lent, mais ?xtr?mement solide. Il est ?quip? de deux canons laser ? haute fr?quence, et d'un double laser anti gravit? de technologie Newton. Il d?cole les unit?s ennemies du sol et les ?jecte en arri?re tout en les bombardant de ses tirs. Difficilement arr?table, voire la silhouette d'un Juggernaut ? l'horizon est une des pires chose que l'on puisse apercevoir.]],
	helptext_de    = [[Der Jugglenaut ist der gro�e Bruder des Sumos. Er besitzt im Gegensatz zu diesem keinen exotischen Heat Ray, sondern drei nicht weniger verr�ckte Gravitationskanonen und eine einfache Laserkanone. Dieses Biest ist langsam und teuer, aber scheinbar v�llig unbeeindruckt vom feindlichen Feuer.]],
    extradrawrange = 260,
	modelradius    = [[30]],
  },

  explodeAs              = [[ESTOR_BUILDINGEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
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
  sightDistance          = 650,
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
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      projectiles             = 2,
      proximityPriority       = -15,
      range                   = 550,
      reloadtime              = 0.2,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
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
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 550,
      reloadtime              = 40,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
	  size                    = 0,
	  stages                  = 1,
	  tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
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
      thickness               = 0.001,
      tolerance               = 0,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2300,
    },
	
    GRASER = {
      name                    = [[Light Graser]],
      areaOfEffect			  = 8,
      beamTime                = 1/30,
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[GORG_DEAD]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ gorg = unitDef })
