unitDef = {
  unitname               = [[corcrash]],
  name                   = [[Vandal]],
  description            = [[Anti-air Bot]],
  acceleration           = 0.45,
  brakeRate              = 0.45,
  buildCostEnergy        = 90,
  buildCostMetal         = 90,
  buildPic               = [[CORCRASH.png]],
  buildTime              = 90,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 41 30]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô anti-aéreo]],
    description_es = [[Robot Antiaéreo]],
    description_fr = [[Robot Anti-Air]],
    description_it = [[Robot da contraerea]],
	description_de = [[Flugabwehr Roboter]],
	description_pl = [[Bot przeciwlotniczy]],
    helptext       = [[The Vandal is a cheap, hardy and reliable dedicated anti-air bot. Defenseless vs. land forces.]],
    helptext_bp    = [[O Vandal é um robô anti-ar barato. Dá aos robôs uma vantagem definitiva contra aeronaves. N?o pode ser defender de unidades terrestres.]],
    helptext_es    = [[El Vandal es un robot antiaéreo barato. Ofrece una ventaja definitiva para los kbots contra aviones. No tiene defensas contra unidades de tierra.]],
    helptext_fr    = [[Le Vandal est l'unit? anti-air de base, il tire des missiles guid?s ? une cadence peu rapide. Redoutable en groupe, il sert ? prot?ger bases et troupes.]],
    helptext_it    = [[Il Vandal é un economico robot da contraerea. Offre ai kbot un vantaggio decisivo contro aerei. Non ha difese contro forze terrestre.]],
	helptext_de    = [[Der Vandal ist ein billiger, dedizierter Flugabwehr Roboter, der den Robotern einen bestimmten Vorteil gegenüber Flugzeugen bringt. Schutzlos gegenüber Landstreitkräften.]],
	helptext_pl    = [[Vandal to tani, wytrzymaly i niezawodny bot przeciwlotniczy. Jest bezbronny przeciwko wojskom ladowym.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkeraa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 650,
  maxSlope               = 36,
  maxVelocity            = 2.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[crasher.s3o]],
  script                 = [[corcrash.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:CRASHMUZZLE]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[ARMKBOT_MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    ARMKBOT_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 7.2,
        planes  = 72,
        subs    = 4,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_fury.s3o]],
      noSelfDamage            = true,
      range                   = 880,
      reloadtime              = 2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 650,
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 141,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 850,
    },

  },

  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Vandal]],
      blocking         = true,
      damage           = 650,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 36,
      object           = [[crasher_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
    },

    HEAP = {
      description      = [[Debris - Vandal]],
      blocking         = false,
      damage           = 650,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 18,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 18,
    },

  },

}

return lowerkeys({ corcrash = unitDef })
