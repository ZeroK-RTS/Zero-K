unitDef = {
  unitname               = [[a_shipdestroyer]],
  name                   = [[Warden]],
  description            = [[Destroyer (Riot/Assault)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 420,
  buildCostMetal         = 420,
  builder                = false,
  buildPic               = [[destroyer.png]],
  buildTime              = 420,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 0]],
  collisionVolumeScales  = [[35 35 110]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],
  --Core_color.dds Core_other.dds
  customParams           = {

    helptext       = [[This Destroyer is a general-purpose combat vessel, combining a strong area-of-effect sonic cannon, a medium-range vertical launch missile, and strong armor. Use its sonic gun against smaller opponents above and below the water, and its missile against static targets.]],
    modelradius    = [[15]],
	turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[a_shipdestroyer]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 2400,
  maxVelocity            = 2.0,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[a_shipdestroyer.s3o]],
  scale                  = [[0.5]],
  script				 = [[a_shipdestroyer.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_l]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 430,
  smoothAnim             = true,
  sonarDistance          = 430,
  turninplace            = 0,
  turnRate               = 360,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SONIC]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    SONIC         = {
		name                    = [[Sonic Blaster]],
		areaOfEffect            = 180,
		avoidFeature            = true,
		avoidFriendly           = true,
		burnblow                = true,
		craterBoost             = 0,
		craterMult              = 0,

		customParams            = {
			slot = [[5]],
			muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
			miscEffectFire   = [[custom:RIOT_SHELL_L]],
			lups_explodelife = 1.3,
			lups_explodespeed = 0.8,
		},

		damage                  = {
			default = 260,
			planes  = 260,
			subs    = 16,
		},
		
		cegTag					= [[sonictrail]],
		explosionGenerator		= [[custom:sonic_2]],
		edgeEffectiveness       = 0.5,
		fireStarter             = 150,
		impulseBoost            = 300,
		impulseFactor           = 0.5,
		interceptedByShieldType = 1,
		noSelfDamage            = true,
		range                   = 380,
		reloadtime              = 2,
		soundStart              = [[weapon/sonicgun]],
		soundHit                = [[weapon/sonicgun_hit]],
		soundStartVolume        = 12,
		soundHitVolume			= 10,
		texture1                = [[sonic_glow]],
		texture2                = [[null]],
		texture3                = [[null]],
		rgbColor 				= {0, 0.5, 1},
		thickness				= 20,
		corethickness			= 1,
		turret                  = true,
		weaponType              = [[LaserCannon]],
		weaponVelocity          = 700,
		waterweapon				= true,
		duration				= 0.15,
	},
	
    MISSILE      = {
      name                    = [[Destroyer Missiles]],
      areaOfEffect            = 48,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 400,
        subs    = 400,
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
      range                   = 700,
      reloadtime              = 10,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/missile_fire12]],
      soundStart              = [[weapon/missile/missile_fire10]],
      startVelocity			  = 100,
      tolerance               = 4000,
	  turnrate				  = 30000,
	  turret				  = true,	  
	  --waterWeapon			  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1800,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[destroyer_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ a_shipdestroyer = unitDef })
