unitDef = {
  unitname               = [[amphskirm]],
  name                   = [[Duck]],
  description            = [[Amphibious Skirmisher Bot]],
  acceleration           = 0.18,
  amphibious             = [[1]],
  brakeRate              = 0.375,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,

  buildoptions           = {
  },

  buildPic               = [[amphskirm.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[walkerskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 390,
  maxDamage              = 620,
  maxSlope               = 36,
  maxVelocity            = 1.6,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName             = [[amphskirm.s3o]],
  script                 = [[amphskirm.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  sonarDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1000,
  upright                = true,

  weapons                = {
    {
      def                = [[GYROJET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },


  weaponDefs             = {
  
    GYROJET = {
      name                    = [[Gyrojet]],
      areaOfEffect            = 8,
      cegTag                  = [[torpedo_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50,
        planes  = 50,
        subs    = 2.5,
      },
	  
      fireStarter             = 70,
      flightTime              = 2.2,
      guidance                = false,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_m_frostshard.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 440,
      reloadtime              = 0.75,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/mini_cannon]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/cannon/emg_hit]],
      soundStartVolume        = 6,
      startVelocity           = 500,
      texture2                = [[wake]],
      tracks                  = false,
      turret                  = true,
	  waterweapon			  = true,
      weaponAcceleration      = 190,
      weaponTimer             = 1,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
    },	
  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Duck]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Duck]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 50,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphskirm = unitDef })
