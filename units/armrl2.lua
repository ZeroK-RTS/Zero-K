unitDef = {
  unitname                      = [[armrl2]],
  name                          = [[Defender]],
  description                   = [[Light Missile Tower]],
  acceleration                  = 0,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildCostEnergy               = 65,
  buildCostMetal                = 65,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armrl2_aoplane.dds]],
  buildPic                      = [[ARMRL.png]],
  buildTime                     = 65,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext = [[The defender is a long range anti-air and anti-ground. It easily takes out land scouts and is your best defense against crawling bombs. It can help to harass an enemies skirmishers and keep them off your llt's, as well as to push an llt line back from yours. It dies very quickly to a frontal attack though.]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[BIG_UNITEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseskirm]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 32.5,
  maxDamage                     = 295,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[defender.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[BIG_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  side                          = [[ARM]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  TEDClass                      = [[METAL]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[ARMRL_MISSILE]],
      badTargetCategory  = [[HOVER SWIM LAND SINK FLOAT SHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    ARMRL_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 110,
        planes  = [[110]],
        subs    = 5.5,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      guidance                = true,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[wep_m_needle.s3o]],
      noSelfDamage            = true,
      range                   = 610,
      reloadtime              = 1.2,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/ROCKHVY2]],
      startsmoke              = [[1]],
      startVelocity           = 500,
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 13000,
      turret                  = true,
      weaponAcceleration      = 150,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Defender]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 295,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 26,
      object           = [[ARMRL_DEAD]],
      reclaimable      = true,
      reclaimTime      = 26,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Defender]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 295,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 26,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 26,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Defender]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 295,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 13,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 13,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armrl2 = unitDef })
