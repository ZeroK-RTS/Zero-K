unitDef = {
  unitname            = [[armfig2]],
  name                = [[Freedom Fighter II]],
  description         = [[Interceptor]],
  acceleration        = 2,
  amphibious          = true,
  bankscale           = [[1]],
  bmcode              = [[1]],
  brakeRate           = 8,
  buildCostEnergy     = 150,
  buildCostMetal      = 150,
  buildPic            = [[armfig2.png]],
  buildTime           = 150,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  corpse              = [[HEAP]],
  cruiseAlt           = 200,

  customParams        = {
    helptext = [[This variant of the Freedom Fighter boasts more powerful engines and dual anti-air EMGs, making it excellent at catching and destroying incoming bombers. However, it is not as versatile as the original, faring poorly against ground defenses and opposing fighters.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[SMALL_UNITEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[fighter]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 75,
  maxDamage           = 250,
  maxVelocity         = 16,
  minCloakDistance    = 75,
  moverate1           = [[8]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName          = [[ARMFIG]],
  seismicSignature    = 0,
  selfDestructAs      = [[SMALL_UNITEX]],
  separation          = [[2]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:ffmuzzle]],
      [[custom:ffejector]],
      [[custom:ff_engine]],
      [[custom:FF_PUFF]],
      [[custom:ff_wingtips]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 710,
  size                = [[1]],
  sizedecay           = [[0]],
  smoothAnim          = true,
  stages              = [[50]],
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 891,

  weapons             = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    EMG = {
      name                    = [[Air-To-Air EMG]],
      areaOfEffect            = 16,
      burst                   = 2,
      burstrate               = 0.2,
      canattackground         = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 2,
        planes  = 20,
        subs    = 1,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      pitchtolerance          = [[18000]],
      range                   = 700,
      reloadtime              = 0.4,
      renderType              = 4,
      rgbColor                = [[1 0.4 0.25]],
      soundStart              = [[flashemg]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      sweepfire               = false,
      tolerance               = 8000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1150,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Freedom Fighter II]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 250,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[ARMHAM_DEAD]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Freedom Fighter II]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Freedom Fighter II]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 30,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 30,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armfig2 = unitDef })
