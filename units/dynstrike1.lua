return { dynstrike1 = {
  unitname               = [[dynstrike1]],
  name                   = [[Strike Commander]],
  description            = [[Mobile Assault Commander]],
  acceleration           = 0.54,
  activateWhenBuilt      = true,
  autoheal               = 5,
  brakeRate              = 2.25,
  buildCostMetal         = 1200,
  buildDistance          = 144,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[commstrike.png]],
  radarDistanceJam       = 175,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 50 45]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    level = [[1]],
    statsname = [[dynstrike1]],
    soundok = [[heavy_bot_move]],
    soundselect = [[bot_select]],
    soundok_vol = [[0.58]],
    soundselect_vol = [[0.5]],
    soundbuild = [[builder_start]],
    commtype = [[1]],
    --decorationicons = {chest = "friendly", shoulders = "arrows-dot"},
    aimposoffset   = [[0 15 0]],
    modelradius    = [[25]],
    dynamic_comm   = 1,
    shared_energy_gen = 1,
    set_target_range_buffer = 50,

    outline_x = 110,
    outline_y = 110,
    outline_yoff = 31.25,
  },

  energyStorage          = 500,
  explodeAs              = [[ESTOR_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[commander1]],
  leaveTracks            = true,
  losEmitHeight          = 40,
  maxDamage              = 4200,
  maxSlope               = 36,
  maxVelocity            = 1.45,
  maxWaterDepth          = 5000,
  metalStorage           = 500,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[strikecom.dae]],
  script                 = [[dynstrike.lua]],
  selfDestructAs         = [[ESTOR_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
        [[custom:BEAMWEAPON_MUZZLE_BLUE]],
        [[custom:NONE]],
    },

  },

  showNanoSpray          = false,
  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 26,
  turnRate               = 1377,
  upright                = true,
  workerTime             = 10,

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[strikecom_dead_1.dae]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },


  },

} }
