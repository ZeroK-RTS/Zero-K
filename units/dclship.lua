unitDef = {
  unitname            = [[dclship]],
  name                = [[Hunter]],
  description         = [[Torpedo Frigate]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.043,
  buildCostEnergy     = 450,
  buildCostMetal      = 450,
  builder             = false,
  buildPic            = [[DCLSHIP.png]],
  buildTime           = 450,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Torpedofregatte]],
    helptext       = [[The Torpedo Frigate is a (relatively) cheap countermeasure to subs, though it can also attack surface targets.]],
	helptext_de    = [[Die relativ günstige Torpedofregatte besitzt eine Waffe speziell zur U-Jagd, die auch im Stande ist Schiffe zu treffen.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[mediumship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 240,
  maxDamage           = 1800,
  maxVelocity         = 3.4,
  minCloakDistance    = 75,
  minWaterDepth       = 5,
  movementClass       = [[BOAT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE HOVER]],
  objectName          = [[DCLSHIP]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[ARM]],
  sightDistance       = 760,
  smoothAnim          = true,
  sonarDistance		  = 600,
  turninplace         = 0,
  turnRate            = 418,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 360,
        subs    = 360,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      fixedLauncher           = true,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[wep_t_longbolt.s3o]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 430,
      reloadtime              = 2.6,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[explosion/ex_underwater]],
      soundStart              = [[weapon/torp_land]],
      startVelocity           = 120,
      tolerance               = 8000,
      tracks                  = true,
      turnRate                = 18000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 50,
      weaponTimer             = 5,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Hunter]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1750,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 184,
      object           = [[wreck3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 184,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hunter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1750,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 92,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 92,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ dclship = unitDef })
