unitDef = {

  unitname            = [[shiptorpraider]],
  name                = [[Hunter]],
  description         = [[Torpedo-Boat (Raider)]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostMetal      = 100,
  builder             = false,
  buildPic            = [[shiptorpraider.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[SHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 28 55]],
  collisionVolumeType    = [[cylZ]],
  corpse              = [[DEAD]],

  customParams        = {
	modelradius    = [[14]],
	turnatfullspeed = [[1]],
  },


  explodeAs           = [[SMALL_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[shiptorpraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  maxDamage           = 310,
  maxVelocity         = 4.2,
  minCloakDistance    = 75,
  minWaterDepth       = 5,
  movementClass       = [[BOAT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE HOVER]],
  objectName          = [[SHIPTORPRAIDER]],
  script              = [[shiptorpraider.lua]],
  selfDestructAs      = [[SMALL_UNITEX]],
  sightDistance       = 450,
  sonarDistance       = 450,
  turnRate            = 800,
  waterline           = 0,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    TORPEDO = {

      name                    = [[Torpedo]],
      areaOfEffect            = 64,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
	  burnblow                = 1,

      canAttackGround		  = false,	-- workaround for range hax
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

			customParams = {
				burst = Shared.BURST_RELIABLE,
			},

      damage                  = {

        default = 200.1,
        subs    = 200.1,
      },

      edgeEffectiveness       = 0.6,

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      fixedLauncher           = true,
      groundbounce            = 1,
      impulseBoost            = 1,
      impulseFactor           = 0.9,
      interceptedByShieldType = 1,
	  flightTime              = 0.9,
	  leadlimit               = 0,
      model                   = [[wep_m_ajax.s3o]],
      myGravity               = 10.1,
      numbounce               = 4,
      noSelfDamage            = true,

      range                   = 230,
      reloadtime              = 2.5,
      soundHit                = [[TorpedoHitVariable]],
      soundHitVolume          = 2.8,
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 4,
      startVelocity           = 20,
      tolerance               = 100000,
      tracks                  = true,
      turnRate                = 200000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 440,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[shiptorpraider_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}


return lowerkeys({ shiptorpraider = unitDef })
