return { amphtele = {
  unitname               = [[amphtele]],
  name                   = [[Djinn]],
  description            = [[Amphibious Teleport Bridge]],
  acceleration           = 0.75,
  activateWhenBuilt      = true,
  brakeRate              = 4.5,
  buildCostMetal         = 750,
  buildPic               = [[amphtele.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[36 49 36]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 30,
    amph_submerged_at = 40,

    teleporter = 1,
    teleporter_throughput = 150, -- mass per second
    teleporter_beacon_spawn_time = 8,
    teleporter_beacon_unit = [[tele_beacon]],
  },

  explodeAs              = [[BIG_UNIT]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[amphtransport]],
  leaveTracks            = true,
  maxDamage              = 2500,
  maxSlope               = 36,
  maxVelocity            = 2.5,
  movementClass          = [[AKBOT3]],
  objectName             = [[amphteleport.s3o]],
  script                 = [[amphtele.lua]],
  pushResistant          = 0,
  selfDestructAs         = [[BIG_UNIT]],
  sightDistance          = 300,
  sonarDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 24,
  turnRate               = 840,

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphteleport_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
