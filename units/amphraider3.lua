unitDef = {
  unitname               = [[amphraider3]],
  name                   = [[Duck]],
  description            = [[Amphibious Raider Bot (Sea)]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.375,
  buildCostEnergy        = 200,
  buildCostMetal         = 200,

  buildoptions           = {
  },

  buildPic               = [[amphraider3.png]],
  buildTime              = 200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND SINK]],
  collisionVolumeTest    = 1,
  corpse                 = [[DEAD]],

  customParams           = {
      helptext       = [[The Duck is the basic underwater raider. Armed with short ranged torpedoes, it uses it's (relatively) high speed to harass sea targets that cannot shoot back though it dies to serious opposition. On land it can launch the torpedoes a short distance as a decent short ranged anti-heavy weapon.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[amphtorpraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 390,
  maxDamage              = 400,
  maxSlope               = 36,
  maxVelocity            = 2.7,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP]],
  objectName             = [[amphraider3.s3o]],
  script                 = [[amphraider3.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  sonarDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1000,
  upright                = true,

  weapons                = {
    {
      def                = [[TORPCANNON]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM FIXEDWING HOVER LAND SINK TURRET FLOAT SHIP GUNSHIP]],
    },  
    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP]],
    },
  },


  weaponDefs             = {

    TORPCANNON = {
      name                    = [[Torpedo Projector]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        subs    = 6,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_m_ajax.s3o]],
      myGravity               = 0.1,
      noSelfDamage            = true,
      projectiles	          = 2,
      range                   = 240,
      reloadtime              = 3,
      soundHit                = [[weapon/cannon/cannon_hit2]],
	  soundHitVolume          = 6,
      soundStart              = [[weapon/cannon/mini_cannon]],
	  soundStartVolume        = 8,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 200,
    },
  
    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 32,
      --avoidFriendly           = false,
      --collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 150,
      },

      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:TORPEDO_HIT]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      projectiles	      	  = 2,
      range                   = 240,
      reloadtime              = 3,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 100,
      tolerance               = 1000,
      tracks                  = true,
      turnRate                = 8000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 1,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 140,
    },
  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Duck]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Duck]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 400,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphraider3 = unitDef })
