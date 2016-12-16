unitDef = {
  unitname            = [[dante]],
  name                = [[Dante]],
  description         = [[Assault/Riot Strider]],
  acceleration        = 0.0984,
  brakeRate           = 0.2392,
  buildCostEnergy     = 3500,
  buildCostMetal      = 3500,
  builder             = false,
  buildPic            = [[dante.png]],
  buildTime           = 3500,
  canAttack           = true,
  canDGun             = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],
  
  customParams        = {
    description_fr = [[Mechwarrior d'Assaut]],
	description_de = [[Sturm/Riotroboter]],
    helptext       = [[The Dante is a heavy combat unit that specializes in getting close and melting its target. Its flamethrower and twin heatrays aren't extraordinary, but its incendiary rockets can be fired in a salvo of twenty that devastates a wide swath of terrain.]],
    helptext_fr    = [[]],
	helptext_de    = [[Der Dante ist eine schwere Sturmeinheit f? den Fronteinsatz, wenn herkömmliche Mittel versagen. Sein Flammenwerfer und doppelläufiger Heat Ray sind zwar nichts besonderes, doch seine Brandraketen können in 20-Schuss Salven breite Schneisen in das Gelände schlagen.]],
  },

  explodeAs           = [[CRAWL_BLASTSML]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[t3riot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  losEmitHeight       = 50,
  maxDamage           = 11000,
  maxSlope            = 36,
  maxVelocity         = 1.75,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[dante.s3o]],
  script			  = [[dante.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[CRAWL_BLASTSML]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:SLASHMUZZLE]],
      [[custom:SLASHREARMUZZLE]],
      [[custom:RAIDMUZZLE]],
    },
  },
  sightDistance       = 600,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 0.6,
  trackType           = [[ComTrack]],
  trackWidth          = 38,
  turnRate            = 597,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM_ROCKETS]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[HEATRAY]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[NAPALM_ROCKETS_SALVO]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DANTE_FLAMER]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs          = {

    DANTE_FLAMER         = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 96,
      avoidGround             = false,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideGround           = false,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,
	  cegTag                  = [[flamer]],

	  customParams        	  = {
		flamethrower = [[1]],
	    setunitsonfire = "1",
		burntime = [[450]],

		light_camera_height = 1800,
        light_color = [[0.6 0.39 0.18]],
		light_radius = 260,
		light_fade_time = 13,
		light_beam_mult_frames = 5,
		light_beam_mult = 5,
	  },
	  
      damage                  = {
        default = 15,
        subs    = 0.15,
      },

	  duration				  = 0.01,
      explosionGenerator      = [[custom:SMOKE]],
	  fallOffRate             = 1,
	  fireStarter             = 100,
	  heightMod               = 1,
	  impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.3,
      interceptedByShieldType = 1,
      noExplode               = true,
      noSelfDamage            = true,
	  --predictBoost			  = 1,
      range                   = 340,
      reloadtime              = 0.16,
	  rgbColor                = [[1 1 1]],
	  soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
	  texture1				  = [[flame]],
	  thickness	              = 0,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },


    HEATRAY              = {
      name                    = [[Heat Ray]],
      accuracy                = 512,
      areaOfEffect            = 20,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		light_camera_height = 2000,
		light_color = [[0.9 0.4 0.12]],
		light_radius = 180,
		light_fade_time = 35,
		light_fade_offset = 10,
		light_beam_mult_frames = 9,
		light_beam_mult = 8,
	  },
	  
      damage                  = {
        default = 49,
        planes  = 49,
        subs    = 2.45,
      },

      duration                = 0.3,
      dynDamageExp            = 1,
      dynDamageInverted       = false,
      explosionGenerator      = [[custom:HEATRAY_HIT]],
      fallOffRate             = 1,
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      projectiles             = 2,
      proximityPriority       = 4,
      range                   = 430,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.1 0]],
      rgbColor2               = [[1 1 0.25]],
      soundStart              = [[weapon/heatray_fire]],
      thickness               = 3,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 500,
    },

    NAPALM_ROCKETS       = {
      name                    = [[Napalm Rockets]],
      areaOfEffect            = 228,
      burst                   = 2,
      burstrate               = 0.1,
	  cegTag                  = [[missiletrailredsmall]],
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
	    setunitsonfire = "1",
	    burnchance = "1",
	  },
	  
      damage                  = {
        default = 120.8,
        subs    = 6,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:napalm_phoenix]],
      fireStarter             = 250,
      fixedlauncher           = true,
      flightTime              = 1.8,
      impulseBoost            = 0,
      impulseFactor           = 0.1,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      range                   = 460,
      reloadtime              = 2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rapid_rocket_hit]],
      soundStart              = [[weapon/missile/rapid_rocket_fire]],
      sprayAngle              = 1000,
      startVelocity           = 150,
      tolerance               = 6500,
      tracks                  = false,
      turnRate                = 8000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
      wobble                  = 10000,
    },


    NAPALM_ROCKETS_SALVO = {
      name                    = [[Napalm Rocket Salvo]],
      areaOfEffect            = 228,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      burst                   = 10,
      burstrate               = 0.1,
      cegTag                  = [[missiletrailredsmall]],
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
	    setunitsonfire = "1",
	    burnchance = "1",
		
		light_color = [[0.8 0.4 0.1]],
		light_radius = 320,
	  },
	  
      damage                  = {
        default = 120.8,
        subs    = 6,
      },

      dance                   = 15,
      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:napalm_phoenix]],
      fireStarter             = 250,
      fixedlauncher           = true,
      flightTime              = 1.8,
      impulseBoost            = 0,
      impulseFactor           = 0.1,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      projectiles			  = 2,
      range                   = 460,
      reloadtime              = 20,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rapid_rocket_hit]],
      soundStart              = [[weapon/missile/rapid_rocket_fire]],
      sprayAngle              = 8000,
      startVelocity           = 200,
      tolerance               = 6500,
      tracks                  = false,
      trajectoryHeight        = 0.18,
      turnRate                = 3000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
      wobble                  = 8000,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[dante_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ dante = unitDef })
