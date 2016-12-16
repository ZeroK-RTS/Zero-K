unitDef = {
  unitname            = [[hoverscout]],
  name                = [[Dagger]],
  description         = [[Fast Attack Hovercraft]],
  acceleration        = 0.066,
  brakeRate           = 0.0835,
  buildCostEnergy     = 85,
  buildCostMetal      = 85,
  builder             = false,
  buildPic            = [[CORSH.png]],
  buildTime           = 85,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[19 19 36]],
  collisionVolumeType    = [[cylZ]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft d'Attaque Éclair]],
    description_de = [[Schnellangriff Luftkissenboot]],
    helptext       = [[The Dagger is the hover plant's scout. It provides a cheap, disposable method of getting intel, and can also hit economic targets of opportunity. Its light sonic cannon can attack surface and underwater targets alike.]],
    helptext_fr    = [[Le Dagger est petit, maniable, rapide et n'a qu'une faible puissance de feu. Idéal pour les attaques surprises depuis la mer, il surprendra bien des ennemis. Son blindage est cependant trop faible pour faire face r une quelquonque résistance. ]],
    helptext_de    = [[Der Dagger ist der Aufklärer unter den Luftkissenbooten. Es bietet dir eine kostengünstige, entbehrliche Möglichkeit deinen Feind frühzeitig um seine Rohstoffquellen zu bringen.]],
  },

  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[hoverraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 300,
  maxSlope            = 36,
  maxVelocity         = 4.8,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[CORSH.s3o]],
  script			  = [[corsh.cob]],
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
      [[custom:flashmuzzle1]],
    },

  },
  sightDistance       = 450,
  sonarDistance       = 230,
  turninplace         = 0,
  turnRate            = 673,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SONICGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs         = {
    SONICGUN         = {
		name                    = [[Light Sonic Blaster]],
		areaOfEffect            = 0,
		avoidFeature            = false,
		avoidFriendly           = true,
		burnblow                = true,
		craterBoost             = 0,
		craterMult              = 0,
		collisionSize			= 16,

		customParams            = {
			single_hit = 1,
		},

		damage                  = {
			default = 110,
			planes  = 110,
			subs    = 110,
		},
		
		cegTag					= [[sonictrail]],
		explosionGenerator		= [[custom:sonic]],
		impulseBoost            = 60,
		impulseFactor           = 0.5,
		interceptedByShieldType = 1,
		intensity				= 0.6,
		noSelfDamage            = true,
		noExplode				= true,
		range                   = 220,
		reloadtime              = 3,
		soundStart              = [[weapon/sonic_blaster]],
		soundHit                = [[weapon/unfa_blast_2]],
		texture1                = [[sonic_glow]],
		texture2                = [[null]],
		rgbColor 				= {0, 0.25, 0.5},
		thickness				= 10,
		turret                  = true,
		weaponType              = [[LaserCannon]],
		weaponVelocity           = 1000,
		waterweapon				= true,
		duration				= 0.05,
	},
  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corsh_dead.s3o]],
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

return lowerkeys({ hoverscout = unitDef })
