unitDef = {
  unitname               = [[a_shipcorvette]],
  name                   = [[Corsair]],
  description            = [[Corvette (Antiair/Heavy Raider)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildAngle             = 16384,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,
  builder                = false,
  buildPic               = [[destroyer.png]],
  buildTime              = 200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 0 3]],
  collisionVolumeScales  = [[32 46 102]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[The Corsair packs a shotgun effective against torpedo boats and light defences, and a light anti-air missile battery. It is defenseless against enemy submarines.]],
	extradrawrange = 420,
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shipcorvette]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 200,
  maxDamage              = 1150,
  maxVelocity            = 3.4,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName             = [[destroyer.s3o]],
  script				 = [[a_shipcorvette.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],
  side                   = [[ARM]],
  sightDistance          = 500,
  
  sfxtypes               = {

    explosiongenerators = {
	  [[custom:LARGE_MUZZLE_FLASH_FX]],
      [[custom:PULVMUZZLE]],
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
      def                = [[MISSILE]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
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
	
	customParams			= {
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_L]],
	},
	
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
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/cannon/cannon_fire4]],
	soundStartVolume		= 0.6,
	soundTrigger            = true,
	sprayangle				= 3600,
	thickness               = 2,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
   },
	
	MISSILE      = {
      name                    = [[Corvette AA Missiles]],
      areaOfEffect            = 48,
	  canattackground         = false,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,
	  
	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 14,
        planes  = 140,
        subs    = 7,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 100,
	  fixedLauncher			  = true,	  
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      range                   = 320,
      reloadtime              = 2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/missile_fire12]],
      soundStart              = [[weapon/missile/missile_fire10]],
      startVelocity			  = 100,
      tolerance               = 4000,
	  tracks				  = true,
	  turnrate				  = 30000,
	  turret				  = true,	  
	  waterWeapon			  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1800,
    },
  },


  featureDefs            = {

    DEAD  = {
      blocking         = false,
	  collisionVolumeOffsets = [[0 0 3]],
	  collisionVolumeScales  = [[32 46 102]],
	  collisionVolumeTest    = 1,
	  collisionVolumeType    = [[box]],	  
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[destroyer_dead.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ a_shipcorvette = unitDef })
