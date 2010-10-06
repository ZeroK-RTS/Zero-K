unitDef = {
  unitname                      = [[corbeac]],
  name                          = [[Zenith]],
  description                   = [[Meteor Controller]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  antiweapons                   = [[1]],
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 32700,
  buildCostEnergy               = 35000,
  buildCostMetal                = 35000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[corbeac_aoplane.dds]],
  buildPic                      = [[corbeac.png]],
  buildTime                     = 35000,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  corpse                        = [[DEAD]],
  defaultmissiontype            = [[GUARD_NOMOVE]],
  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 17500,
  maxDamage                     = 12000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[corbeac.3do]],
  onoffable                     = true,
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:IMMA_LAUNCHIN_MAH_LAZER]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[METEOR]],
      badTargetCateogory = [[MOBILE]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },

  },


  weaponDefs                    = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 6000,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 32,
      soundStart              = [[bladeturnon]],
      soundTrigger            = true,
      startsmoke              = [[0]],
      thickness               = 32,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 6000,
    },


    METEOR      = {
      name                    = [[Meteor Bombardment]],
      alwaysVisible           = 1,
      areaOfEffect            = 240,
      avoidFeature            = false,
      cegTag                  = [[METEOR_TAG]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 2,

      damage                  = {
        default = 2000,
        planes  = 2000,
        subs    = 100,
      },

      edgeEffectiveness       = 0.8,
      energypershot           = 50,
      explosionGenerator      = [[custom:NUKE_150_GRAY]],
      fireStarter             = 70,
      flightTime              = 30,
      impulseBoost            = 0.123,
      impulseFactor           = 0.0492,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[meteor]],
      noSelfDamage            = true,
      range                   = 9000,
      reloadtime              = 1,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[rockhit]],
      startsmoke              = [[1]],
      startVelocity           = 500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      trajectoryHeight        = 0,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponTimer             = 10,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1200,
      wobble                  = 1024,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Zenith]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 14000,
      object           = [[corbeac_dead]],
      reclaimable      = true,
      reclaimTime      = 14000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Zenith]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 14000,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 14000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Zenith]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 7000,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 7000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corbeac = unitDef })
