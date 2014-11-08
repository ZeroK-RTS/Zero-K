unitDef = {
  unitname               = [[corbats]],
  name                   = [[Warlord]],
  description            = [[Battleship (Bombardment)]],
  acceleration           = 0.039,
  brakeRate              = 0.0475,
  buildAngle             = 16384,
  buildCostEnergy        = 3800,
  buildCostMetal         = 3800,
  builder                = false,
  buildPic               = [[CORBATS.png]],
  buildTime              = 3800,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  cantBeTransported      = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[45 45 260]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Navire de Guerre Lourd]],
	description_de = [[Schlachtschiff (Bombardierung)]],
	description_pl = [[Pancernik]],
    helptext       = [[A single salvo from one of these will pummel almost any surface target into submission. The psychological effects of the muzzle flash and the ship recoiling in the water are impressive enough, to say nothing of the effects of a direct hit. Be warned--battleships are not meant to be used on their own, lacking in anti-air and anti-submarine protection as they are.]],
    helptext_fr    = [[Le Warlord est le seigneur des mers. Sa quadruple batterie de canon plasma lourd peut pilonner ind?finiment une position, sachant qu'un seul tir peut venir ? bout de la plupart des unit?s. L'effet psychologique est aussi d?vastateur que son bombardement. Il n'est cependant pas fait pour ?tre utilis? seul, malgr? son lourd blindage, il est vuln?rable aux attaques rapides, sousmarines ou aeriennes.]],
	helptext_de    = [[Eine einzige Salve wird einfach jedes Oberfl�chenziel in Einzelteile zerschmettern. Die psychologischen Auswirkungen der M�ndungsfeuer und die R�ckst��e des Schiffes sind beeindruckend genug, ganz zu schweigen von den Auswirkungen, die ein Volltreffer erzeugt. Sei gewarnt - Schlachtschiffe sind nicht dazu gedacht, alleine, auf eigene Faust zu agieren, da ihnen dazu die n�tige Luft- und U-Boot-Abwehr fehlt.]],
	helptext_pl    = [[Jedna salwa z pancernika jest w stanie poradzic sobie z wiekszoscia celow na powierzchni lub ladzie. Wymaga jednak ochrony przed jednostkami podwodnymi i powietrznymi.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 6,
  footprintZ             = 6,
  highTrajectory         = 2,
  iconType               = [[battleship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 776,
  maxDamage              = 12000,
  maxVelocity            = 2.2,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[BOAT6]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName             = [[battleship.s3o]],
  radarDistance          = 2400,
  script                 = [[corbats.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:xamelimpact]],
      [[custom:ROACHPLOSION]],
      [[custom:shellshockflash]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 660,
  turninplace            = 0,
  turnRate               = 216,
  waterLine              = 4,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },


    {
      def                = [[PLASMA]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 330,
	  badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Long-Range Plasma Battery]],
      areaOfEffect            = 96,
      avoidFeature            = false,
	  avoidGround             = false,
      burst                   = 3,
      burstrate               = 0.2,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 500,
        planes  = 500,
        subs    = 25,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_96]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-25]],
      projectiles             = 1,
      range                   = 1400,
      reloadtime              = 10,
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

    DEAD = {
      description      = [[Wreckage - Warlord]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 1520,
      object           = [[BATTLESHIP_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 1520,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Warlord]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 7,
      footprintZ       = 7,
      hitdensity       = [[100]],
      metal            = 760,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 760,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corbats = unitDef })
