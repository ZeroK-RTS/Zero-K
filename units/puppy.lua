unitDef = {
  unitname               = [[puppy]],
  name                   = [[Puppy]],
  description            = [[Walking Missile]],
  acceleration           = 0.24,
  activateWhenBuilt      = true,
  brakeRate              = 0.24,
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
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    description_de = [[Wandernde Rakete]],
    description_pl = [[Chodzaca rakieta]],
    helptext       = [[This fast-moving suicide unit is good for raiding and sniping lightly-armored targets. When standing next to wreckages, it automatically draws metal from them to replicate itself, grey goo style.]],
	helptext_de    = [[Diese flinke Kamikazeinheit ist ideal, um schlecht gepanzerte Ziele zu überfallen. Sobald sie neben Wracks steht, zieht sie automatisch Metall aus diesen, um sich selbst zu vervielfältigen.]],
	helptext_pl    = [[Ta samobojcza jednostka dobrze nadaje sie do najazdow na przeciwnika i niszczeniu lekkich celow. Gdy stoi w poblizu zlomu, samoczynnie pobiera metal i replikuje sie.]],
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
  mass                   = 66,
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

  side                   = [[CORE]],
  sightDistance          = 425,
  smoothAnim             = true,
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
        default = 410,
        planes  = 410,
        subs    = 20.5,
      },

      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 0.8,
      guidance                = true,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[puppymissile.s3o]],
      noSelfDamage            = true,
      range                   = 170,
      reloadtime              = 1,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 300,
      tracks                  = true,
      turnRate                = 56000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },
  
  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Puppy]],
      blocking         = false,
      damage           = 80,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 20,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 20,
    },
	
	DEAD2      = {
      description      = [[Wreckage - Puppy]],
      blocking         = false,
      damage           = 80,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 20,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 20,
    },

    HEAP      = {
      description      = [[Debris - Puppy]],
      blocking         = false,
      damage           = 80,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 10,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 10,
    },

  },
  
}

return lowerkeys({ puppy = unitDef })
