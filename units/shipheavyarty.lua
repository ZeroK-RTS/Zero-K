unitDef = {
  unitname               = [[shipheavyarty]],
  name                   = [[Shogun]],
  description            = [[Battleship (Heavy Artillery)]],
  acceleration           = 0.039,
  activateWhenBuilt   = true,
  brakeRate              = 0.0475,
  buildCostMetal         = 5000,
  builder                = false,
  buildPic               = [[shipheavyarty.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  cantBeTransported      = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[45 45 260]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[80]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 10,
  footprintZ             = 10,
  highTrajectory         = 2,
  iconType               = [[shipheavyarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 8000,
  maxVelocity            = 2.2,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[BOAT10]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName             = [[shipheavyarty.s3o]],
  script                 = [[shipheavyarty.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:xamelimpact]],
      [[custom:ROACHPLOSION]],
      [[custom:shellshockflash]],
    },

  },
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 216,
  waterLine              = 4,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Long-Range Plasma Battery]],
      areaOfEffect            = 96,
      avoidFeature            = false,
	  avoidGround             = false,
      burst                   = 3,
      burstrate               = 0.2,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 501.1,
        planes  = 501.1,
        subs    = 25,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_96]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      projectiles             = 1,
      range                   = 1600,
      reloadtime              = 12.5,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[explosion/ex_large5]],
      sprayAngle              = 768,
      tolerance               = 4096,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 475,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[shipheavyarty_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ shipheavyarty = unitDef })
