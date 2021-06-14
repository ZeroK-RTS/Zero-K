return { droneheavyslow = {
  unitname            = [[droneheavyslow]],
  name                = [[Viper]],
  description         = [[Advanced Battle Drone]],
  acceleration        = 0.3,
  airHoverFactor      = 4,
  brakeRate           = 0.24,
  buildCostMetal      = 35,
  builder             = false,
  buildPic            = [[droneheavyslow.png]],
  canBeAssisted       = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[GUNSHIP DRONE]],
  collide             = false,
  cruiseAlt           = 95,
  explodeAs           = [[TINY_BUILDINGEX]],
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  hoverAttack         = true,
  iconType            = [[gunship]],
  idleAutoHeal        = 10,
  idleTime            = 300,
  maxDamage           = 430,
  maxVelocity         = 5,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[battledrone.s3o]],
  reclaimable         = false,
  repairable          = false, -- mostly not to waste constructor attention on area-repair; has regen anyway
  script              = [[droneheavyslow.lua]],
  selfDestructAs      = [[TINY_BUILDINGEX]],
  
  customParams        = {
    bait_level_target      = 2,
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
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 20,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

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
        timeslow_damagefactor = [[2]],
        
        light_camera_height = 2000,
        light_color = [[0.85 0.33 1]],
        light_radius = 150,
      },
      
      damage                  = {
        default = 200,
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
      range                   = 200,
      reloadtime              = 2,
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
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  },

} }
