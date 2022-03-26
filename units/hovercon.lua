return { hovercon = {
  unitname            = [[hovercon]],
  name                = [[Quill]],
  description         = [[Construction Hovercraft]],
  acceleration        = 0.4,
  activateWhenBuilt   = true,
  brakeRate           = 18.0,
  buildCostMetal      = 125,
  buildDistance       = 170,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[hovercon.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[UNARMED HOVER]],
  collisionVolumeOffsets = [[0 2 0]],
  collisionVolumeScales  = [[35 20 40]],
  collisionVolumeType    = [[box]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
    selection_scale = 1.2,
    turnatfullspeed_hover = [[1]],
  },

  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  maxDamage           = 960,
  maxSlope            = 36,
  maxVelocity         = 2.9,
  movementClass       = [[HOVER2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[corch.s3o]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HOVERS_ON_GROUND]],
    },

  },

  showNanoSpray       = false,
  script              = [[hovercon.lua]],
  sightDistance       = 300,
  sonarDistance       = 300,
  turninplace         = 0,
  turnRate            = 1100,
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

} }
