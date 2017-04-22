unitDef = {
  unitname            = [[corch]],
  name                = [[Quill]],
  description         = [[Construction Hovercraft, Builds at 5 m/s]],
  acceleration        = 0.066,
  activateWhenBuilt   = true,
  brakeRate           = 1.5,
  buildCostMetal      = 150,
  buildDistance       = 160,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[CORCH.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[UNARMED HOVER]],
  collisionVolumeOffsets = [[0 2 0]],
  collisionVolumeScales  = [[35 20 40]],
  collisionVolumeType    = [[box]],  
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Hovercraft de Construction, Construit r 5 m/s]],
	description_de = [[Konstruktionsluftkissenboot, Baut mit 5 M/s]],
    helptext       = [[The Quill allows smooth expansion across both land and sea.]],
    helptext_fr    = [[L'Hovercon est rapide et agile mais son blindage et ses nanoconstructeurs sont de mauvaise facture.]],
    helptext_de    = [[Quill erlaubt dir leichtgängige Expansionen über Land und See.]],
	modelradius    = [[15]],
  },

  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 800,
  maxSlope            = 36,
  maxVelocity         = 2.8,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[corch.s3o]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
    },

  },

  showNanoSpray       = false,
  script              = [[corch.lua]],
  sightDistance       = 325,
  sonarDistance       = 325,
  turninplace         = 0,
  turnRate            = 550,
  workerTime          = 5,

  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corch_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ corch = unitDef })
