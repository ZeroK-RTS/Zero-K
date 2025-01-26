return { planelightscout = {
  name                = [[Sparrow]],
  description         = [[Light Scout/Radar Jammer Plane]],
  brakerate           = 0.4,
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
  cruiseAltitude      = 220,

  customParams        = {
    bait_level_target      = 2,

    boost_speed_mult = 5,
    boost_accel_mult = 2,
    boost_duration   = 90,
    boost_detonate   = 1,

    scan_radius_base = 400,
    scan_radius_max  = 640,
    scan_frames      = 12 * 30,

    modelradius      = [[8]],
    refuelturnradius = [[130]],

    outline_x = 75,
    outline_y = 75,
    outline_yoff = 10,
  },

  explodeAs           = [[PLANELIGHTSCOUT_DEATH]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  health              = 350,
  iconType            = [[scoutplane]],
  maxAcc              = 0.6,
  maxAileron          = 0.017,
  maxElevator         = 0.023,
  maxRudder           = 0.012,
  metalCost           = 230,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[planelightscout.s3o]],
  radarDistanceJam    = 640,
  script              = [[planelightscout.lua]],
  selfDestructAs      = [[PLANELIGHTSCOUT_DEATH]],
  selfDestructCountdown  = 0,
  
  sfxtypes               = {

    explosiongenerators = {
      [[custom:scan_trail]],
    },

  },
  sightDistance       = 950,
  speed               = 210,
  turnRadius          = 30,
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

  weaponDefs = {
    PLANELIGHTSCOUT_DEATH = {
      name               = "Scanner Payload",
      areaOfEffect       = 16,
      craterBoost        = 1,
      craterMult         = 3,
      damage = {
        default          = 150.1,
      },
     
      edgeEffectiveness  = 0.4,
      explosionGenerator = "custom:scan_explode",
      soundHit           = [[explosion/scan_explode]],
      soundHitVolume     = 4,
    },
  }
} }
