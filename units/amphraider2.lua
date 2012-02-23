unitDef = {
  unitname               = [[amphraider2]],
  name                   = [[Ray]],
  description            = [[Amphibious Raider Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.4,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,

  buildoptions           = {
  },

  buildPic               = [[amphraider2.png]],
  buildTime              = 200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
    maxwatertank = [[300]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 411,
  maxDamage              = 620,
  maxSlope               = 36,
  maxVelocity            = 2.4,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName             = [[amphraider2.s3o]],
  script                 = [[amphraider2.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:watercannon_muzzle]],
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  sonarDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[WATERCANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    WATERCANNON = {
      name                    = [[Water Cannon]],
      alphaDecay              = 0,
      areaOfEffect            = 8,
      --cegTag		      = [[torpedo_trail]],
      colormap                = [[0.6 0.8 1 1 0.6 0.8 1 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 6,
        planes  = 6,
        subs    = 0.3,
      },

      explosionGenerator      = [[custom:watercannon_impact]],
      impactOnly              = true,
      impulseBoost            = 15,
      impulseFactor           = 60,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      myGravity		          = 0.6,
      noGap                   = false,
      noSelfDamage            = true,
      projectiles	          = 2,
      range                   = 300,
      reloadtime              = 0.1,
      rgbColor                = [[0.6 0.8 1]],
      rgbColor2               = [[0.6 0.8 1]],
      separation              = 2,
      stages		          = 20,
      --size                  = 0,
      sizeDecay               = 0,
      soundStart              = [[weapon/hiss]],
      soundStartVolume        = 4,
      startsmoke              = [[0]],
      texture1	              = [[wake]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Grebe]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Grebe]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphraider2 = unitDef })
