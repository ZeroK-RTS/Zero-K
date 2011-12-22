unitDef = {
  unitname               = [[amphaa]],
  name                   = [[Angler]],
  description            = [[Amphibious AA/Torpedo Bot]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.375,
  buildCostEnergy        = 350,
  buildCostMetal         = 350,

  buildoptions           = {
  },

  buildPic               = [[amphaa.png]],
  buildTime              = 350,
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
  iconType               = [[walkeraa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 390,
  maxDamage              = 1200,
  maxSlope               = 36,
  maxVelocity            = 1.6,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER]],
  objectName             = [[amphaa.s3o]],
  script                 = [[amphaa.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
	  [[custom:THUDMUZZLE]],
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  sonarDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 22,
  turnRate               = 1000,
  upright                = true,

  weapons                = {
  
    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP]],
    },  
  
    {
      def                = [[FLAK]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },
	
  },


  weaponDefs             = {
  
    TORPEDO = {
      name                    = [[Torpedo Launcher]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_t_longbolt.s3o]],
      numbounce               = 4,
      range                   = 450,
      reloadtime              = 2.5,
      soundHit                = [[explosion/ex_underwater]],
      soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponTimer             = 3,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 320,
    },
  
  
    FLAK = {
      name                    = [[Flak Cannon]],
      accuracy                = 100,
      areaOfEffect            = 64,
      burnblow                = true,
      canattackground         = false,
      cegTag                  = [[flak_trail]],
      color                   = 1,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 10,
        planes  = 100,
        subs    = 5,
      },

      edgeEffectiveness       = 0.85,
      explosionGenerator      = [[custom:FLAK_HIT_16]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-24]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 900,
      reloadtime              = 0.75,
	  size                    = 0.01,
      soundHit                = [[weapon/flak_hit]],
      soundStart              = [[weapon/flak_fire]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },	
  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Angler]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 140,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP      = {
      description      = [[Debris - Angler]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 70,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 70,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


  },

}

return lowerkeys({ amphaa = unitDef })
