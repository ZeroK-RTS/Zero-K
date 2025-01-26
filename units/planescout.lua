return { planescout = {
  name                = [[Owl]],
  description         = [[Radar/Sonar Scout Plane]],
  brakerate           = 0.4,
  builder             = false,
  buildPic            = [[planescout.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[UNARMED FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[40 15 75]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAltitude      = 250,

  customParams        = {
    modelradius       = [[20]],
    --specialreloadtime = [[600]],
    refuelturnradius  = [[120]],
    priority_misc     = 2, -- High
    sonar_can_be_disabled = 1,
    disable_radar_preview = 1,

    outline_x = 120,
    outline_y = 120,
    outline_yoff = 20,
  },

  energyUpkeep        = 1.5,
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  health              = 950,
  iconType            = [[radarplane]],
  maxAcc              = 0.5,
  maxAileron          = 0.018,
  maxElevator         = 0.02,
  maxRudder           = 0.008,
  metalCost           = 340,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[armpnix.s3o]],
  radarDistance       = 2400,
  script              = [[planescout.lua]],
  selfDestructAs      = [[GUNSHIPEX]],
  sightDistance       = 1400,
  sonarDistance       = 700,
  speed               = 360,
  turnRadius          = 60,
  workerTime          = 0,

  featureDefs         = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[35 12 60]],
      collisionVolumeType    = [[box]],
      object           = [[armpnix_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
