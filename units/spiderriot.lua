unitDef = {
  unitname               = [[spiderriot]],
  name                   = [[Redback]],
  description            = [[Riot Spider]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 280,
  buildCostMetal         = 280,
  buildPic               = [[spiderriot.png]],
  buildTime              = 280,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[36 36 36]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]], 
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[A rapid fire spider which excels at picking off fast units.]],
    description_pl = [[Pajak wsparcia]],
    helptext_pl    = [[Szybkostrzelny pajak, ktory swietnie radzi sobie z niszczeniem lekkich jednostek.]],
    aimposoffset   = [[0 10 0]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 900,
  maxSlope               = 72,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[spiderriot.s3o]],
  script                 = [[spiderriot.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 366,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 55,
  turnRate               = 1700,

  weapons                = {

    {
      def                = [[PARTICLEBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },
  
  weaponDefs             = {

    PARTICLEBEAM = {
      name                    = [[Auto Particle Beam]],
      beamDecay               = 0.85,
      beamTime                = 0.01,
      beamttl                 = 45,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 60.01,
        subs    = 3,
      },

      explosionGenerator      = [[custom:flash1red]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 7.5,
      minIntensity            = 1,
      range                   = 300,
      reloadtime              = 0.33,
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
      description      = [[Wreckage - Tarantula]],
      blocking         = true,
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 112,
      object           = [[tarantula_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
    },

    HEAP  = {
      description      = [[Debris - Tarantula]],
      blocking         = false,
      damage           = 900,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 56,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 56,
    },

  },

}

return lowerkeys({ spiderriot = unitDef })
