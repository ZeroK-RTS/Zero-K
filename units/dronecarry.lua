return { dronecarry = {
  unitname            = [[dronecarry]],
  name                = [[Gull]],
  description         = [[Carrier Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  brakeRate           = 0.24,
  buildCostMetal      = 15,
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
  cruiseAlt           = 100,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[smallgunship]],
  maneuverleashlength = [[900]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  maxDamage           = 180,
  maxVelocity         = 8.56,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[carrydrone.s3o]],
  reclaimable         = false,
  repairable          = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  script              = [[dronecarry.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
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
  turnRate            = 792,
  upright             = true,

  weapons             = {

    {
      def                = [[ARM_DRONE_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    ARM_DRONE_WEAPON = {
      name                    = [[Drone EMG]],
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0,
      craterMult              = 0,
  
      customParams            = {
        light_camera_height = 2000,
        light_color = [[0.95 0.91 0.48]],
        light_radius = 150,
      },

      damage                  = {
        default = 8,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      range                   = 360,
      reloadtime              = 0.3,
      rgbColor                = [[1 0.95 0.4]],
      size                    = 1.75,
      soundStart              = [[weapon/emg]],
      soundStartVolume        = 2,
      sprayAngle              = 512,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },

  },

} }
