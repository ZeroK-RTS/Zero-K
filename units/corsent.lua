unitDef = {
  unitname               = [[corsent]],
  name                   = [[Copperhead]],
  description            = [[Flak Anti-Air Tank]],
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
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Tank Anti-Air r Canons Flak]],
	description_de = [[Flakpanzer]],
    helptext       = [[The Copperhead's flak cannon makes quick work of enemy gunships, and is also fairly effective against planes.]],
    helptext_fr    = [[Le Copperhead est doté d'un double canon Flak envoyant des balles explosives en l'air. Il compense son imprécision par les dégâts de zones qu'elles provoquent. Peut efficace contre les cibles rapides, il s'occupera parfaitement des cibles aeriennes groupées en essaim.]],
	helptext_de    = [[Copperheads Flakkanone macht kurzen Prozess mit feindlichen Hubschraubern, aber auch gegen Flugzeuge erweist sie sich als nützlich.]],
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
  maxDamage              = 1200,
  maxSlope               = 18,
  maxVelocity            = 3.2,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  moveState              = 0,
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
  sightDistance          = 660,
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
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
		
		light_radius = 0,
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
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 900,
      reloadtime              = 0.4,
      size                    = 0.01,
      soundHit                = [[weapon/flak_hit]],
      soundStart              = [[weapon/flak_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[corsent_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ corsent = unitDef })
