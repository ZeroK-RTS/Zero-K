unitDef = {
  unitname               = [[corak]],
  name                   = [[Bandit]],
  description            = [[Medium-Light Raider Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.4,
  buildCostMetal         = 75,
  buildPic               = [[CORAK.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[24 29 24]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Robot Pilleur]],
	description_de = [[Mittel-leichter Raider Roboter]],
    helptext       = [[The Bandit outranges and is somewhat tougher than the Glaive, but still not something that you hurl against entrenched forces. Counter with riot units and LLTs.]],
    helptext_fr    = [[Le Bandit est plus puissant que sa contre partie ennemie, le Glaive. Il n'est cependant pas tr?s puissant et ne passera pas contre quelques d?fenses: LLT ou ?meutiers. ]],
	helptext_de    = [[Als Raider opfert der Bandit die rohe Feuerkraft der Überlebensfähigkeit. Er ist etwas stärker als der Glaive, aber immer noch nicht stark genug, um gegen größere Kräfte zu bestehen. Mit Rioteinheiten und LLT entgegenwirken.]],
	modelradius    = [[12]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 250,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[mbot.s3o]],
  script				 = [[corak.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2500,
  upright                = true,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    LASER = {
      name                    = [[Laser Blaster]],
      areaOfEffect            = 8,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1200,
		light_radius = 120,
      },
	  
      damage                  = {
        default = 9.53,
        subs    = 0.61,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 245,
      reloadtime              = 0.1,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/small_laser_fire2]],
      soundTrigger            = true,
      thickness               = 2.55,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[mbot_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ corak = unitDef })
