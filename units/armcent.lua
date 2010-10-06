unitDef = {
  unitname                      = [[armcent]],
  name                          = [[Trebuchet]],
  description                   = [[Rocket Artillery]],
  bmcode                        = [[0]],
  buildAngle                    = 8192,
  buildCostEnergy               = 1300,
  buildCostMetal                = 1300,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[armcent_aoplane.dds]],
  buildPic                      = [[armcent.png]],
  buildTime                     = 1300,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext = [[What you can see of the Trebuchet is just the tip of an iceberg: the superstructure hides a large loading facility manned by hundreds of Arm clones, all there with a single purpose: feeding the ravenous weapon its load of long-range rockets. Arm Commanders have used this new tool like the old plasma-based Guardian, which it is designed to replace--to shell fortified positions from a safe place.]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[fixedarty]],
  mass                          = 650,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  noAutoFire                    = false,
  objectName                    = [[ARMCENT]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  shootme                       = [[1]],
  side                          = [[ARM]],
  sightDistance                 = 660,

  sounds                        = {
    canceldestruct = [[ota/cancel2]],

    cant           = {
      [[ota/cantdo4]],
    },

    cloak          = [[ota/kloak1]],

    count          = {
      [[ota/count6]],
      [[ota/count5]],
      [[ota/count4]],
      [[ota/count3]],
      [[ota/count2]],
      [[ota/count1]],
    },


    ok             = {
      [[ota/twrturn3]],
    },


    select         = {
      [[ota/twrturn3]],
    },

    uncloak        = [[ota/kloak1un]],
    underattack    = [[ota/warning1]],
  },

  TEDClass                      = [[FORT]],
  useBuildingGroundDecal        = true,
  version                       = [[1]],
  workerTime                    = 0,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def               = [[DROPPOD]],
      badTargetCategory = [[SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
      mainDir           = [[0 1 0]],
      maxAngleDif       = 230,
    },

  },


  weaponDefs                    = {

    DROPPOD = {
      name                    = [[Long-Range Rocket Artillery]],
      accuracy                = 1400,
      areaOfEffect            = 32,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 0,
        planes  = 0,
        subs    = 0,
      },

      edgeEffectiveness       = 0.7,
      energypershot           = 150,
      explosionGenerator      = [[custom:WEAPEXP_PUFF]],
      fireStarter             = 100,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = false,
      metalpershot            = 150,
      model                   = [[box_small]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      range                   = 5200,
      reloadtime              = 15,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOMED4]],
      soundStart              = [[OTAunit/ROCKHVY1]],
      startsmoke              = [[1]],
      stockpile               = true,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 320,
      weaponTimer             = 3,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 10000,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Trebuchet]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 520,
      object           = [[ARMCENT_DEAD]],
      reclaimable      = true,
      reclaimTime      = 520,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Trebuchet]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 520,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 520,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Trebuchet]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 260,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 260,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armcent = unitDef })
