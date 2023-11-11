return { spiderriot = {
  name                   = [[Redback]],
  description            = [[Riot Spider]],
  acceleration           = 0.66,
  brakeRate              = 3.96,
  buildPic               = [[spiderriot.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[40 36 48]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 4]],
  selectionVolumeScales  = [[68 45 76]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    aimposoffset       = [[0 10 0]],
    aim_lookahead      = 80,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  health                 = 900,
  iconType               = [[spiderriot]],
  leaveTracks            = true,
  maxSlope               = 72,
  maxWaterDepth          = 22,
  metalCost              = 240,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spiderriot.s3o]],
  script                 = [[spiderriot.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 366,
  speed                  = 52.5,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 55,
  turnRate               = 1938,

  weapons                = {

    {
      def                = [[PARTICLEBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },
  
  weaponDefs             = {

    PARTICLEBEAM = {
      name                    = [[Auto Particle Beam]],
      beamDecay               = 0.85,
      beamTime                = 1/30,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        light_color = [[0.9 0.22 0.22]],
        light_radius = 80,
      },

      damage                  = {
        default = 80.01,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      range                   = 300,
      reloadtime              = 0.3,
      rgbColor                = [[1 0 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 6,
      thickness               = 5,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
    
  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[tarantula_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
