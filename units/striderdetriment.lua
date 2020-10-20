return { striderdetriment = {
  unitname               = [[striderdetriment]],
  name                   = [[Detriment]],
  description            = [[Ultimate Assault Strider]],
  acceleration           = 0.328,
  activateWhenBuilt      = true,
  autoheal               = 60,
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
    jump_range         = 1200,
    jump_height        = 700,
    jump_speed         = 8,
    jump_delay         = 100,
    jump_reload        = 120,
    jump_from_midair   = 1,
    jump_rotate_midair = 1,		
    modelradius    = [[95]],
    extradrawrange = 700, -- Huh? This just adds an extra range that doesn't work.
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
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.6,
  trackType              = [[ComTrack]],
  trackWidth             = 60,
  turnRate               = 400,
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
      def                = [[AALASER]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },
	
	{
      def                = [[TRILASER]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	},

    {
      def                = [[WEAPON]],
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
      burst                   = 3,
      burstrate               = 0.6,
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
      range                   = 550,
      reloadtime              = 2.5,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 2.0,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 900,
      stages                  = 32,
	  fireTolerance		      = 4000,  
      tolerance               = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 900,
    },
	
	AALASER         = {
      name                    = [[Anti-Air Laser Battery]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        reaim_time = 1,
      },

      damage                  = {
        default = 2.05,
        planes  = 20.5,
        subs    = 1.125,
      },
      
      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.75,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 820,
      reloadtime              = 0.1,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      thickness               = 2.5,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

    TRILASER = {
      name                    = [[High-Energy Laserbeam]],
      areaOfEffect            = 14,
      beamTime                = 0.8,
      beamttl                 = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_color = [[0.2 0.8 0.2]],
        reaim_time = 1,
      },
      
      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 45,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 90,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10.4,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 3,
      range                   = 700,
      reloadtime              = 6,
      rgbColor                = [[0 1 0]],
      scrollSpeed             = 5,
      soundStart              = [[weapon/laser/heavy_laser3]],
      soundStartVolume        = 2,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tileLength              = 300,
	  fireTolerance		      = 4200, -- about 50 degrees
      tolerance               = 4200, -- about 50 degrees
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },
	
	BOMB_LAUNCHER = {
      name                    = [[Bomb Launcher]],
      areaOfEffect       	  = 384,     
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 12,
      burstrate               = 0.4, 
	  cegTag                  = [[tactrail]],	  
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
	  myGravity               = 1.0,
      noSelfDamage            = true,         
      range                   = 1000,
      reloadtime              = 60,      
      soundHit           	  = "explosion/mini_nuke",
      soundStart              = [[weapon/missile/tacnuke_launch2_trimmed]],
      --soundStartVolume        = 15,
	  sprayAngle              = 1000, 
      tolerance               = 16384,
      turret                  = true,   
      weaponType              = [[Cannon]],
      weaponVelocity          = 1200,
    },	
	
	
	WEAPON = {
      name                    = [[Swarm Missiles]],
      areaOfEffect            = 150,
      --accuracy                = 500,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 8,
      burstrate               = 0.5,
	  --projectiles             = 8,
      cegTag                  = [[seismictrail]],
      commandFire             = true,
      craterBoost             = 1,
      craterMult              = 2,
      
      customParams            = {
	    gatherradius = [[300]],
        smoothradius = [[150]],
        detachmentradius = [[150]],
        smoothmult   = [[1]],
        smoothexponent = [[0.45]],
        movestructures = [[1]],
        combatrange = 900,
        light_color = [[1 1.4 0.35]],
        light_radius = 400,
        reaim_time = 1,
      },

      damage                  = {
        default        = 1200,
      },

      dance                   = 30,
      edgeEffectiveness  = 0.4,
      explosionGenerator = "custom:ROACHPLOSION",
	  explosionSpeed     = 10000,
      fireStarter             = 100,
      fixedlauncher           = true,
      flightTime              = 30,
	  --highTrajectory		  = 1,
      impulseBoost            = 2,
      impulseFactor           = 2.8,
      interceptedByShieldType = 2,
      model                   = [[wep_m_kickback.s3o]],
      range                   = 925,
      reloadtime              = 50,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
	  sprayAngle              = 12000, 
      soundStartVolume        = 5,
	  soundHitVolume          = 5,
      startVelocity           = 300,
      tracks                  = false,      
      turnRate                = 9000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 8000,
    },
	
	LANDING = {
      name                    = [[Detriment Landing]],
      areaOfEffect            = 500,
      canattackground         = false,
      craterBoost             = 100,
      craterMult              = 15,

      damage                  = {
        default = 2000,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
	  explosionSpeed          = 500,
      impulseBoost            = 10,
      impulseFactor           = 2,
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
      areaOfEffect            = 300,
      canattackground         = false,
      craterBoost             = 2,
      craterMult              = 5,

      damage                  = {
        default = 500,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:FLASH64]],
	  explosionSpeed          = 500,
      impulseBoost            = 2,
      impulseFactor           = 2,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 120,
      soundHit           	  = "explosion/mini_nuke",
      soundStart              = [[krog_stomp]],
      soundStartVolume        = 5,
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
