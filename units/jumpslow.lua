return { jumpslow = {
  name                = [[Beam Mod]],
  description         = [[Disruptor Skirmisher Walker]],
  acceleration        = 0.6,
  activateWhenBuilt   = true,
  brakeRate           = 3.6,
  builder             = false,
  buildPic            = [[jumpskirm.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
-- A box collision volume, while better matching the model, seems to increase friendly fire
--  collisionVolumeOffsets        = [[0 0 0]],
--  collisionVolumeScales         = [[30 30 20]],
--  collisionVolumeType           = [[box]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[63 63 63]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump            = 1,
    bait_level_default = 1,
    dontfireatradarcommand = '1',
    selection_scale   = 0.78,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 15.5,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  health              = 480,
  iconType            = [[fatbotsupport]],
  leaveTracks         = true,
  maxSlope            = 36,
  maxWaterDepth       = 22,
  metalCost           = 240,
  movementClass       = [[KBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB UNARMED DRONE]],
  objectName          = [[CORMORTGUN.s3o]],
  script              = [[jumpslow.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  sightDistance       = 473,
  speed               = 57,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1.25,
  trackType           = [[ComTrack]],
  trackWidth          = 14,
  turnRate            = 2880,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamTime                = 0.1,
      beamttl                 = 50,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
        
        light_camera_height = 1800,
        light_color = [[0.6 0.22 0.8]],
        light_radius = 200,
      },

      damage                  = {
        default = 2000,
      },

      explosionGenerator      = [[custom:flashslow]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 2.5,
      rgbColor                = [[0.27 0 0.36]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 15,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 11,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets        = [[0 -5 -15]],
      collisionVolumeScales         = [[20 20 30]],
      collisionVolumeType           = [[box]],
      object           = [[cormort_dead_no_gun.s3o]],
    },


    HEAP  = {
      blocking    = false,
      footprintX  = 2,
      footprintZ  = 2,
      object      = [[debris2x2a.s3o]],
    },

  },

} }
