unitDef = {
  unitname               = [[striderantiheavy]],
  name                   = [[Ultimatum]],
  description            = [[Cloaked Anti-Heavy/Anti-Strider Walker]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  autoHeal               = 5,
  brakeRate              = 0.375,
  buildCostMetal         = 2000,
  buildPic               = [[striderantiheavy.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 8,
  cloakCostMoving        = 24,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[42 42 42]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
	description_de = [[Desintegrator Wanderer (Anti-Strider)]],	
    helptext       = [[The Ultimatum packs only one weapon: a disintegrator gun that can vaporize a heavy tank in one blast. It is best used for sneaking up to enemy heavy striders and inflicting serious damage or destruction with a few shots. Defense against it is achieved by screening your heavyweights with lighter units.]],
	helptext_de    = [[Ultimatum beinhaltet nur eine Waffe: ein Desintegrator, welche gegnerische Panzer mit einem Schlag vaporisieren kann. Am meisten wird dafür er gebraucht, sich an gegenerische, harte Streicher heranzuschleichen und diese mit einigen Schüssen zu erledigen. Verteidigung gegen sie wird erreicht, indem man seine Schwergewicht mit leichten Einheiten beschützt.]],
	modelradius    = [[21]],
  },

  energyUse              = 0,
  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[corcommander]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 2000,
  maxSlope               = 36,
  maxVelocity            = 1.45,
  maxWaterDepth          = 5000,
  minCloakDistance       = 100,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[noruas]],
  script                 = [[striderantiheavy.lua]],
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:laserbladestrike]],
    },

  },

  showNanoSpray          = false,
  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 1148,
  upright                = true,

  weapons                = {

    {
      def = [[DISINTEGRATOR]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SUB SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    DISINTEGRATOR = {
      name                    = [[Disintegrator]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      commandfire             = false,
      craterBoost             = 1,
      craterMult              = 6,

      damage                  = {
        default = 1200,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 250,
      reloadtime              = 1.5,
	  size					  = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
	  waterWeapon             = true,
      weaponType              = [[DGun]],
      weaponVelocity          = 300,
    },

  },


  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[ultimatum_d.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ striderantiheavy = unitDef })
