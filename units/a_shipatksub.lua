unitDef = {
  unitname               = [[a_shipatksub]],
  name                   = [[Seawolf]],
  description            = [[Submarine (Stealth Raider)]],
  acceleration           = 0.06,
  activateWhenBuilt      = true,
  brakeRate              = 0.2,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,
  builder                = false,
  buildPic               = [[CORSUB.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = true,
  category               = [[SUB SINK]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[22 22 89]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[Stealthy, fast, and fragile, this Submarine can quickly strike unprotected targets. Slow damage allows it to effectively kill lone units. Watch out for anything with anti-sub weaponry, especially Torpedo Boats and Destroyers.]],
	modelradius    = [[13]],
	aimposoffset   = [[0 -5 0]],
	midposoffset   = [[0 -5 0]],
    turnatfullspeed = [[1]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[submarine]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  mass                   = 240,
  maxDamage              = 550,
  maxVelocity            = 4.0,
  minCloakDistance       = 75,
  minWaterDepth          = 15,
  movementClass          = [[UBOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP HOVER]],
  objectName             = [[sub.s3o]],
  script                 = [[a_shipatksub.lua]],
  seismicSignature       = 4,
  selfDestructAs         = [[SMALL_UNITEX]],
  side                   = [[CORE]],
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
      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 190,
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
      reloadtime              = 4,
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
      range                   = 210,
      reloadtime              = 4.4,
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
      object           = [[sub_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ a_shipatksub = unitDef })
