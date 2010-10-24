unitDef = {
  unitname            = [[corgarp]],
  name                = [[Wolverine]],
  description         = [[Artillery Minelayer Vehicle]],
  acceleration        = 0.0282,
  bmcode              = [[1]],
  brakeRate           = 0.0412,
  buildCostEnergy     = 260,
  buildCostMetal      = 260,
  builder             = false,
  buildPic            = [[corgarp.png]],
  buildTime           = 260,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Tanque de artilharia]],
    description_fr = [[Tank Artilleur]],
    helptext       = [[The Wolverine fires in high trajectory so it's not suitable for use against moving units. It can comfortably outrange Heavy Laser Towers. It can't fire backwards and is unmanouverable. Protect it against raider charges with a screen of riot or assault units.]],
    helptext_bp    = [[Wolverine é o veículo de artilharia leve de Logos. Seus tiros s?o de alta trajetória ent?o n?o funciona bem contra unidades móveis. Seu alcançe supera com folga o de torres de laser pesadas, mas é pouco ágil e n?o pode atirar para trás, devendo ser protegido de agressores por linhas de unidades dispesadoras ou de assalto.]],
    helptext_fr    = [[Le Wolverine est l'arme idéale pour prendre d'assaut les zones fortifiées. Une grande portée, des tirs en cloche et une cadence de tir respectable en font une artillerie trcs bon marché. Peu rapide et ne pouvant pas tirer en arricre, il faudra cependant la protéger.]],
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
  maneuverleashlength = [[650]],
  mass                = 151,
  maxDamage           = 380,
  maxSlope            = 18,
  maxVelocity         = 2.5,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName          = [[corwolv.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:wolvmuzzle0]],
      [[custom:wolvmuzzle1]],
      [[custom:wolvflash]],
    },

  },

  side                = [[CORE]],
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
  turnRate            = 399,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MINE]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    MINE = {
      name                    = [[Light Mine Artillery]],
      accuracy                = 500,
      areaOfEffect            = 96,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:dirt]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.3,
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 5,
      renderType              = 4,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      startsmoke              = [[1]],
      targetMoveError         = 0.1,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Wolverine]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 380,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[0]],
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[corwolv_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[all]],
    },


    DEAD2 = {
      description      = [[Debris - Wolverine]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 380,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Wolverine]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 380,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corgarp = unitDef })
