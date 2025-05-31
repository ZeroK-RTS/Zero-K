return { dronecarry = {
  name                = [[Gull]],
  description         = [[Carrier Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 3,
  brakeRate           = 0.6,
  builder             = false,
  buildPic            = [[dronecarry.png]],
  canBeAssisted       = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP DRONE]],
  collisionVolumeOffsets   = [[0 0 0]],
  collisionVolumeScales    = [[26 26 26]],
  collisionVolumeType      = [[ellipsoid]],
  collide             = false,
  cruiseAltitude      = 80,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  health              = 260,
  hoverAttack         = true,
  iconType            = [[smallgunship]],
  maneuverleashlength = [[900]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  metalCost           = 15,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[carrydrone.s3o]],
  reclaimable         = false,
  repairable          = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  script              = [[dronecarry.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],
  stealth                = true,
  
  customParams        = {
    bait_level_target      = 1,
    is_drone = 1,
    modelradius    = [[13]],
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },
  sightDistance       = 500,
  speed               = 256.8,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[CAPTURERAY]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 30,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CAPTURERAY = {
      name                    = [[Capture Ray]],
      beamdecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 1,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        capture_scaling = 1,
        is_capture = 1,
        capture_to_drone_controller = 1,
        post_capture_reload = 150,

        stats_hide_damage = 1, -- continuous laser
        stats_hide_reload = 1,
        
        light_radius = 120,
        light_color = [[0 0.6 0.15]],
        combatrange = 230,
      },

      damage                  = {
        default = 12,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      largeBeamLaser          = true,
      laserFlareSize          = 0,
      minIntensity            = 1,
      range                   = 250,
      reloadtime              = 1/30,
      rgbColor                = [[0 0.8 0.2]],
      scrollSpeed             = 2.5,
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 0.28,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[dosray]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 2.6,
      tolerance               = 12000,
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 150,
    },

  },

} }
