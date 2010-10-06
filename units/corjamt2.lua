unitDef = {
  unitname                      = [[corjamt2]],
  name                          = [[Altruist]],
  description                   = [[Vampiric Attractor Shield]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 9821,
  buildCostEnergy               = 450,
  buildCostMetal                = 450,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corjamt2_aoplane.dds]],
  buildPic                      = [[CORJAMT.png]],
  buildTime                     = 450,
  canAttack                     = false,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],
  energyUse                     = 1.5,
  explodeAs                     = [[BIG_UNITEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[shield]],
  idleAutoHeal                  = 100,
  idleTime                      = 1800,
  mass                          = 225,
  maxDamage                     = 1160,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[m-8.s3o]],
  onoffable                     = false,
  seismicSignature              = 4,
  selfDestructAs                = [[BIG_UNITEX]],
  side                          = [[CORE]],
  sightDistance                 = 200,
  smoothAnim                    = true,
  TEDClass                      = [[SPECIAL]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  weapons                       = {

    {
      def         = [[COR_SHIELD_SMALL]],
      maxAngleDif = 1,
    },

  },


  weaponDefs                    = {

    COR_SHIELD_SMALL = {
      name                    = [[PlasmaAttractor]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      impulseFactor           = 0,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[0.1 0.1 0.1]],
      shieldForce             = -4,
      shieldGoodColor         = [[1 0.1 0.1]],
      shieldInterceptType     = 3,
      shieldPower             = 2500,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 7,
      shieldRadius            = 400,
      shieldRepulser          = true,
      smartShield             = true,
      texture1                = [[wake]],
      visibleShield           = true,
      visibleShieldHitFrames  = 15,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Altruist]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1160,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[3]],
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[all]],
    },


    DEAD2 = {
      description      = [[Debris - Altruist]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1160,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Altruist]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1160,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 90,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 90,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corjamt2 = unitDef })
