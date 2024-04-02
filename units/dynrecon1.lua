return { dynrecon1 = {
  name                = [[Recon Commander]],
  description         = [[High Mobility Commander]],
  acceleration        = 0.75,
  activateWhenBuilt   = true,
  autoheal            = 5,
  brakeRate           = 2.7,
  buildDistance       = 144,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[commrecon.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 50 45]],
  collisionVolumeType    = [[CylY]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 4.5,
    jump_reload        = 26,
    jump_from_midair   = 1,
    level = [[1]],
    statsname = [[dynrecon1]],
    soundok = [[heavy_bot_move]],
    soundselect = [[bot_select]],
    soundok_vol = [[0.58]],
    soundselect_vol = [[0.5]],
    soundbuild = [[builder_start]],
    commtype = [[3]],
    modelradius    = [[25]],
    aimposoffset   = [[0 10 0]],
    dynamic_comm   = 1,
    shared_energy_gen = 1,
    set_target_range_buffer = 50,
  },

  energyStorage       = 500,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  health              = 3250,
  iconType            = [[commander1]],
  leaveTracks         = true,
  maxSlope            = 36,
  maxWaterDepth       = 5000,
  metalCost           = 1200,
  metalStorage        = 500,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[commrecon.s3o]],
  script              = [[dynrecon.lua]],
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
      [[custom:RAIDMUZZLE]],
      [[custom:NONE]],
      [[custom:VINDIBACK]],
      [[custom:FLASH64]],
    },

  },

  showNanoSpray       = false,
  sightEmitHeight     = 40,
  sightDistance       = 500,
  sonarDistance       = 500,
  speed               = 40.5,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 1620,
  upright             = true,
  workerTime          = 8,
  
  featureDefs         = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[commrecon_dead.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
