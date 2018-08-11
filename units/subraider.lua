unitDef = {
  unitname               = [[subraider]],
  name                   = [[Seawolf]],
  description            = [[Attack Submarine (Stealth Raider)]],
  acceleration           = 0.06,
  activateWhenBuilt      = true,
  brakeRate              = 0.2,
  buildCostMetal         = 220,
  builder                = false,
  buildPic               = [[subraider.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SUB SINK]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[22 22 89]],
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
	modelradius    = [[13]],
	aimposoffset   = [[0 -5 0]],
	midposoffset   = [[0 -5 0]],
    turnatfullspeed = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[subraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 600,
  maxVelocity            = 3.7,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[UBOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP HOVER]],
  objectName             = [[subraider.s3o]],
  script                 = [[subraider.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  sightDistance          = 360,
  sonarDistance          = 360,
  turninplace            = 0,
  turnRate               = 600,
  upright                = true,
  waterline              = 20,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FAKEWEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 200,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 210,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      canattackground         = false,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[torptrailpurple]],

      customparams = {
		burst = Shared.BURST_RELIABLE,

        timeslow_damagefactor = 2,
      },

      damage                  = {
        default = 250.1,
        subs    = 250.1,
      },

      explosionGenerator      = [[custom:disruptor_missile_hit]],
      fixedLauncher           = true,
      flightTime              = 0.8,
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 60,
      impulseFactor           = 0.6,
      interceptedByShieldType = 1,
	  leadlimit               = 0,
      model                   = [[wep_t_longbolt.s3o]],
	  numbounce               = 0,
      noSelfDamage            = true,
      range                   = 220,
      reloadtime              = 3,
      rgbcolor                = [[0.9 0.1 0.9]],
      soundHit                = [[explosion/wet/ex_underwater_pulse]],
      soundHitVolume          = 6,
      soundStart              = [[weapon/torpedo]],
      soundStartVolume        = 6,
      startVelocity           = 450,
      tolerance               = 200,
      tracks                  = true,
      turnRate                = 80000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 400,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 600,
    },


    FAKEWEAPON  = {
      name                    = [[Fake Torpedo - Points me in the right direction]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.1,
        planes  = 0.1,
        subs    = 0.1,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      fixedLauncher           = true,
      flightTime              = 0.8,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      model                   = [[wep_t_longbolt.s3o]],
      range                   = 220,
      reloadtime              = 3,
      startVelocity           = 400,
      tolerance               = 100,
      tracks                  = true,
      turnRate                = 100000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 400,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 600,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[subraider_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ subraider = unitDef })
