unitDef = {
  unitname               = [[striderscorpion]],
  name                   = [[Scorpion]],
  description            = [[Cloaked Infiltration Strider]],
  acceleration           = 0.26,
  brakeRate              = 0.78,
  buildCostMetal         = 3000,
  builder                = false,
  buildPic               = [[striderscorpion.png]],
  canGuard               = true,
  canManualFire          = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 2,
  cloakCostMoving        = 10,
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[85 85 85]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
  },

  explodeAs              = [[CRAWL_BLASTSML]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3spidergeneric]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked			 = true,
  leaveTracks            = true,
  maxDamage              = 12000,
  maxSlope               = 72,
  maxVelocity            = 1.3,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[scorpion.s3o]],
  script				 = [[striderscorpion.lua]],
  selfDestructAs         = [[CRAWL_BLASTSML]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],	  
    },

  },
  sightDistance          = 517,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType				 = [[crossFoot]],
  trackWidth             = 76,
  turnRate               = 400,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FAKELASER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 30,
    },  
    
    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[MULTILIGHTNING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	
	
    {
      def                = [[PARTICLEBEAM]],
	  mainDir            = [[-0.2 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
    {
      def                = [[PARTICLEBEAM]],
	  mainDir            = [[0.2 0 1]],
      maxAngleDif        = 240,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
	
  },


  weaponDefs             = {
    
    FAKELASER     = {
      name                    = [[Fake Laser]],
      areaOfEffect            = 12,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
        subs    = 0,
      },

      duration                = 0.11,
      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 70,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5.53,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 0.11,
      rgbColor                = [[0 1 0]],
      soundStart              = [[weapon/laser/laser_burn5]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5.53,
      tolerance               = 10000,
      turret                  = false,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 900,
    },
    
    LIGHTNING = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = 1080,
		
		light_camera_height = 1600,
		light_color = [[0.85 0.85 1.2]],
		light_radius = 200,
        gui_draw_range = 450,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 360,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzeTime            = 3,
      range                   = 490,
      reloadtime              = 2,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      sprayAngle              = 700,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },
	
    MULTILIGHTNING = {
      name                    = [[Multi-Stunner]],
      areaOfEffect            = 160,
      avoidFeature            = false,
	  burst					  = 20,
	  burstRate				  = 0.1,
	  commandFire			  = true,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 0,

      customParams            = {
		light_color = [[0.7 0.7 0.2]],
		light_radius = 320,
        gui_draw_range = 450,
      },

      damage                  = {
        default        = 1001,
      },

      duration                = 8,
      dynDamageExp            = 0,
      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 0,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 3,
      range                   = 490,
      reloadtime              = 30,
      rgbColor                = [[1 1 0.25]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = false,
	  sprayAngle			  = 2048,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },	

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
        default = 70.01,
        subs    = 3,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      range                   = 420,
      reloadtime              = 0.3 + 1/30,
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
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[scorpion_dead.s3o]],
    },
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ striderscorpion = unitDef })
