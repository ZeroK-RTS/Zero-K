unitDef = {
  unitname               = [[gorg]],
  name                   = [[Jugglenaut]],
  description            = [[Heavy Assault Strider]],
  acceleration           = 0.0552,
  bmcode                 = [[1]],
  brakeRate              = 0.1375,
  buildCostEnergy        = 12000,
  buildCostMetal         = 12000,
  builder                = false,
  buildPic               = [[GORG.png]],
  buildTime              = 12000,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[65 65 65]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Mechwarrior d'Assaut]],
    helptext       = [[The Juggernaut is the big daddy to the Sumo. Where its smaller cousin sported the exotic heatray, the Jugg is even more bizzare with its three gravity guns complementing a standard laser cannon. This beast is slow and expensive, but seemingly impervious to enemy fire.]],
    helptext_fr    = [[Le Juggernaut est un quadrip?de lourd et lent, mais ?xtr?mement solide. Il est ?quip? de deux canons laser ? haute fr?quence, et d'un double laser anti gravit? de technologie Newton. Il d?cole les unit?s ennemies du sol et les ?jecte en arri?re tout en les bombardant de ses tirs. Difficilement arr?table, voire la silhouette d'un Juggernaut ? l'horizon est une des pires chose que l'on puisse apercevoir.]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[ESTOR_BUILDINGEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[640]],
  mass                   = 1848,
  maxDamage              = 100000,
  maxSlope               = 36,
  maxVelocity            = 0.8325,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[GORG]],
  pieceTrailCEGRange     = 1,
  pieceTrailCEGTag       = [[trail_huge]],
  seismicSignature       = 4,
  selfDestructAs         = [[ESTOR_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 650,
  smoothAnim             = true,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  turnRate               = 233,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },

  },


  weaponDefs             = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 35,
      impulseFactor           = -120,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 550,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2750,
    },


    LASER       = {
      name                    = [[Heavy Laser Blaster]],
      areaOfEffect            = 24,
      beamWeapon              = true,
      canattackground         = true,
      cegTag                  = [[redlaser_llt]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 2,
      },

      duration                = 0.04,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 30,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      noSelfDamage            = true,
      range                   = 430,
      reloadtime              = 0.17,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      sweepfire               = false,
      targetMoveError         = 0.1,
      thickness               = 4.03112887414927,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1720,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Juggernaut]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 100000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[8]],
      hitdensity       = [[100]],
      metal            = 4800,
      object           = [[GORG_DEAD]],
      reclaimable      = true,
      reclaimTime      = 4800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Juggernaut]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 100000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[2]],
      hitdensity       = [[100]],
      metal            = 4800,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 4800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Juggernaut]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 100000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[2]],
      hitdensity       = [[100]],
      metal            = 2400,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 2400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ gorg = unitDef })
