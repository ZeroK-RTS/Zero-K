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
    jump_range         = 3000,
    jump_height        = 1500,
    jump_speed         = 8,
    jump_delay         = 100,
    jump_reload        = 120,
    jump_from_midair   = 0,
    jump_rotate_midair = 0,		
    modelradius    = [[95]],
    --extradrawrange = 925, -- Huh? This just adds an extra range that doesn't work.
  },

  explodeAs              = [[ATOMIC_BLAST]],
  footprintX             = 6,
  footprintZ             = 6,
  iconType               = [[krogoth]],
  leaveTracks            = true,
  losEmitHeight          = 100,
  maxDamage              = 100000,
  maxSlope               = 37,
  maxVelocity            = 1.6,
  maxWaterDepth          = 5000,
  minCloakDistance       = 150,
  movementClass          = [[AKBOT6]],  
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[detriment.s3o]],
  radarDistance          = 1200,
  radarEmitHeight        = 12,
  script                 = [[striderdetriment.lua]],
  selfDestructAs         = [[ATOMIC_BLAST]],
  selfDestructCountdown  = 10,
  sfxtypes            = {
    explosiongenerators = {
      [[custom:dirtyfootstep]],
	    [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
	    [[custom:extra_large_muzzle_flash_flame]],
	    [[custom:extra_large_muzzle_flash_smoke]],	  
	    [[custom:vindiback_large]],
	    [[custom:rocketboots_muzzle]],
    },
  },
  
  sightDistance          = 910,
  sonarDistance          = 1200,
  --trackOffset            = 0,
  --trackStrength          = 8,
  --trackStretch           = 0.8,
  --trackType              = [[ComTrack]],
  --trackWidth             = 60,
  turnRate               = 482,
  upright                = true,

  weapons                = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	
		
	{
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SUB SHIP SWIM FLOAT GUNSHIP HOVER]],
    },	

    {
      def                = [[BOMB_LAUNCHER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },
	
	{
      def                = [[LANDING]],
      badTargetCategory  = [[]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[]],
    },
	
	{
      def                = [[FOOTCRATER]],
      badTargetCategory  = [[]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[]],
    },
	
	{
      def                = [[TAKEOFF]],
      badTargetCategory  = [[]],
      mainDir            = [[1 0 0]],
      maxAngleDif        = 0,
      onlyTargetCategory = [[]],
    },
	
	
	
	
  },


  weaponDefs             = {
  
	GAUSS         = {
      name                    = [[Gauss Battery]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      --burst                   = 3,
      --burstrate               = 0.4,
      cegTag                  = [[gauss_tag_h]],
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams = {
        single_hit_multi = true,
        reaim_time = 1,
      },

      damage                  = {
        default = 500.1,        
      },

      explosionGenerator      = [[custom:gauss_hit_h]],
      groundbounce            = 1,
	  heightBoostFactor       = 0, -- stops shooting at ground while jumping
	  heightMod			      = 1.2,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 600,
      reloadtime              = 0.4,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 2.0,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 900,
      stages                  = 32,
	  fireTolerance		      = 16384,  
      tolerance               = 16384,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 900,
    },
	
	BOMB_LAUNCHER = {
      name                    = [[Bomb Launcher]],
      areaOfEffect       	  = 384,     
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 12,
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
      model                   = [[zeppelin_bomb.dae]], 
	  myGravity               = 0.095,
      noSelfDamage            = true,         
      range                   = 1200,
      reloadtime              = 60,      
      soundHit           	  = "explosion/mini_nuke",
      soundStart              = [[weapon/cannon/pillager_fire]],
      soundStartVolume        = 25,
	  sprayAngle              = 1500, 
      tolerance               = 16384,
      turret                  = true,   
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },	
	
	LANDING = {
      name                    = [[Detriment Landing]],
      areaOfEffect            = 500,
      canattackground         = false,
      craterBoost             = 100,
      craterMult              = 15,

      damage                  = {
        default = 6000,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
	  explosionSpeed          = 500,
      impulseBoost            = 1000,
      impulseFactor           = 25,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 120,
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
	
	FOOTCRATER = {
      name                    = [[Detriment walking]],
	  areaOfEffect			  = 10,
      craterAreaOfEffect      = 150,
      canattackground         = false,
      craterBoost             = 20,
      craterMult              = 15,

      damage                  = {
        default = 200.1,        
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:dirtyfootstep]],	  
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 5,
      reloadtime              = 13,
      soundHit                = [[weapon/cannon/reaper_hit]],
     
      soundHitVolume        = 1,
      turret                  = false,
      weaponType              = [[Melee]],
      weaponVelocity          = 5,

      customParams            = {
        hidden = true
      }
    },
	
	TAKEOFF = {
      name                    = [[Detriment Takeoff]],
      areaOfEffect            = 500,
      canattackground         = false,
      craterBoost             = 30,
      craterMult              = 15,

      damage                  = {
        default = 1000,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
	  explosionSpeed          = 500,
      impulseBoost            = 100,
      impulseFactor           = 10,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 120,
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
