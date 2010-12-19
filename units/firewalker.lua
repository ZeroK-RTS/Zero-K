unitDef = {
  unitname            = [[firewalker]],
  name                = [[Firewalker]],
  description         = [[Fire Support Walker (Artillery/Skirmish)]],
  acceleration        = 0.0984,
  bmcode              = [[1]],
  brakeRate           = 0.2392,
  buildCostEnergy     = 1280,
  buildCostMetal      = 1280,
  builder             = false,
  buildPic            = [[firewalker.png]],
  buildTime           = 1280,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[The Firewalker's medium range mortars immolate a small area, denying use of that terrain for brief periods of time. The bot itself is somewhat clumsy and slow to maneuver.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[walkerarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  immunetoparalyzer   = [[0]],
  maneuverleashlength = [[640]],
  mass                = 347,
  maxDamage           = 1250,
  maxSlope            = 36,
  maxVelocity         = 1.9,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[firewalker.s3o]],
  script              = [[punisher.cob]],
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
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turnRate            = 538,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM_MORTAR]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    NAPALM_MORTAR = {
      name                    = [[Immolation Mortar]],
      accuracy                = 320,
      areaOfEffect            = 256,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:firewalker_impact]],
      firestarter             = 40,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      movingAccuracy          = 1200,
      myGravity               = 0.1,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 900,
      reloadtime              = 12,
      renderType              = 4,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      sprayangle              = 2048,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Firewalker]],
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
      metal            = 512,
      object           = [[CORKARG_DEAD]],
      reclaimable      = true,
      reclaimTime      = 512,
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Firewalker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 650,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 512,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 512,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Firewalker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 650,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 256,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 256,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ firewalker = unitDef })
