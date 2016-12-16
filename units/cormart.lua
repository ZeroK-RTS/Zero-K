unitDef = {
  unitname            = [[cormart]],
  name                = [[Pillager]],
  description         = [[General-Purpose Artillery]],
  acceleration        = 0.0282,
  brakeRate           = 0.136,
  buildCostEnergy     = 700,
  buildCostMetal      = 700,
  builder             = false,
  buildPic            = [[CORMART.png]],
  buildTime           = 700,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Artillerie Mobile]],
	description_de = [[Allzweck Artillerie]],
    helptext       = [[The heavy, long-ranging gun of the Pillager makes it the unit of choice for standoff shelling of enemy mobiles or structures. As always, it should be wary of anything that gets close to it.]],
    helptext_fr    = [[Le Pillager est équipé d'un canon plasma lourd r trcs grande portée. C'est une artillerie r forte puissance de feu et précise. Elle est capable de toucher certaines cibles en mouvement mais reste plus efficace sur les structures immobiles. Sa cadence et son angle de tir sont ses principaux défauts.]],
	helptext_de    = [[Die schwere, weitreichende Kanone des Pillagers macht ih zur pefekten Wahl, wenn es um einen Stellungskrieg geht und du Bauwerke usw. zerstören willst. Wie immer bei Artillerieeinheiten, musst du alledings alle feindlichen Einheiten von dem Pillager fernhalten.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 840,
  maxSlope            = 18,
  maxVelocity         = 2.7,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[cormart.s3o]],
  pushResistant       = 0,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 660,
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 31,
  turninplace         = 0,
  turnRate            = 400,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORE_ARTILLERY]],
      mainDir            = [[0 0 1]],
--      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORE_ARTILLERY = {
      name                    = [[Plasma Artillery]],
      accuracy                = 180,
      areaOfEffect            = 96,
	  avoidFeature            = false,
	  avoidGround             = false,
      craterBoost             = 1,
      craterMult              = 2,

      customParams            = {
		light_color = [[1.4 0.8 0.3]],
      },

      damage                  = {
        default = 600.5,
        planes  = 600.5,
        subs    = 35,
      },

      edgeEffectiveness       = 0.5,
	  explosionGenerator      = [[custom:DOT_Pillager_Explo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      noSelfDamage            = true,
      range                   = 1180,
      reloadtime              = 7,
      soundHit                = [[weapon/cannon/arty_hit]],
      soundStart              = [[weapon/cannon/pillager_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 330,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[cormart_dead.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ cormart = unitDef })
