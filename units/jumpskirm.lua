return { jumpskirm = {
  unitname            = [[jumpskirm]],
  name                = [[Moderator]],
  description         = [[Disruptor Skirmisher Walker]],
  acceleration        = 0.6,
  activateWhenBuilt   = true,
  brakeRate           = 3.6,
  buildCostMetal      = 240,
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
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 1,
    dontfireatradarcommand = '1',
    selection_scale   = 0.85,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 15.5,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[fatbotsupport]],
  leaveTracks         = true,
  maxDamage           = 480,
  maxSlope            = 36,
  maxVelocity         = 1.9,
  maxWaterDepth       = 22,
  movementClass       = [[KBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB UNARMED DRONE]],
  objectName          = [[CORMORT.s3o]],
  script              = [[jumpskirm.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:NONE]],
    },

  },

  sightDistance       = 473,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 0.8,
  trackType           = [[ComTrack]],
  trackWidth          = 14,
  turnRate            = 2880,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DISRUPTOR_BEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DISRUPTOR_BEAM = {
    name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 32,
      beamdecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 30,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        burst = Shared.BURST_RELIABLE,

        timeslow_damagefactor = 4,
        timeslow_overslow_frames = 2*30,

        light_color = [[1.88 0.63 2.5]],
        light_radius = 320,
      },

      damage                  = {
          default = 460.1,
      },

      explosionGenerator      = [[custom:heavy_disruptor_beam_hit]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 420,
      reloadtime              = 10,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 3.8,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 12,
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
