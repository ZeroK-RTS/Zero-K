unitDef = {
  unitname               = [[corbats]],
  name                   = [[Warlord]],
  description            = [[Battleship (Bombardment)]],
  acceleration           = 0.039,
  bmcode                 = [[1]],
  brakeRate              = 0.0475,
  buildAngle             = 16384,
  buildCostEnergy        = 4600,
  buildCostMetal         = 4600,
  builder                = false,
  buildPic               = [[CORBATS.png]],
  buildTime              = 4600,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 20 0]],
  collisionVolumeScales  = [[60 50 260]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Navire de Guerre Lourd]],
    helptext       = [[A single salvo from one of these will pummel almost any surface target into submission. The psychological effects of the muzzle flash and the ship recoiling in the water are impressive enough, to say nothing of the effects of a direct hit. Be warned--battleships are not meant to be used on their own, lacking in anti-air and anti-submarine protection as they are.]],
    helptext_fr    = [[Le Warlord est le seigneur des mers. Sa quadruple batterie de canon plasma lourd peut pilonner ind?finiment une position, sachant qu'un seul tir peut venir ? bout de la plupart des unit?s. L'effet psychologique est aussi d?vastateur que son bombardement. Il n'est cependant pas fait pour ?tre utilis? seul, malgr? son lourd blindage, il est vuln?rable aux attaques rapides, sousmarines ou aeriennes.]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 6,
  footprintZ             = 6,
  HighTrajectory         = 2,
  iconType               = [[battleship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[640]],
  mass                   = 776,
  maxDamage              = 10000,
  maxVelocity            = 2.8,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[BOAT6]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName             = [[battleship.s3o]],
  radarDistance          = 2400,
  script				 = [[corbats.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  
  sfxtypes            = {
    explosiongenerators = {
      [[custom:ROACHPLOSION]],
      [[custom:EXP_MEDIUM_BUILDING_SMALL]],
	  [[custom:shellshockflash]],
    },
  },

  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  steeringmode           = [[1]],
  TEDClass               = [[SHIP]],
  turninplace            = 0,
  turnRate               = 216,
  waterLine              = 4,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 330,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Long-Range Plasma Battery]],
      areaOfEffect            = 96,
      burst                   = 3,
      burstrate               = 0.2,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 450,
        planes  = 450,
        subs    = 22.5,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_96]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-25]],
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 1400,
      reloadtime              = 10,
      renderType              = 4,
      soundHit                = [[explosion/ex_large4]],
      soundStart              = [[explosion/ex_large5]],
      sprayAngle              = 768,
      startsmoke              = [[1]],
      tolerance               = 4096,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 425,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Warlord]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 10000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 6,
      footprintZ       = 6,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 1840,
      object           = [[BATTLESHIP_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 1840,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Warlord]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 10000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 7,
      footprintZ       = 7,
      hitdensity       = [[100]],
      metal            = 1840,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 1840,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Warlord]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 10000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 7,
      footprintZ       = 7,
      hitdensity       = [[100]],
      metal            = 920,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 920,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corbats = unitDef })
