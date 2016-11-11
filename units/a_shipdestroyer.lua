unitDef = {
  unitname               = [[a_shipdestroyer]],
  name                   = [[Warden]],
  description            = [[Destroyer (Assault/Riot)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 320,
  buildCostMetal         = 320,
  builder                = false,
  buildPic               = [[CORESUPP.png]],
  buildTime              = 320,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 -2]],
  collisionVolumeScales  = [[25 25 90]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {

    helptext       = [[The Warden is a brawler, combining strong area-of-effect sonic cannons and armor at a low cost--for a ship. Use these to protect your fleet against surface and underwater raiders and to spearhead assaults.]],
    modelradius    = [[15]],
	turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[a_shipdestroyer]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 1800,
  maxVelocity            = 1.8,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[warden.s3o]],
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
  sightDistance          = 410,
  smoothAnim             = true,
  sonarDistance          = 410,
  turninplace            = 0,
  turnRate               = 360,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    EMG         = {
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
			default = 170,
			planes  = 170,
			subs    = 170,
		},
		
		cegTag					= [[sonictrail]],
		explosionGenerator		= [[custom:sonic_2]],
		edgeEffectiveness       = 0.75,
		fireStarter             = 150,
		impulseBoost            = 60,
		impulseFactor           = 0.5,
		interceptedByShieldType = 1,
		noSelfDamage            = true,
		range                   = 250,
		reloadtime              = 2.5,
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

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[warden_dead.s3o]],
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
