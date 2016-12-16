unitDef = {
  unitname            = [[slowmort]],
  name                = [[Moderator]],
  description         = [[Distruptor Skirmisher Walker]],
  acceleration        = 0.2,
  activateWhenBuilt   = true,
  brakeRate           = 0.6,
  buildCostEnergy     = 240,
  buildCostMetal      = 240,
  builder             = false,
  buildPic            = [[slowmort.png]],
  buildTime           = 240,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Kurzstrahl Roboter]],
    helptext       = [[The Moderator's disruptor beam reduces enemy speed and rate of fire by up to 50% in addition to dealing damage, making it effective against almost all targets.]],
    helptext_de    = [[Seine verlangsamender Strahl reduziert die Geschwindigkeit feindlicher Einheiten und die Feuerrate um bis zu 50%, deshalb sind sie effektiv gegen fast alle Ziele.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[fatbotsupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 450,
  maxSlope            = 36,
  maxVelocity         = 1.9,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB UNARMED]],
  objectName          = [[CORMORT.s3o]],
  script              = [[slowmort.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:NONE]],
    },

  },

  sightDistance       = 660,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 0.8,
  trackType           = [[ComTrack]],
  trackWidth          = 14,
  turnRate            = 2400,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DISRUPTOR_BEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DISRUPTOR_BEAM = {
    name                    = [[Disruptor Pulse Beam]],
	  areaOfEffect            = 32,
	  beamdecay               = 0.9,
	  beamTime                = 1/30,
	  beamttl                 = 50,
	  coreThickness           = 0.25,
	  craterBoost             = 0,
	  craterMult              = 0,
      
	  customparams = {
	    timeslow_damagefactor = 3,
		
		light_color = [[1.88 0.63 2.5]],
		light_radius = 320,
	  },

	  damage                  = {
	  	default = 500.1,
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
	  range                   = 420,
	  reloadtime              = 10,
	  rgbColor                = [[0.3 0 0.4]],
	  soundStart              = [[weapon/laser/heavy_laser5]],
	  soundStartVolume        = 3,
	  soundTrigger            = true,
	  texture1                = [[largelaser]],
	  texture2                = [[flare]],
	  texture3                = [[flare]],
	  texture4                = [[smallflare]],
	  thickness               = 12,
	  tolerance               = 18000,
	  turret                  = true,
	  weaponType              = [[BeamLaser]],
	  weaponVelocity          = 500,
	},
  
    DISRUPTOR_BOMB = {
	  name                    = [[Disruptor Bomb]],
	  accuracy                = 92,
	  areaOfEffect            = 64,
	  cegTag                  = [[beamweapon_muzzle_purple]],
	  craterBoost             = 0,
	  craterMult              = 0,

	  customParams            = {
		timeslow_damagefactor = 3,
	  },

	  damage                  = {
		default = 350,
		planes  = 350,
		subs    = 17.5,
	  },

	  explosionGenerator      = [[custom:riotball_small]],
	  explosionSpeed          = 5,
	  fireStarter             = 100,
	  impulseBoost            = 0,
	  impulseFactor           = 0,
	  interceptedByShieldType = 2,
	  model                   = [[wep_b_fabby.s3o]],
	  range                   = 520,
	  reloadtime              = 6,
	  smokeTrail              = true,
	  soundHit                = [[weapon/aoe_aura]],
	  soundHitVolume          = 3,
	  soundStart              = [[weapon/cannon/cannon_fire3]],
	  --startVelocity           = 350,
	  --trajectoryHeight        = 0.3,
	  turret                  = true,
	  weaponType              = [[Cannon]],
	  weaponVelocity          = 350,
	},
  
    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamTime                = 0.1,
      beamttl                 = 40,
      coreThickness           = 0.1,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 175,
      },

      customparams = {
        timeslow_damagefactor = 1,
        timeslow_onlyslow = 1,
        timeslow_smartretarget = 0.33,
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
      range                   = 600,
      reloadtime              = 1,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 11,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[CORMORT_DEAD.s3o]],
    },


    HEAP  = {
      blocking    = false,
      footprintX  = 2,
      footprintZ  = 2,
      object      = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ slowmort = unitDef })
