unitDef = {
  unitname            = [[hoversonic]],
  name                = [[Morningstar]],
  description         = [[Antisub Hovercraft]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostEnergy     = 300,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoversonic.png]],
  buildTime           = 300,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext       = [[The Morningstar comes armed with a sonic pulse cannon which completely doesn't care whether target is above or under water.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 900,
  maxSlope            = 36,
  maxVelocity         = 3,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hovershotgun.s3o]],
  script			  = [[hovershotgun.cob]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },
  sightDistance       = 385,
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SONICGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {
  
    SONICGUN         = {
		name                    = [[Sonic Blaster]],
		areaOfEffect            = 70,
		avoidFeature            = true,
		avoidFriendly           = true,
		burnblow                = true,
		craterBoost             = 0,
		craterMult              = 0,

		customParams            = {
			slot = [[5]],
			muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
			miscEffectFire   = [[custom:RIOT_SHELL_L]],
			lups_explodelife = 100,
			lups_explodespeed = 1,
		},

		damage                  = {
			default = 175,
			planes  = 175,
			subs    = 175,
		},
		
		cegTag					= [[sonictrail]],
		explosionGenerator		= [[custom:sonic]],
		edgeEffectiveness       = 0.75,
		fireStarter             = 150,
		impulseBoost            = 60,
		impulseFactor           = 0.5,
		interceptedByShieldType = 1,
		noSelfDamage            = true,
		range                   = 320,
		reloadtime              = 1.1,
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


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverassault_dead.s3o]],
    },


    DEAD2 = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ hoversonic = unitDef })
