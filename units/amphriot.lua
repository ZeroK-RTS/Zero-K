unitDef = {
  unitname               = [[amphriot]],
  name                   = [[Scallop]],
  description            = [[Amphibious Riot Bot (Land), Skirmish Bot (Sea)]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  amphibious             = [[1]],
  brakeRate              = 0.375,
  buildCostEnergy        = 350,
  buildCostMetal         = 350,

  buildPic               = [[amphriot.png]],
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
    extradrawrange = 460,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  hideDamage             = false,
  iconType               = [[amphtorpriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 390,
  maxDamage              = 850,
  maxSlope               = 36,
  maxVelocity            = 1.4,
  maxWaterDepth          = 5000,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER]],
  objectName             = [[amphriot.s3o]],
  script                 = [[amphriot.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:HEAVY_CANNON_MUZZLE]],
      [[custom:RIOT_SHELL_L]],
    },
  },

  side                   = [[ARM]],
  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 28,
  turnRate               = 1000,
  upright                = false,

  weapons                = {
  
    {
      def                = [[FLECHETTE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
 
    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP]],
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
        default = 100,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[wep_t_longbolt.s3o]],
      numbounce               = 4,
      range                   = 460,
      reloadtime              = 2,
      soundHit                = [[explosion/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 26,
      weaponTimer             = 3,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 300,
    },
  
  
    FLECHETTE = {
      name                    = [[Flechette]],
      areaOfEffect            = 32,
      burst		      = 3,
      burstRate		      = 0.03,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      damage                  = {
	    default = 32,
	    subs    = 1.6,
      },
      
      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
      fireStarter             = 50,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      projectiles	      = 3,
      range                   = 300,
      reloadtime              = 0.9,
      rgbColor                = [[1 1 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/cannon/cannon_fire4]],
      soundStartVolume	      = 0.6,
      soundTrigger            = true,
      sprayangle	      = 1600,
      targetMoveError         = 0.15,
      thickness               = 2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    }	
  },


  featureDefs            = {

    DEAD      = {
      description      = [[Wreckage - Scallop]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1600,
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
      description      = [[Debris - Scallop]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1600,
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

return lowerkeys({ amphriot = unitDef })
