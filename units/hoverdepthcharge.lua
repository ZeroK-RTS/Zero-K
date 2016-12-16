unitDef = {
  unitname            = [[hoverdepthcharge]],
  name                = [[Claymore]],
  description         = [[Anti-Sub Hovercraft]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostEnergy     = 330,
  buildCostMetal      = 330,
  builder             = false,
  buildPic            = [[hoverdepthcharge.png]],
  buildTime           = 330,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets  = [[0 0 0]],
  collisionVolumeScales   = [[55 55 55]],
  collisionVolumeType	  = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext        = [[The somewhat suicidal Claymore is armed with a heavy depthcharge launcher and has no qualms about dropping it on land.]],
    turnatfullspeed = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverspecial]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 1350,
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
  sightDistance       = 385,
  sonarDistance       = 385,
  turninplace         = 0,
  turnRate            = 390,
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

    {
      def                = [[FAKE_DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 290,
      avoidFriendly           = false,
	  bounceSlip              = 0.4,
	  bounceRebound           = 0.99,
      canAttackGround		  = false,	-- it cannot really, this will stop people from being confused.
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 900.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:TORPEDOHITHUGE]],
      fixedLauncher           = true,
      flightTime              = 12,
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
      range                   = 270,
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
      weaponAcceleration      = 15,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 280,
    },
	
	FAKE_DEPTHCHARGE = {
      name                    = [[Fake Depth Charge]],
      areaOfEffect            = 290,
      avoidFriendly           = false,
	  bounceSlip              = 0.4,
	  bounceRebound           = 0.4,
      canAttackGround		  = false,	-- it cannot really, this will stop people from being confused.
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 1250.5,
      },

      edgeEffectiveness       = 0.4,
      explosionGenerator      = [[custom:TORPEDOHITHUGE]],
      fixedLauncher           = true,
      flightTime              = 2,
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
      range                   = 270,
      reloadtime              = 8,
      soundHitDry             = [[explosion/mini_nuke]],
      soundHitWet             = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 8,
      tolerance               = 1000000,
      tracks                  = false,
      turnRate                = 0,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 5,
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
      flightTime              = 1,
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
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverdepthcharge_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ hoverdepthcharge = unitDef })
