unitDef = {
  unitname               = [[amphraider]],
  name                   = [[Grebe]],
  description            = [[Amphibious Raider Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,
  buildPic               = [[amphraider.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
      description_pl = [[Lekki bot amfibijny]],
      helptext       = [[The Grebe is a basic raider armed with grenades - a decent short ranged anti-heavy weapon. Despite being amphibious, it cannot shoot while submerged.]],
      helptext_pl    = [[Grebe to lekki bot z granatami krotkiego zasiegu, ktore dobrze sprawdzaja sie przeciwko ciezszym celom. Mimo ze jest amfibijny, nie moze atakowac spod wody.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 900,
  maxSlope               = 36,
  maxVelocity            = 2.4,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[amphraider.s3o]],
  script                 = [[amphraider.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  sightDistance          = 500,
  sonarDistance          = 300,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[GRENADE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    --{
    --  def                = [[TORPEDO]],
    --  badTargetCategory  = [[FIXEDWING]],
    --  onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    --},
  },

  weaponDefs             = {

	GRENADE = {
      name                    = [[Grenade Launcher]],
      accuracy                = 200,
      areaOfEffect            = 96,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 240,
        planes  = 240,
        subs    = 12,
      },

      explosionGenerator      = [[custom:PLASMA_HIT_96]],
      fireStarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 2,
      model                   = [[diskball.s3o]],
      projectiles             = 2,
      range                   = 360,
      reloadtime              = 3,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med6]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/cannon/cannon_fire3]],
      soundStartVolume        = 2,
      soundTrigger			= true,
      sprayangle              = 512,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
	},

	TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        subs    = 200,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      flightTime              = 6,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_t_longbolt.s3o]],
      noSelfDamage            = true,
      range                   = 400,
      reloadtime              = 3,
      soundHit                = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torpedo]],
      startVelocity           = 90,
      tolerance               = 1000,
      tracks                  = true,
      turnRate                = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 25,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 140,
    },

  },

  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Grebe]],
      blocking         = true,
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      metal            = 120,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
    },

    HEAP      = {
      description      = [[Debris - Grebe]],
      blocking         = false,
      damage           = 900,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
    },

  },

}

return lowerkeys({ amphraider = unitDef })
