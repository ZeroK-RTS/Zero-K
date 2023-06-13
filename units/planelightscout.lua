return { planelightscout = {
  unitname            = [[planelightscout]],
  name                = [[Sparrow]],
  description         = [[Light Scout Plane]],
  brakerate           = 0.4,
  buildCostMetal      = 235,
  builder             = false,
  buildPic            = [[planelightscout.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[UNARMED FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[14 14 45]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],
  cruiseAlt           = 220,

  customParams        = {
    bait_level_target      = 2,

    modelradius    = [[8]],
    refuelturnradius = [[130]],

    outline_x = 75,
    outline_y = 75,
    outline_yoff = 10,
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[scoutplane]],
  maxAcc              = 0.5,
  maxDamage           = 350,
  maxAileron          = 0.016,
  maxElevator         = 0.022,
  maxRudder           = 0.012,
  maxVelocity         = 7,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[planelightscout.s3o]],
  script              = [[planelightscout.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 950,
  turnRadius          = 50,
  workerTime          = 0,

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[planelightscout_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
