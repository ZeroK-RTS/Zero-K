unitDef = {
  unitname               = [[shipassault]],
  name                   = [[Siren]],
  description            = [[Destroyer (Riot/Assault)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 590,
  buildCostMetal         = 590,
  builder                = false,
  buildPic               = [[shipassault.png]],
  buildTime              = 590,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 6 5]],
  collisionVolumeScales  = [[55 55 130]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],
  --Core_color.dds Core_other.dds
  customParams           = {

    helptext       = [[This Destroyer is a general-purpose combat vessel, combining a strong area-of-effect sonic cannon, a medium-range vertical launch missile, and strong armor. Use its sonic gun against smaller opponents above and below the water, and its missile against static targets.]],
    modelradius    = [[55]],
	turnatfullspeed = [[1]],
	extradrawrange = 800,
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shipassault]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 5400,
  maxVelocity            = 2.0,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[shipassault.s3o]],
  scale                  = [[0.5]],
  script				 = [[shipassault.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_l]],
    },

  },

  sightDistance          = 430,
  sonarDistance          = 430,
  turninplace            = 0,
  turnRate               = 360,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SONIC]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  mainDir            = [[0 -1 0]],
      maxAngleDif        = 240,
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
		areaOfEffect            = 160,
		avoidFeature            = true,
		avoidFriendly           = true,
		burnblow                = true,
		craterBoost             = 0,
		craterMult              = 0,

		customParams            = {
			slot = [[5]],
			muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
			miscEffectFire   = [[custom:RIOT_SHELL_L]],
			lups_explodelife = 1.5,
			lups_explodespeed = 0.8,
		},

		damage                  = {
			default = 230,
			planes  = 230,
			subs    = 230,
		},
		
		cegTag					= [[sonictrail]],
		explosionGenerator		= [[custom:sonic_80]],
		edgeEffectiveness       = 0.5,
		fireStarter             = 150,
		impulseBoost            = 300,
		impulseFactor           = 0.5,
		interceptedByShieldType = 1,
		noSelfDamage            = true,
		range                   = 380,
		reloadtime              = 3,
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
      areaOfEffect            = 30,
      cegTag                  = [[missiletrailyellow]],
	  collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 360,
        subs    = 360,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 100,
	  fixedLauncher			  = true,	  
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 11,
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
      object           = [[shipassault_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ shipassault = unitDef })
