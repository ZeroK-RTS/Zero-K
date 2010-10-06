unitDef = {
  unitname            = [[armbeaver]],
  name                = [[Beaver]],
  description         = [[Construction Amph, Builds at 6 m/s]],
  acceleration        = 0.03388,
  bmcode              = [[1]],
  brakeRate           = 0.1166,
  buildCostEnergy     = 140,
  buildCostMetal      = 140,
  buildDistance       = 100,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[armbeaver.png]],
  buildTime           = 140,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  canstop             = [[1]],
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Unité de Construction Amphibie, Construit r 6 m/s]],
    description_pl = [[Konstruktor Amfibia, Buduje z pr?dko?ci? 6 m/s]],
    helptext_fr    = [[Le Beaver est un tank de construcion étanche, ce qui lui permet d'acccder r des zones inattendues mais son étanchéité r joué en la défaveur de sa vitesse.]],
    helptext_pl    = [[Beaver to pojazd budowniczy funkcjonuj?cy zarówno na l?dzie jak i pod wod?.]],
  },

  defaultmissiontype  = [[Standby]],
  energyMake          = 0.15,
  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 70,
  maxDamage           = 925,
  maxSlope            = 36,
  maxVelocity         = 2.9,
  maxWaterDepth       = 5000,
  metalMake           = 0.15,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[armbeaver]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  showNanoSpray       = false,
  side                = [[ARM]],
  sightDistance       = 266,
  smoothAnim          = true,

  sounds              = {
    build          = [[ota/nanlath1]],
    canceldestruct = [[ota/cancel2]],

    cant           = {
      [[ota/cantdo4]],
    },


    count          = {
      [[ota/count6]],
      [[ota/count5]],
      [[ota/count4]],
      [[ota/count3]],
      [[ota/count2]],
      [[ota/count1]],
    },


    ok             = {
      [[ota/varmmove]],
    },

    repair         = [[ota/repair1]],

    select         = {
      [[ota/varmsel]],
    },

    underattack    = [[ota/warning1]],
    working        = [[ota/reclaim1]],
  },

  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  terraformSpeed      = 300,
  trackOffset         = 0,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 31,
  turninplace         = 0,
  turnRate            = 435,
  workerTime          = 6,

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Beaver]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 925,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 56,
      object           = [[armbeaver_dead]],
      reclaimable      = true,
      reclaimTime      = 56,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Beaver]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 925,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 56,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 56,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Beaver]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 925,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 28,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 28,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armbeaver = unitDef })
