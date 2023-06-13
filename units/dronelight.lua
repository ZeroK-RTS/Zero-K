return { dronelight = {
  unitname            = [[dronelight]],
  name                = [[Firefly]],
  description         = [[Attack Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  brakeRate           = 0.24,
  buildCostMetal      = 20,
  builder             = false,
  buildPic            = [[dronelight.png]],
  canBeAssisted       = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP DRONE]],
  collide             = false,
  cruiseAlt           = 85,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[fighter]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  maxDamage           = 180,
  maxVelocity         = 7,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[attackdrone.s3o]],
  reclaimable         = false,
  repairable          = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  refuelTime          = 10,
  script              = [[dronelight.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
    bait_level_target      = 1,
    is_drone = 1,
  },
  
  
  sfxtypes            = {

    explosiongenerators = {
    },

  },
  sightDistance       = 500,
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER      = {
      name                    = [[Light Particle Beam]],
      beamDecay               = 0.9,
      beamTime                = 1/30,
      beamttl                 = 60,
      coreThickness           = 0.25,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,
  
      customParams            = {
        light_camera_height = 1800,
        light_color = [[0.25 1 0.25]],
        light_radius = 130,
      },

      damage                  = {
        default = 32,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 150,
      reloadtime              = 0.8,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/mini_laser]],
      soundStartVolume        = 4,
      thickness               = 2.165,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },
  },

} }
