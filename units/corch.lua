unitDef = {
  unitname            = [[corch]],
  name                = [[Hovercon]],
  description         = [[Construction Hovercraft, Builds at 6 m/s]],
  acceleration        = 0.06,
  bmcode              = [[1]],
  brakeRate           = 0.062,
  buildCostEnergy     = 150,
  buildCostMetal      = 150,
  buildDistance       = 90,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[CORCH.png]],
  buildTime           = 150,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canreclamate        = [[1]],
  canstop             = [[1]],
  category            = [[UNARMED HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft de Construction, Construit r 6 m/s]],
    helptext_fr    = [[L'Hovercon est rapide et agile mais son blindage et ses nanoconstructeurs sont de mauvaise facture.]],
  },

  defaultmissiontype  = [[Standby]],
  energyMake          = 0.15,
  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 75,
  maxDamage           = 900,
  maxSlope            = 36,
  maxVelocity         = 2.7,
  metalMake           = 0.15,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[corch.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
    },

  },

  showNanoSpray       = false,
  side                = [[CORE]],
  sightDistance       = 325,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[CNSTR]],
  terraformSpeed      = 300,
  turninplace         = 0,
  turnRate            = 410,
  workerTime          = 6,

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Hovercon]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[corch_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Hovercon]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hovercon]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 30,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 30,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corch = unitDef })
