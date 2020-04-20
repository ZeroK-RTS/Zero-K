return { striderdetriment = {
  unitname               = [[striderdetriment]],
  name                   = [[Detriment]],
  description            = [[Ultimate Assault Strider]],
  acceleration           = 0.328,
  activateWhenBuilt      = true,
  autoheal               = 120,
  brakeRate              = 1.435,
  buildCostMetal         = 20000,
  builder                = false,
  buildPic               = [[striderdetriment.png]],
  canGuard               = true,
  canManualFire          = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 14 0]],
  collisionVolumeScales  = [[92 158 92]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
	canjump            = 1,
    jump_range         = 1500,
    jump_height        = 1000,
    jump_speed         = 12,
    jump_delay         = 100,
    jump_reload        = 40,
    jump_from_midair   = 1,
    jump_rotate_midair = 1,		
    modelradius    = [[95]],
    extradrawrange = 925,
  },

  explodeAs              = [[NUCLEAR_MISSILE]],
  footprintX             = 6,
  footprintZ             = 6,
  iconType               = [[krogoth]],
  leaveTracks            = true,
  losEmitHeight          = 100,
  maxDamage              = 100000,
  maxSlope               = 37,
  maxVelocity            = 1.2,
  maxWaterDepth          = 5000,
  minCloakDistance       = 150,
  movementClass          = [[AKBOT6]],  
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[detriment.s3o]],
  radarDistance          = 1200,
  radarEmitHeight        = 12,
  script                 = [[striderdetriment.lua]],
  selfDestructAs         = [[NUCLEAR_MISSILE]],
  selfDestructCountdown  = 10,
  sfxtypes            = {
    explosiongenerators = {
      [[custom:sumosmoke]],
	  [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
	  [[custom:extra_large_muzzle_flash_flame]],
	  [[custom:extra_large_muzzle_flash_smoke]],	  
	  [[custom:vindiback_large]],
	  [[custom:rocketboots_muzzle]],
    },
  },
  
  sightDistance          = 910,
  sonarDistance          = 910,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.8,
  trackType              = [[ComTrack]],
  trackWidth             = 60,
  turnRate               = 482,
  upright                = true,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	
		
	{
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[SNITCH_LAUNCHER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },
	
	{
      def                = [[LANDING]],
      badTargetCategory  = [[]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[]],
    },
	
	
  },


  weaponDefs             = {
  
	PLASMA  = {
      name                    = [[Heavy Plasma Impulse Cannon]],
	  accuracy                = 2000,
      areaOfEffect            = 384,
      avoidFeature            = false,
      burnBlow                = true,	  
      craterBoost             = 1.5,
      craterMult              = 4.2,

      customParams            = {
	    timeslow_damagefactor = 10,
        light_color = [[2.2 1.6 0.9]],
        light_radius = 550,
      },

      damage                  = {
        default = 800,
        subs    = 800,
      },

      edgeEffectiveness       = 0.5,	  
      explosionGenerator      = [[custom:flashbigbuilding]],
	  explosionSpeed          = 500,	  
      fireStarter             = 99,
      fireTolerance		      = 8192,  
	  impulseBoost            = 3000,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = 6,
      range                   = 600,	  
      reloadtime              = 1,    
      soundHit                = [[weapon/cannon/cannon_hit4]],
      soundHitVolume          = 15,
      soundStart              = [[weapon/cannon/heavy_cannon2]],
	  soundStartVolume        = 16,      
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1100,
    },
	
	CHAINGUN = {
      name                    = [[Heavy Chaingun]],
      accuracy                = 1500,
      alphaDecay              = 0.7,
      areaOfEffect            = 120,
      burnblow                = true,     
      craterBoost             = 0.8,
      craterMult              = 2.2,

      customParams        = {
        light_camera_height = 1600,
        light_color = [[0.8 0.76 0.38]],
        light_radius = 450,
      },

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 2.25,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
	  fireTolerance		      = 8192,	  
      impulseBoost            = 500,
      impulseFactor           = 0.4,
      intensity               = 1.3,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 0.2,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
	  soundHitVolume          = 7,
      soundStart              = [[weapon/sd_emgv7]],
	  soundStartVolume        = 7,	  
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },    
	
	SNITCH_LAUNCHER = {
      name                    = [[Snitch Launcher]],
      areaOfEffect       	  = 384,     
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 10,
      burstrate               = 0.2,      
      commandFire             = true, 
      craterBoost             = 2,
      craterMult              = 5,
      
      customParams            = {
	    burst = Shared.BURST_RELIABLE,        
		
        light_color = [[0.65 0.65 0.18]],
        light_radius = 380,        
		reaim_time = 8, -- COB
      },

      damage                  = {
        default        = 1200,
      },
      
      edgeEffectiveness  = 0.4,
      explosionGenerator = "custom:ROACHPLOSION",
	  explosionSpeed     = 10000,
      fireStarter             = 100,    
      highTrajectory		  = 1,
      impulseBoost            = 2,
      impulseFactor           = 2.8,
      interceptedByShieldType = 2,
      model                   = [[logroach.s3o]], 
	  myGravity               = 0.095,
      noSelfDamage            = true,         
      range                   = 1200,
      reloadtime              = 30,      
      soundHit           	  = "explosion/mini_nuke",
      soundStart              = [[weapon/cannon/pillager_fire]],
      soundStartVolume        = 25,
	  sprayAngle              = 1000, 
      tolerance               = 512,
      turret                  = true,   
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },	
	
	LANDING = {
      name                    = [[Detriment Landing]],
      areaOfEffect            = 900,
      canattackground         = false,
      craterBoost             = 10,
      craterMult              = 12,

      damage                  = {
        default = 6000,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
	  explosionSpeed          = 500,
      impulseBoost            = 6000,
      impulseFactor           = 25,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 5,
      reloadtime              = 13,
      soundHit           	  = "explosion/mini_nuke",
      soundStart              = [[krog_stomp]],
      soundStartVolume        = 10,
      turret                  = false,
      weaponType              = [[Cannon]],
      weaponVelocity          = 5,

      customParams            = {
        hidden = true
      }
    },	
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[Detriment_wreck.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
