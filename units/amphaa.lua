unitDef = {
  unitname               = [[amphaa]],
  name                   = [[Angler]],
  description            = [[Amphibious AA Bot]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  brakeRate              = 0.375,
  buildCostEnergy        = 220,
  buildCostMetal         = 220,

  buildoptions           = {
  },

  buildPic               = [[amphaa.png]],
  buildTime              = 220,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canStop                = true,
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 20,
    amph_submerged_at = 40,
	description_de = [[Amphibischer Luftabwehrbot]],
    description_pl = [[Amfibijny Bot Przeciwlotniczy]],
    helptext       = [[Angler is amphibious AA designed to counter the factory's nemesis - Raven. Two of them together can float to the surface and kill a single Raven.]],
    helptext_de    = [[Der Angler ist dafür konzipiert, Raven-Bomber vom Himmel zu holen, die eine besondere Gefahr für amphibische Einheiten darstellen. Je zwei von ihnen können zur Wasseroberfläche schwimmen und einen Raven mit einer Salve ausschalten.]],
	helptext_pl    = [[Angler to amfibijna jednostka przeciwlotnicza zaprojektowana, by likwidowac glowne lotnicze zagrozenie dla amfibii - bombowiec Raven. Dwa Anglery moga wyplynac na powierzchnie i zestrzelic pojedynczego Ravena.]],
    floattoggle = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 36,
  maxVelocity            = 1.6,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[amphaa.s3o]],
  script                 = [[amphaa.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
	  [[custom:STORMMUZZLE]],
	  [[custom:STORMBACK]],
    },
  },

  sightDistance          = 660,
  sonarDistance          = 250,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 30,
  turnRate               = 1000,
  upright                = true,

  weapons                = {

    {
      def                = [[MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    MISSILE = {
      name                    = [[Missile Pack]],
      areaOfEffect            = 48,
      burst                   = 4,
      burstRate               = 0.7,
      canAttackGround         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

      customParams            = {
          isaa = [[1]],
      },

      damage                  = {
        default = 14.5,
        planes  = 145,
        subs    = 8,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 10,
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

    DEAD      = {
      description      = [[Wreckage - Angler]],
      blocking         = true,
      damage           = 1100,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 88,
      object           = [[amphaa_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
    },

    HEAP      = {
      description      = [[Debris - Angler]],
      blocking         = false,
      damage           = 1100,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 44,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
    },

  },

}

return lowerkeys({ amphaa = unitDef })
