unitDef = {
  unitname                      = [[cortoast]],
  name                          = [[Toaster]],
  description                   = [[Heavy Pop-Up Flamer Battery]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 8192,
  buildCostEnergy               = 1800,
  buildCostMetal                = 1800,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[cortoast_aoplane.dds]],
  buildPic                      = [[CORTOAST.png]],
  buildTime                     = 1800,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK FIREPROOF]],
  corpse                        = [[DEAD]],

  customParams                  = {
    fireproof = [[1]],
    helptext  = [[The aptly named Toaster pops up when enemies approach and deploys its massive dual flamers. It can incinerate entire columns in moments.]],
  },

  damageModifier                = 0.25,
  defaultmissiontype            = [[GUARD_NOMOVE]],
  digger                        = [[1]],
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[fixedarty]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 900,
  maxDamage                     = 12500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[CORTOAST2]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[FLAMETHROWER]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs                    = {

    FLAMETHROWER = {
      name                    = [[FlameThrower]],
      areaOfEffect            = 128,
      collideFeature          = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default       = 5,
        flamethrowers = 1,
        planes        = 5,
        subs          = 0.0025,
      },

      explosionGenerator      = [[custom:SMOKE]],
      fireStarter             = 100,
      flameGfxTime            = 1.6,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.1,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noExplode               = true,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 430,
      reloadtime              = 0.1,
      renderType              = 5,
      sizeGrowth              = 2.8,
      soundStart              = [[OTAunit/FLAMHVY1]],
      soundTrigger            = true,
      sprayAngle              = 50000,
      tolerance               = 2500,
      turret                  = true,
      weaponType              = [[Flame]],
      weaponVelocity          = 430,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Toaster]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[CORTOAST_DEAD]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Toaster]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[CORTOAST_DEAD2]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Toaster]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12500,
      energy           = 0,
      featureDead      = [[HEAP1]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[CORTOAST_DEAD2]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP1 = {
      description = [[Wreckage]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 19200,
      energy      = 0,
      footprintX  = 3,
      footprintZ  = 3,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 347.7,
      object      = [[debris3x3a.s3o]],
      reclaimable = true,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ cortoast = unitDef })
