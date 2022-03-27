return { gunshipcon = {
  unitname            = [[gunshipcon]],
  name                = [[Wasp]],
  description         = [[Heavy Gunship Constructor]],
  acceleration        = 0.1,
  airStrafe           = 0,
  brakeRate           = 0.08,
  buildCostMetal      = 300,
  buildDistance       = 180,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[GUNSHIPCON.png]],
  buildRange3D        = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 55 55]],
  collisionVolumeType    = [[cylX]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[52 52 52]],
  selectionVolumeType    = [[ellipsoid]],
  collide             = true,
  corpse              = [[DEAD]],
  cruiseAlt           = 80,

  customParams        = {
    airstrafecontrol = [[0]],
    modelradius    = [[15]],
    aimposoffset   = [[0 35 0]],
    midposoffset   = [[0 35 0]],
    custom_height  = [[55]],

    outline_x = 105,
    outline_y = 105,
    outline_yoff = 25,
  },

  energyUse           = 0,
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[builderair]],
  maxDamage           = 1500,
  maxVelocity         = 2.4,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[bumblebee.dae]],
  script              = [[gunshipcon.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  showNanoSpray       = false,
  sightDistance       = 375,
  turnRate            = 500,
  workerTime          = 10,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets = [[0 0 -20]],
      collisionVolumeScales  = [[90 90 60]],
      collisionVolumeType    = [[ellipsoid]],
      object           = [[bumblebee_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
