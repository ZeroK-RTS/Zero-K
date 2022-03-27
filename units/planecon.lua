return { planecon = {
  unitname            = [[planecon]],
  name                = [[Crane]],
  description         = [[Construction Aircraft]],
  acceleration        = 0.1,
  airStrafe           = 0,
  brakeRate           = 0.08,
  buildCostMetal      = 200,
  buildDistance       = 160,
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[planecon.png]],
  buildRange3D        = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP UNARMED]],
  collisionVolumeOffsets        = [[0 0 -5]],
  collisionVolumeScales         = [[42 8 42]],
  collisionVolumeType           = [[cylY]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 80,

  customParams        = {
    airstrafecontrol = [[0]],
    modelradius    = [[10]],
    midposoffset   = [[0 4 0]],

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 7.5,
  },

  energyUse           = 0,
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[builderair]],
  maxDamage           = 260,
  maxVelocity         = 6,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[crane.s3o]],
  script              = [[planecon.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  showNanoSpray       = false,
  sightDistance       = 375,
  turnRate            = 500,
  workerTime          = 5,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[crane_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
