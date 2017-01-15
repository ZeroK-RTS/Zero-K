unitDef = {
  unitname               = [[corstorm]],
  name                   = [[Rogue]],
  description            = [[Skirmisher Bot (Indirect Fire)]],
  acceleration           = 0.25,
  brakeRate              = 0.2,
  buildCostEnergy        = 120,
  buildCostMetal         = 120,
  buildPic               = [[CORSTORM.png]],
  buildTime              = 120,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 42 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Skirmisher Roboter (Indirektes Feuer)]],
    description_fr = [[Robot Tirailleur]],
    helptext       = [[The Rogue's arcing rockets have a low rate of fire, but do a lot of damage, making it very good at dodging in and out of range of enemy units or defense, or in a powerful initial salvo. Counter them by attacking them with fast units, or crawling bombs when massed.]],
    helptext_de    = [[Der Rogue nutzt Raketen mit einer geringen Feuerrate, dafür aber mit großem Schaden. Von daher eignet er sich gut gegen Verteidigung. Gegen schnelle Einheiten sieht er alledings recht alt aus.]],
    helptext_fr    = [[Le Rogue est un tirailleur typique: longue port?e, cadence de tir lente et faible blindage. Ces deux puissants missiles ? t?tes chercheuse sont tr?s puissant mais cette unit? doit fuir le corps ? corps ? tout prix.]],
	aimposoffset   = [[0 5 0]],
	midposoffset   = [[0 -3 0]],
	modelradius    = [[14]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 570,
  maxSlope               = 36,
  maxVelocity            = 1.95,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[storm.s3o]],
  script                 = [[corstorm.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  sightDistance          = 583,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[STORM_ROCKET]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {

    STORM_ROCKET = {
      name                    = [[Heavy Rocket]],
      areaOfEffect            = 75,
      cegTag                  = [[missiletrailred]],
      craterBoost             = 1,
      craterMult              = 2,

      customParams        = {
		light_camera_height = 1800,
      },
	  
      damage                  = {
        default = 280,
        planes  = 280,
        subs    = 16.25,
      },

      fireStarter             = 70,
      flightTime              = 3.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 530,
      reloadtime              = 7,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med4]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/missile2_fire_bass]],
      soundStartVolume        = 7,
      startVelocity           = 170,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      trajectoryHeight        = 0.6,
      turnrate                = 1000,
      turret                  = true,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 170,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[storm_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ corstorm = unitDef })
