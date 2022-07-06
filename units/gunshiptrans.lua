return { gunshiptrans = {
  unitname            = [[gunshiptrans]],
  name                = [[Charon]],
  description         = [[Air Transport]],
  acceleration        = 0.2,
  brakeRate           = 0.96,
  buildCostMetal      = 100,
  builder             = false,
  buildPic            = [[gunshiptrans.png]],
  canFly              = true,
  canGuard            = true,
  canload             = [[1]],
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP UNARMED]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 16 35]],
  collisionVolumeType    = [[box]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 16 45]],
  selectionVolumeType    = [[cylY]],
  corpse              = [[DEAD]],
  cruiseAlt           = 140,

  customParams        = {
    airstrafecontrol  = [[1]],
    midposoffset      = [[0 0 0]],
    modelradius       = [[15]],
    transport_speed_light   = [[0.7]],
    transport_speed_medium  = [[0.4]],
    islighttransport  = 1, -- Actually maybe this needs to be kept as is, how does Circuit handle it?
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[gunshiptransport]],
  maxDamage           = 300,
  maxVelocity         = 11.5,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[smallTransport.s3o]],
  script              = [[gunshiptrans.lua]],
  releaseHeld         = true,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:ATLAS_ENGINE]],
    },

  },
  sightDistance       = 300,
  transportCapacity   = 1,
  transportMass       = 330,
  transportSize       = 4,
  turninplace         = 0,
  turnRate            = 550,
  verticalSpeed       = 30,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[smalltrans_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
