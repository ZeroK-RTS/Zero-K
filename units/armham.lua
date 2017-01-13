unitDef = {
  unitname               = [[armham]],
  name                   = [[Hammer]],
  description            = [[Light Artillery Bot]],
  acceleration           = 0.25,
  brakeRate              = 0.75,
  buildCostEnergy        = 130,
  buildCostMetal         = 130,
  buildPic               = [[ARMHAM.png]],
  buildTime              = 130,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 43 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Leichter Artillerie/Skirmisher Roboter]],
    description_fr = [[Robot d'Artillerie]],
    helptext       = [[The Hammer has a long range plasma cannon that allows indirect fire over obstacles, and outranges static defenses up to heavy laser towers. Although effective versus mobile units, it should be guarded in order to prevent raiders and other fast units from closing range.]],
    helptext_de    = [[Der Hammer besitzt eine weitreichende Plasmakanone, die es ihm erlaubt über Hindernisse zu schießen und sich dabei außer Reichweite von gegnerischen Verteidigungsanlagen zu finden. Obwohl er auch effektiv gegen mobile Einheiten ist, sollte er beschützt werden, um Raider und andere schnelle Einheiten von ihm Fern zu halten.]],
    helptext_fr    = [[Le Hammer a un canon plasma longue port?e qui lui permet de tirer indirectement au dessus des obstacles, et a une port?e plus grande que les tour de d?fense basic jusqu'au HLT. Bien qu'il soit ?fficace contre les unit?es mobiles, il est n?c?ssaire de le d?fendre avec des Warriors pour le prot?ger des unit?s rapide et de raid.]],
	modelradius    = [[14]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 350,
  maxSlope               = 36,
  maxVelocity            = 1.62,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP TOOFAST]],
  objectName             = [[Milo.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1500,
  upright                = true,

  weapons                = {

    {
      def                = [[HAMMER_WEAPON]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    HAMMER_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      accuracy                = 220,
      areaOfEffect            = 16,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1400,
		light_color = [[0.80 0.54 0.23]],
		light_radius = 200,
      },

      damage                  = {
        default = 150.1,
        planes  = 150.1,
        subs    = 7.5,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:MARY_SUE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
	  myGravity               = 0.09,
      noSelfDamage            = true,
      range                   = 840,
      reloadtime              = 6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 260,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[milo_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ armham = unitDef })
