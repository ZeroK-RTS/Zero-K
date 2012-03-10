unitDef = {
  unitname               = [[amphfloater]],
  name                   = [[Buoy]],
  description            = [[Inflatable Amphibious Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,

  buildoptions           = {
  },

  buildPic               = [[amphfloater.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
    floattoggle = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[amphskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 411,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[can.s3o]],
  script                 = [[amphfloater.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    --{
    --  def                = [[TORPEDO]],
    --  badTargetCategory  = [[FIXEDWING]],
    --  onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    --},
  },


  weaponDefs             = {

	CANNON = {
      name                    = [[Disruption Cannon]],
      accuracy                = 200,
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 2,
	  
      damage                  = {
        default = 290,
        planes  = 290,
        subs    = 12,
      },
      
      explosionGenerator      = [[custom:PLASMA_HIT_32]],
      fireStarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
	  myGravity               = 0.2,
	  predictBoost            = 1,
      projectiles             = 1,
      range                   = 430,
      reloadtime              = 3.4,
	  rgbcolor                = [[0.9 0.1 0.9]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      soundStartVolume        = 3.5,
      soundTrigger			  = true,
      sprayangle              = 0,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 330,
	},

  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Buoy]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Buoy]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphfloater = unitDef })
