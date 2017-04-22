unitDef = {
  unitname               = [[spideraa]],
  name                   = [[Tarantula]],
  description            = [[Anti-Air Spider]],
  acceleration           = 0.22,
  brakeRate              = 0.66,
  buildCostMetal         = 400,
  buildPic               = [[spideraa.png]],
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Araign�e AA]],
	description_de = [[Flugabwehr Spinne]],
    helptext       = [[An all-terrain AA unit that supports other spiders against air with its medium-range missiles.]],
    helptext_fr    = [[Une unit� araign�e lourde anti-air, son missile a d�collage vertical est lent � tirer mais tr�s efficace contre des cibles a�riennes blind�es.]],
	helptext_de    = [[Eine gel�ndeg�ngige Flugabwehreinheit, die andere Spinnen mit ihren mittellangen Raketen gegen Luftangriffe verteidigt.]],
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
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[tarantula.s3o]],
  script				 = [[spideraa.lua]],
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
		light_color = [[0.58 0.7 0.7]],
	  },

      damage                  = {
        default = 20,
        planes  = 220.5,
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
      reloadtime              = 1.9,
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[tarantula_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ spideraa = unitDef })
