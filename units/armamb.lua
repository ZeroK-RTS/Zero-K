unitDef = {
  unitname                      = [[armamb]],
  name                          = [[Ambusher]],
  description                   = [[Cloakable HE EMG Battery]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 8192,
  buildCostEnergy               = 1700,
  buildCostMetal                = 1700,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armamb_aoplane.dds]],
  buildPic                      = [[ARMAMB.png]],
  buildTime                     = 1700,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  cloakCost                     = 4,
  collisionVolumeOffsets        = [[0 16 0]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext = [[If you are beset by massive swarms of enemies, the Ambusher is your genie in a bottle--a genie with dual 900 RPM high-explosive Energy Machine Guns.]],
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
  initCloaked                   = false,
  levelGround                   = false,
  mass                          = 850,
  maxDamage                     = 10500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 70,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[ARMAMB2]],
  seismicSignature              = 16,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:DEVA_SHELLS]],
    },

  },

  side                          = [[ARM]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    EMG = {
      name                    = [[HE EMG]],
      areaOfEffect            = 96,
      burnblow                = true,
      burst                   = 6,
      burstrate               = 0.07,
      collideFriendly         = false,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 2,
      },

      edgeEffectiveness       = 0.5,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      pitchtolerance          = 12000,
      projectiles             = 2,
      range                   = 425,
      reloadtime              = 0.4,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.5]],
      soundHit                = [[OTAunit/XPLOSML3]],
      soundStart              = [[flashemg]],
      sprayAngle              = 4096,
      startsmoke              = [[0]],
      sweepfire               = false,
      tolerance               = 6000,
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 425,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Ambusher]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 10500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 680,
      object           = [[ARMAMB_DEAD1]],
      reclaimable      = true,
      reclaimTime      = 680,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Ambusher]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 10500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 680,
      object           = [[ARMAMB_DEAD2]],
      reclaimable      = true,
      reclaimTime      = 680,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Ambusher]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 10500,
      energy           = 0,
      featureDead      = [[HEAP1]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 340,
      object           = [[ARMAMB_DEAD2]],
      reclaimable      = true,
      reclaimTime      = 340,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP1 = {
      description      = [[Wreckage]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 18000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 351.3,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armamb = unitDef })
