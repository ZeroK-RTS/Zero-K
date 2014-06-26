unitDef = {
  unitname               = [[corsent]],
  name                   = [[Copperhead]],
  description            = [[Flak Tank]],
  acceleration           = 0.05952,
  brakeRate              = 0.14875,
  buildCostEnergy        = 550,
  buildCostMetal         = 550,
  builder                = false,
  buildPic               = [[corsent.png]],
  buildTime              = 550,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[38 52 38]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Tanque de flak]],
    description_fr = [[Tank Anti-Air r Canons Flak]],
	description_de = [[Flakpanzer]],
	description_pl = [[Czolg przeciwlotniczy]],
    helptext       = [[The Copperhead's flak cannon makes quick work of enemy gunships, and is also fairly effective against planes.]],
    helptext_bp    = [[]],
    helptext_fr    = [[Le Copperhead est doté d'un double canon Flak envoyant des balles explosives en l'air. Il compense son imprécision par les dégâts de zones qu'elles provoquent. Peut efficace contre les cibles rapides, il s'occupera parfaitement des cibles aeriennes groupées en essaim.]],
	helptext_de    = [[Copperheads Flakkanone macht kurzen Prozess mit feindlichen Hubschraubern, aber auch gegen Flugzeuge erweist sie sich als nützlich.]],
	helptext_pl    = [[Dzialo Copperheada szybko pozbywa sie statkow powietrznych i dobrze radzi sobie z lotnictwem.]],
	modelradius    = [[19]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maneuverleashlength    = [[30]],
  mass                   = 242,
  maxDamage              = 1200,
  maxSlope               = 18,
  maxVelocity            = 3.2,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[corsent.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  
  sfxtypes               = {

  explosiongenerators = {
      [[custom:HEAVY_CANNON_MUZZLE]],
    },

  },
  
  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 653,
  upright                = false,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FLAK]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs             = {

    FLAK = {
      name                    = [[Flak Cannon]],
      accuracy                = 100,
      areaOfEffect            = 64,
      burnblow                = true,
      canattackground         = false,
      cegTag                  = [[flak_trail]],
      color                   = 1,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 8.2,
        planes  = 81.5,
        subs    = 5,
      },

      edgeEffectiveness       = 0.85,
      explosionGenerator      = [[custom:flakplosion]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-24]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 900,
      reloadtime              = 0.4,
      size                    = 0.01,
      soundHit                = [[weapon/flak_hit]],
      soundStart              = [[weapon/flak_fire]],
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Copperhead]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[corsent_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Copperhead]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corsent = unitDef })
