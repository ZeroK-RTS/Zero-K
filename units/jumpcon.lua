return { jumpcon = {
  unitname            = [[jumpcon]],
  name                = [[Constable]],
  description         = [[Jumpjet Constructor]],
  acceleration        = 0.78,
  brakeRate           = 4.68,
  buildCostMetal      = 140,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[jumpcon.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND UNARMED]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[32 32 32]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 1,
  },

  energyUse           = 0,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  leaveTracks         = true,
  maxDamage           = 550,
  maxSlope            = 36,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[behe_coroner.s3o]],
  script              = [[jumpcon.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:VINDIMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  showNanoSpray       = false,
  sightDistance       = 375,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 1680,
  upright             = true,
  workerTime          = 5,
 
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
      beamttl                 = 30,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        timeslow_damagefactor = 12,
        timeslow_smartretarget = 0.33,
        timeslow_smartretargethealth = 50,
        
        light_camera_height = 1800,
        light_color = [[0.4 0.15 0.55]],
        light_radius = 150,
      },

      damage                  = {
        default = 15,
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
      range                   = 240,
      reloadtime              = 2,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 30,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
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
      object           = [[behe_coroner_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
