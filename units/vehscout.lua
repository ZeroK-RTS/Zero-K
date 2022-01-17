return { vehscout = {
  unitname               = [[vehscout]],
  name                   = [[Dart]],
  description            = [[Disruptor Raider/Scout Rover]],
  acceleration           = 0.84,
  brakeRate              = 1.866,
  buildCostMetal         = 40,
  builder                = false,
  buildPic               = [[vehscout.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 0 2]],
  collisionVolumeScales  = [[14 14 40]],
  collisionVolumeType    = [[cylZ]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[25 25 30]],
  selectionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[7]],
    aim_lookahead  = 80,
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[vehiclescout]],
  leaveTracks            = true,
  maxDamage              = 120,
  maxSlope               = 18,
  maxVelocity            = 5.09,
  maxWaterDepth          = 22,
  movementClass          = [[TANK2]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[vehscout.s3o]],
  script                 = [[vehscout.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 1,
  trackStretch           = 1,
  trackType              = [[Motorbike]],
  trackWidth             = 24,
  turninplace            = 0,
  turnRate               = 1755,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    DISRUPTOR      = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 24,
      beamdecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 50,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams            = {
        timeslow_damagefactor = 4,
        
        light_camera_height = 2000,
        light_color = [[0.85 0.33 1]],
        light_radius = 120,
      },
      
      damage                  = {
        default = 32,
      },
  
      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 150,
      reloadtime              = 1,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 3,
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


  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[vehscout_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
