unitDef = {
  unitname               = [[amphraider]],
  name                   = [[Grebe]],
  description            = [[Amphibious Raider Bot]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.4,
  buildCostEnergy        = 300,
  buildCostMetal         = 300,

  buildoptions           = {
  },

  buildPic               = [[amphraider.png]],
  buildTime              = 300,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[walkerraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 411,
  maxDamage              = 900,
  maxSlope               = 36,
  maxVelocity            = 2.4,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName             = [[amphraider.s3o]],
  script                 = [[amphraider.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  side                   = [[ARM]],
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
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    --{
    --  def                = [[TORPEDO]],
    --  badTargetCategory  = [[FIXEDWING]],
    --  onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
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
      startsmoke              = [[1]],
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
      soundHit                = [[explosion/ex_underwater]],
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
      category         = [[corpses]],
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Grebe]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 900,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphraider = unitDef })
