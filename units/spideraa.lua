unitDef = {
  unitname               = [[spideraa]],
  name                   = [[Tarantula]],
  description            = [[Anti-Air Spider]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 400,
  buildCostMetal         = 400,
  buildPic               = [[spideraa.png]],
  buildTime              = 400,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Aranha anti-aérea]],
    description_fr = [[Araignée AA]],
	description_de = [[Flugabwehr Spinne]],
	description_pl = [[Pajak przeciwlotniczy]],
    helptext       = [[An all-terrain AA unit that supports other spiders against air with its medium-range missiles.]],
    helptext_bp    = [[Uma unidade escaladora anti-aérea. Use para proteger outras aranhas contra ataques aéreos.]],
    helptext_fr    = [[Une unité araignée lourde anti-air, son missile a décollage vertical est lent à tirer mais très efficace contre des cibles aériennes blindées.]],
	helptext_de    = [[Eine geländegängige Flugabwehreinheit, die andere Spinnen mit ihren mittellangen Raketen gegen Luftangriffe verteidigt.]],
	helptext_pl    = [[Jako pajak, Tarantula jest w stanie wejsc na kazde wzniesienie, aby zapewnic wsparcie przeciwlotnicze swoimi rakietami sredniego zasiegu.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spideraa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1200,
  maxSlope               = 72,
  maxVelocity            = 2.3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[tarantula.s3o]],
  script				 = [[spideraa.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 55,
  turnRate               = 1700,

  weapons                = {

    {
      def                = [[AA]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA = {
      name                    = [[Missiles]],
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
        default = 20,
        planes  = 200,
        subs    = 10,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      range                   = 1000,
      reloadtime              = 2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 400,
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 50000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 450,
    },

  },

  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Tarantula]],
      blocking         = true,
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 160,
      object           = [[tarantula_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
    },

    HEAP  = {
      description      = [[Debris - Tarantula]],
      blocking         = false,
      damage           = 1200,
      energy           = 0,
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 80,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },

  },

}

return lowerkeys({ spideraa = unitDef })
