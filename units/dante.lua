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
  collisionVolumeTest = 1,
  corpse              = [[DEAD]],
  
  customParams        = {
    description_fr = [[Mechwarrior d'Assaut]],
	description_de = [[Sturm/Riotroboter]],
	description_pl = [[Robot szturmowo-bojowy]],
    helptext       = [[The Dante is a heavy combat unit that specializes in getting close and melting its target. Its flamethrower and twin heatrays aren't extraordinary, but its incendiary rockets can be fired in a salvo of twenty that devastates a wide swath of terrain.]],
    helptext_fr    = [[]],
	helptext_de    = [[Der Dante ist eine schwere Sturmeinheit f? den Fronteinsatz, wenn herkömmliche Mittel versagen. Sein Flammenwerfer und doppelläufiger Heat Ray sind zwar nichts besonderes, doch seine Brandraketen können in 20-Schuss Salven breite Schneisen in das Gelände schlagen.]],
	helptext_pl    = [[Dante to ciezka jednostka bojowa, ktora specjalizuje sie w zadawaniu ciezkich obrazen w bezposredniej walce. Posiada promien cieplny, miotacz ognia i rakiety podpalajace, ktore moze wystrzelic w salwie.]],
  },

  explodeAs           = [[CRAWL_BLASTSML]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[t3riot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  losEmitHeight       = 35,
  mass                = 716,
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

  side                = [[CORE]],
  sightDistance       = 600,
  smoothAnim          = true,
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
	  },
	  
      damage                  = {
        default = 15,
        subs    = 0.15,
      },

	  duration				  = 0.01,
      explosionGenerator      = [[custom:SMOKE]],
	  fallOffRate             = 1,
	  fireStarter             = 100,
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
      cegTag                  = [[HEATRAY_CEG]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

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
      soundStart              = [[Heatraysound]],
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
      explosionGenerator      = [[custom:napalm_koda]],
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
      weaponTimer             = 1.8,
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
	  },
	  
      damage                  = {
        default = 120.8,
        subs    = 6,
      },

      dance                   = 15,
      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:napalm_koda]],
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
      weaponTimer             = 1.8,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
      wobble                  = 8000,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Dante]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 11000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 1400,
      object           = [[dante_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 1400,
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Dante]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 11000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 700,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 700,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ dante = unitDef })
