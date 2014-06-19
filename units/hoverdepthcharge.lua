unitDef = {
  unitname            = [[hoverdepthcharge]],
  name                = [[Claymore]],
  description         = [[Antisub Hovercraft]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostEnergy     = 300,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoverdepthcharge.png]],
  buildTime           = 300,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets  = [[0 0 0]],
  collisionVolumeScales   = [[55 55 55]],
  collisionVolumeTest	  = 1,
  collisionVolumeType	  = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext        = [[The somewhat suicidal Claymore is armed with a heavy depthcharge launcher and has no qualms about dropping it on land.]],
    description_pl  = [[Poduszkowiec przeciwpodwodny]],
    helptext_pl     = [[Claymore jest uzbrojony w ciezkie ladunki glebinowe, ktore moze wyrzucac takze na ladzie.]],
    turnatfullspeed = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverspecial]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  mass                = 184,
  maxDamage           = 1000,
  maxSlope            = 36,
  maxVelocity         = 3.3,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverassault.s3o]],
  script			  = [[hoverdepthcharge.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 385,
  sonarDistance       = 300,
  turninplace         = 0,
  turnRate            = 300,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },
	
	{
      def                = [[FAKEGUN]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

  },

  weaponDefs             = {

    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 290,
      avoidFriendly           = false,
	  bounceSlip              = 0.4,
	  bounceRebound           = 0.99,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1150,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:TORPEDOHITHUGE]],
      fixedLauncher           = true,
      flighttime              = 12,
	  groundBounce            = true,
	  heightMod               = 0,
	  impulseBoost            = 0.4,
      impulseFactor           = 1,
      interceptedByShieldType = 1,
      model                   = [[depthcharge_big.s3o]],
	  myGravity               = 0.2,
      noSelfDamage            = false,
      numbounce               = 4,
      predictBoost            = 0,
      range                   = 250,
      reloadtime              = 8,
      soundHitDry             = [[explosion/mini_nuke]],
      soundHitWet             = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 8,
      startVelocity           = 5,
      tolerance               = 1000000,
      tracks                  = true,
      turnRate                = 30000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 40,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 180,
    },
	
	FAKEGUN = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 100,
      reloadtime              = 8,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
	  waterWeapon             = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Claymore]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[hoverdepthcharge_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Claymore]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverdepthcharge = unitDef })
