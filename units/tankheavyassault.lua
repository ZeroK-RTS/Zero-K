unitDef = {
  unitname            = [[tankheavyassault]],
  name                = [[Cyclops]],
  description         = [[Very Heavy Tank Buster]],
  acceleration        = 0.0282,
  brakeRate           = 0.052,
  buildCostMetal      = 2200,
  builder             = false,
  buildPic            = [[tankheavyassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 12000,
  maxSlope            = 18,
  maxVelocity         = 2.05,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[corgol_512.s3o]],
  script              = [[tankheavyassault.lua]],
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance       = 540,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 50,
  turninplace         = 0,
  turnRate            = 312,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[COR_GOL]],
	  badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs          = {

    COR_GOL             = {
      name                    = [[Tankbuster Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
		burst = Shared.BURST_RELIABLE,
	    gatherradius = [[105]],
	    smoothradius = [[70]],
	    smoothmult   = [[0.4]],
		
		light_color = [[3 2.33 1.5]],
		light_radius = 150,
	  },
      
      damage                  = {
        default = 1000,
        subs    = 50,
      },

      explosionGenerator      = [[custom:TESS]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 3.5,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      soundStart              = [[weapon/cannon/rhino]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 310,
    },
	
	SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamTime                = 0.1,
      beamttl                 = 50,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        timeslow_damagefactor = 1,
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
		
		light_camera_height = 1800,
		light_color = [[0.6 0.22 0.8]],
		light_radius = 200,
      },

      damage                  = {
        default = 600,
      },

      explosionGenerator      = [[custom:flashslow]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 440,
      reloadtime              = 1,
      rgbColor                = [[0.27 0 0.36]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 15,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 11,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

    tankheavyassault_FLAMETHROWER = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 64,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideGround           = false,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams        	  = {
		flamethrower = [[1]],
	    setunitsonfire = "1",
		burntime = [[360]],
	  },
	  
      damage                  = {
        default = 5,
        subs    = 0.05,
      },

      duration                = 0.1,
      explosionGenerator      = [[custom:SMOKE]],
      fallOffRate             = 1,
      fireStarter             = 100,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.1,
      interceptedByShieldType = 0,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 0.16,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      texture1				  = [[fireball]],
      texture2				  = [[fireball]],
      thickness	              = 12,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },


  },


  featureDefs         = {

    DEAD       = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[golly_d.s3o]],
    },

	
    HEAP       = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ tankheavyassault = unitDef })
