unitDef = {
  unitname               = [[puppy]],
  name                   = [[Puppy]],
  description            = [[Walking Missile]],
  acceleration           = 0.24,
  activateWhenBuilt      = true,
  brakeRate              = 0.72,
  buildCostEnergy        = 50,
  buildCostMetal         = 50,
  builder                = false,
  buildPic               = [[PUPPY.png]],
  buildTime              = 50,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    description_de = [[Wandernde Rakete]],
    helptext       = [[This fast-moving suicide unit is good for raiding and sniping lightly-armored targets. When standing next to wreckages, it automatically draws metal from them to replicate itself, grey goo style.]],
	helptext_de    = [[Diese flinke Kamikazeinheit ist ideal, um schlecht gepanzerte Ziele zu überfallen. Sobald sie neben Wracks steht, zieht sie automatisch Metall aus diesen, um sich selbst zu vervielfältigen.]],
	modelradius    = [[10]],

	grey_goo = 1,
	grey_goo_spawn = "puppy",
	grey_goo_drain = 5,
	grey_goo_cost = 75,
	grey_goo_range = 120,
  },

  explodeAs              = [[TINY_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 80,
  maxSlope               = 36,
  maxVelocity            = 3.5,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING]],
  objectName             = [[puppy.s3o]],
  script                 = [[puppy.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[TINY_BUILDINGEX]],
  selfDestructCountdown  = 5,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:digdig]],
    },

  },
  sightDistance          = 560,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.6,
  trackType              = [[ComTrack]],
  trackWidth             = 12,
  turnRate               = 1800,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    MISSILE = {
      name                    = [[Legless Puppy]],
      areaOfEffect            = 40,
      cegTag                  = [[VINDIBACK]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 410.1,
        planes  = 410.1,
        subs    = 20.5,
      },

      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 0.8,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[puppymissile.s3o]],
      noSelfDamage            = true,
      range                   = 170,
      reloadtime              = 1,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startVelocity           = 300,
      tracks                  = true,
      turnRate                = 56000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2a.s3o]],
    },
	
	HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },
  
}

return lowerkeys({ puppy = unitDef })
