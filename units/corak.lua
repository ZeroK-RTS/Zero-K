unitDef = {
  unitname               = [[corak]],
  name                   = [[Bandit]],
  description            = [[Medium-Light Raider Bot]],
  acceleration           = 0.384,
  brakeRate              = 0.25,
  buildCostEnergy        = 80,
  buildCostMetal         = 80,
  builder                = false,
  buildPic               = [[CORAK.png]],
  buildTime              = 80,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[25 29 25]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô agressor]],
    description_es = [[Robot de invasión]],
    description_fr = [[Robot Pilleur]],
    description_it = [[Robot d'invasione]],
    helptext       = [[As a raider, the Bandit sacrifices raw firepower for survivability. It is somewhat tougher than the Glaive, but still not something that you hurl against entrenched forces. Counter with riot units and LLTs.]],
    helptext_bp    = [[O AK é um rob? agressor. ? um pouco mais forte que seu equivalente de Nova, mas ainda algo que voç? n?o envia contra forças entrincheiradas. Defenda-se dele com unidades dispersadoras e torres de laser leve.]],
    helptext_es    = [[Como unidad de invasión, el Bandit sacrifica poder de fuego en favor de supervivencia. es un poco mas resistente de su euivalente Nova, pero como quiera no es para lanzarlo en contra de enemigos atrincherados. Se contrastan con unidades de alboroto y llt.]],
    helptext_fr    = [[Le Bandit est plus puissant que sa contre partie ennemie, le Glaive. Il n'est cependant pas tr?s puissant et ne passera pas contre quelques d?fenses: LLT ou ?meutiers. ]],
    helptext_it    = [[Come unita d'invasione, il Bandit sacrifica potenza di fuoco per sopravvivenza. ? pi? resistente del suo equivalente Nova, ma comnque non ? da mandare contro nemici ben difesi. Si contrastano con unita da rissa ed llt.]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 10,
  idleTime               = 150,
  leaveTracks            = true,
  mass                   = 88,
  maxDamage              = 250,
  maxSlope               = 36,
  maxVelocity            = 3.15,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[mbot.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 500,
  smoothAnim             = true,
  TEDClass               = [[KBOT]],
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turninplace            = 0,
  turnRate               = 1200,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Laser Blaster]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 8,
        planes  = 8,
        subs    = 0.4,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 0.107,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/small_laser_fire2]],
      soundTrigger            = true,
      targetMoveError         = 0.15,
      thickness               = 2.54950975679639,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Bandit]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 250,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 32,
      object           = [[mbot_d.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Bandit]],
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
      metal            = 32,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 32,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Bandit]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 16,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 16,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corak = unitDef })
