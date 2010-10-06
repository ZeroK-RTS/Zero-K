unitDef = {
  unitname            = [[tawf013]],
  name                = [[Shellshocker]],
  description         = [[Light Artillery Vehicle]],
  acceleration        = 0.02,
  bmcode              = [[1]],
  brakeRate           = 0.02,
  buildCostEnergy     = 160,
  buildCostMetal      = 160,
  builder             = false,
  buildPic            = [[TAWF013.png]],
  buildTime           = 160,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Veículo de artilharia leve]],
    description_fr = [[Véhicule d'Artillerie Léger]],
    helptext       = [[The Shellshocker fires in high trajectory so it's not suitable for use against moving units. It can comfortably outrange Heavy Laser Towers. It can't fire backwards and is unmanouverable. Protect it against raider charges with a screen of riot or assault units.]],
    helptext_bp    = [[Shellshocker é o veículo de artilharia leve de Nova. Sua trajetória de disparo é alta ent?o n?o funciona bem contra unidades móveis. Ele pode facilmente superar o alcançe de torres de laser pesadas. N?o pode atirar para trás e é pouco ágil. Protega-o de agressores com linhas de unidades de assaulto ou dispersadoras. ]],
    helptext_fr    = [[Le Shellshocker tire en cloche r l'aide de son canon plasma. Il est donc inutile contre les cibles mouvantes mais sa grande portée le rends indispensable pour prendre d'assaut une place forte. Il convient bien entendu de le protéger r l'aide d'émeutiers ou d'autres unités. ]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  highTrajectory      = 1,
  iconType            = [[vehiclearty]],
  idleAutoHeal        = 5,
  idleTime            = 3200,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 80,
  maxDamage           = 300,
  maxSlope            = 18,
  maxVelocity         = 2.7,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName          = [[TAWF013]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:shellshockflash]],
      [[custom:SHELLSHOCKSHELLS]],
      [[custom:SHELLSHOCKGOUND]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 300,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    PLASMA = {
      name                    = [[Light Plasma Artillery]],
      accuracy                = 240,
      areaOfEffect            = 88,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 190,
        planes  = 190,
        subs    = 9.5,
      },

      explosionGenerator      = [[custom:WEAPEXP_PUFF]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      noSelfDamage            = true,
      range                   = 850,
      reloadtime              = 4.5,
      renderType              = 4,
      soundHit                = [[TAWF113b]],
      soundStart              = [[TAWF113a]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Shellshocker]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[24]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[TAWF013_DEAD]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Shellshocker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Shellshocker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 300,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 32,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ tawf013 = unitDef })
