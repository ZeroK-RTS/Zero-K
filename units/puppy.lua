unitDef = {
  unitname               = [[puppy]],
  name                   = [[Puppy]],
  description            = [[Walking Missile]],
  acceleration           = 0.24,
  activateWhenBuilt      = true,
  brakeRate              = 0.24,
  buildCostEnergy        = 35,
  buildCostMetal         = 35,
  builder                = false,
  buildPic               = [[PUPPY.png]],
  buildTime              = 35,
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
  },

  explodeAs              = [[TINY_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotbomb]],
  idleAutoHeal           = 5,
  idleTime               = 600,
  leaveTracks            = true,
  mass                   = 66,
  maxDamage              = 40,
  maxSlope               = 36,
  maxVelocity            = 3.1,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING]],
  objectName             = [[puppy.s3o]],
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
      areaOfEffect            = 10,
      cegTag                  = [[VINDIBACK]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 380,
        planes  = 380,
        subs    = 380,
      },

      fireStarter             = 70,
      fixedlauncher           = 0,
      flightTime              = 4.5,
      guidance                = true,
      impulseBoost            = 0.95,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[puppymissile.s3o]],
      noSelfDamage            = true,
      range                   = 390,
      reloadtime              = 4,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 80,
      vlaunch                 = true,
      twoPhase                = true,
      tracks                  = true,
      turnRate                = 30000,
      turret                  = true,
      tolerance               = 12000,
      weaponAcceleration      = 40,
      weaponTimer             = 2.0,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },

  },
  
}

return lowerkeys({ puppy = unitDef })
