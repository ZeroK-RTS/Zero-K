unitDef = {
  unitname               = [[shiparty]],
  name                   = [[Envoy]],
  description            = [[Cruiser (Artillery)]],
  acceleration           = 0.0417,
  activateWhenBuilt      = true,
  brakeRate              = 0.142,
  buildCostMetal         = 850,
  builder                = false,
  buildPic               = [[shiparty.png]],
  canMove                = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 1 3]],
  collisionVolumeScales  = [[32 32 132]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {

    --extradrawrange = 200,
    modelradius    = [[55]],
    turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shiparty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 25,
  maxDamage              = 2000,
  maxVelocity            = 1.7,
  minCloakDistance       = 75,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP TOOFAST]],
  objectName             = [[shiparty.s3o]],
  script                 = [[shiparty.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 350,
  waterline              = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    PLASMA = {
      name                    = [[Plasma Cannon]],
      areaOfEffect            = 96,
      avoidFeature            = false,
	  avoidGround             = false,
      craterBoost             = 1,
      craterMult              = 2,

			customParams = {
				burst = Shared.BURST_RELIABLE,
			},

      damage                  = {
        default = 601.1,
        planes  = 601.1,
        subs    = 30,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_96]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
	  myGravity               = 0.1,
      projectiles             = 1,
      range                   = 1200,
      reloadtime              = 5,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/heavy_cannon]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },
  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[shiparty_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ shiparty = unitDef })
