unitDef = {
  unitname               = [[a_shipcorvette]],
  name                   = [[Corsair]],
  description            = [[Corvette (Heavy Raider)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildAngle             = 16384,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,
  builder                = false,
  buildPic               = [[CORESUPP.png]],
  buildTime              = 200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[32 32 102]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[This Corvette comes equipped with two shotguns which are effective against anything which gets close.]],
	extradrawrange = 420,
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shipcorvette]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 200,
  maxDamage              = 1350,
  maxVelocity            = 3.3,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName             = [[vette.s3o]],
  script				 = [[a_shipcorvette.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],
  side                   = [[ARM]],
  sightDistance          = 500,
  
  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
    },

  },
  
  smoothAnim             = true,
  sonarDistance          = 500,
  turninplace            = 0,
  turnRate               = 500,
  waterline              = 0,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SHOTGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SHOTGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    SHOTGUN = {
	name                    = [[Shotgun]],
	areaOfEffect            = 64,
	burst					= 4,
	burstRate				= 0.03,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	damage                  = {
		default = 32,
		planes  = 32,
		subs    = 1.6,
	},
	
	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
	fireStarter             = 50,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	projectiles				= 4,
	range                   = 320,
	reloadtime              = 2,
	rgbColor                = [[1 1 0]],
	soundHit                = [[impacts/shotgun_impactv5]],
	soundStart              = [[weapon/cannon/cannon_fire4]],
	soundStartVolume		= 0.05,
	soundTrigger            = true,
	sprayangle				= 3600,
	thickness               = 2,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
   },
	
	
  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[vette_dead.s3o]],
    },
    
    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ a_shipcorvette = unitDef })
