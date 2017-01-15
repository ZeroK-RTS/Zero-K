unitDef = {
  unitname               = [[corbtrans]],
  name                   = [[Vindicator]],
  description            = [[Armed Heavy Air Transport]],
  acceleration           = 0.2,
  airStrafe              = 0,
  brakeRate              = 0.248,
  buildCostEnergy        = 500,
  buildCostMetal         = 500,
  builder                = false,
  buildPic               = [[corbtrans.png]],
  buildTime              = 500,
  canAttack              = true,
  canFly                 = true,
  canGuard               = true,
  canload                = [[1]],
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 25 100]],
  collisionVolumeType    = [[Box]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 250,

  customParams           = {
    description_fr = [[Transport Aerien Arm? Lourd]],
	description_de = [[Schwerer, bewaffneter Lufttransport]],
    helptext       = [[The Vindicator can haul any land unit in the game. Its twin laser guns and automated cargo ejection system make it ideal for drops into hot LZs.]],
    helptext_fr    = [[Le Vindicator est le summum du transport aerien. Rapide et puissant il peut transporter toutes vos unit?s sur le champ de bataille, il riposte aux tirs gr?ce ? ses multiples canons laser, et s'il est abattu, il ejecte sa livraison au sol avant d'exploser.]],
	helptext_de    = [[Der Vindicator kann jede Landeinheit im Spiel befördern. Seine doppelläufige Laserkanone und sein automatisches Frachtauswurfsystem machen ihn ideal für den Transport von Einheiten in umkämpfte Landezonen.]],
	midposoffset   = [[0 0 0]],
	aimposoffset   = [[0 10 0]],
	modelradius    = [[15]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  hoverAttack            = true,
  iconType               = [[heavygunshiptransport]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[1280]],
  maxDamage              = 1100,
  maxVelocity            = 8,
  minCloakDistance       = 75,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[largeTransport.s3o]],
  script				 = [[corbtrans.lua]],
  releaseHeld            = true,
  seismicSignature       = 0,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:VINDIMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },
  sightDistance          = 660,
  transportCapacity      = 1,
  transportSize          = 25,
  turninplace            = 0,
  turnRate               = 420,
  upright                = true,
  verticalSpeed          = 30,
  workerTime             = 0,

  weapons                = {

	{
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  mainDir            = [[-1 -1 1]],
      maxAngleDif        = 200,
    },


    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  mainDir            = [[1 -1 1]],
      maxAngleDif        = 200,
    },
	
	
	{
      def                = [[AALASER]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
      mainDir            = [[0 -1 1]],
      maxAngleDif        = 160,
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Light Laser Blaster]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        combatrange = 60,
        light_camera_height = 1200,
        light_radius = 160,
      },
      
      damage                  = {
        default = 10,
        subs    = 0.5,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      impactOnly              = true,
	  heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 325,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      thickness               = 2.4,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2400,
    },
	
    AALASER  = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,
      
      customParams        = {
        combatrange = 100,
      },

      damage                  = {
        default = 2,
        planes  = 20,
        subs    = 1,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 450,
      reloadtime              = 0.4,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.3,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
	  collisionVolumeScales  = [[60 40 80]],
	  collisionVolumeType    = [[CylZ]],
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[heavytrans_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ corbtrans = unitDef })
