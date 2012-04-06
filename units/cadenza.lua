unitDef = {
  unitname               = [[cadenza]],
  name                   = [[Cadenza]],
  description            = [[Skirmish Strider]],
  acceleration           = 0.14,
  brakeRate              = 0.28,
  buildCostEnergy        = 3000,
  buildCostMetal         = 3000,
  buildPic               = [[cadenza.png]],
  buildTime              = 3000,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 85 50]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
	canjump = [[1]],
	soundok = [[heavy_bot_move]],
	soundselect = [[bot_select]],
  },

  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[t3generic]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 800,
  maxDamage              = 6400,
  maxSlope               = 36,
  maxVelocity            = 2.2,
  maxWaterDepth          = 36,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[cadenza.s3o]],
  script                 = [[cadenza.lua]],
  seismicSignature       = 16,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
    	[[custom:THUDMUZZLE]],
	[[custom:THUDSHELLS]],
	[[custom:THUDDUST]],
	[[custom:STORMMUZZLE]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 32,
  turnRate               = 672,
  upright                = true,

  weapons                = {

    {
      def                = [[CANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[LANDING]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[NULL]],
    },
  },


  weaponDefs             = {
  
    CANNON = {
      name                    = [[Plasma Repeater Cannon]],
      areaOfEffect            = 32,
      burst		      = 2,
      burstRate               = 0.15,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 7.5,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      range                   = 420,
      reloadtime              = 1,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 700,
    },
    
    MISSILE = {
      name                    = [[Heavy Missile Battery]],
      areaOfEffect            = 96,
      burst		      = 4,
      burstRate               = 0.16,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 15,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[wep_m_maverick.s3o]],
      range                   = 450,
      reloadtime              = 6,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 180,
      texture2                = [[lightsmoketrail]],
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 24000,
      turret                  = true,
      weaponAcceleration      = 120,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },
    
    LANDING = {
      name                    = [[Cadenza Landing]],
      areaOfEffect            = 300,
      canattackground         = false,
      craterBoost             = 4,
      craterMult              = 6,

      damage                  = {
        default = 800,
        planes  = 800,
        subs    = 40,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
      impulseBoost            = 1,
      impulseFactor           = 0.8,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 5,
      reloadtime              = 20,
      soundHit                = [[krog_stomp]],
      soundStart              = [[krog_stomp]],
      soundStartVolume        = 3,
      startsmoke              = [[1]],
      turret                  = false,
      weaponType              = [[Cannon]],
      weaponVelocity          = 5,
    },    
  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Cadenza]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 6400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 1200,
      object           = [[wreck4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 1200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Cadenza]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 6400,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 600,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 600,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },
  
}

return lowerkeys({ cadenza = unitDef })
