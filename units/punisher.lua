unitDef = {
  unitname            = [[punisher]],
  name                = [[Punisher]],
  description         = [[Fire Support Walker (Artillery/Skirmish)]],
  acceleration        = 0.0984,
  bmcode              = [[1]],
  brakeRate           = 0.2392,
  buildCostEnergy     = 520,
  buildCostMetal      = 520,
  builder             = false,
  buildPic            = [[punisher.png]],
  buildTime           = 520,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[The Punisher's medium range mortars have a considerable AoE and decent damage output. However, the bot itself is somewhat clumsy and slow to maneuver.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[walkerarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  immunetoparalyzer   = [[0]],
  maneuverleashlength = [[640]],
  mass                = 217,
  maxDamage           = 650,
  maxSlope            = 36,
  maxVelocity         = 1.7,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[punisher.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:shellshockflash]],
      [[custom:SHELLSHOCKSHELLS]],
      [[custom:SHELLSHOCKGOUND]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 380,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turnRate            = 538,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PLASMA]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    PLASMA = {
      name                    = [[Plasma Mortar]],
      accuracy                = 320,
      areaOfEffect            = 96,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 190,
        planes  = 190,
        subs    = 9.5,
      },

      energypershot           = [[0]],
      explosionGenerator      = [[custom:WEAPEXP_PUFF]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      movingAccuracy          = 1200,
      myGravity               = 0.1,
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 2.5,
      renderType              = 4,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Punisher]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 650,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 208,
      object           = [[CORKARG_DEAD]],
      reclaimable      = true,
      reclaimTime      = 208,
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Punisher]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 650,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 208,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 208,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Punisher]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 650,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ punisher = unitDef })
