unitDef = {
  unitname            = [[armpnix]],
  name                = [[Tempest]],
  description         = [[Cruise Missile Bomber]],
  amphibious          = true,
  buildCostEnergy     = 750,
  buildCostMetal      = 750,
  builder             = false,
  buildPic            = [[ARMPNIX.png]],
  buildTime           = 750,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  corpse              = [[DEAD]],
  cruiseAlt           = 180,

  customParams        = {
    helptext = [[The Tempest launches a long-ranged cruise missile that allows it to outrange most enemy ground-based AA. It is particularly useful for SEAD strikes, removing heavy AA from afar to clear the way for conventional bombers.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomber]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1380]],
  mass                = 300,
  maxAcc              = 0.5,
  maxDamage           = 1125,
  maxFuel             = 1000,
  maxVelocity         = 11,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[tempest.s3o]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  stealth             = true,
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 402,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ALCM]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 60,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    ALCM = {
      name                    = [[Air-Launched Cruise Missile]],
      areaOfEffect            = 64,
      avoidFriendly           = false,
      cegTag                  = [[raventrail]],
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargetting      = 1,

      damage                  = {
        default = 1000,
      },

      explosionGenerator      = [[custom:MISSILE_HIT_PIKES_160]],
      fireStarter             = 70,
      fixedLauncher           = true,
      flightTime              = 4,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[wep_m_kickback.s3o]],
      noSelfDamage            = true,
      range                   = 1400,
      reloadtime              = 1.5,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/missile_fire9]],
      startsmoke              = [[1]],
      startVelocity           = 200,
      texture2                = [[none]],
      tolerance               = 40000,
      tracks                  = false,
      turnRate                = 15000,
      weaponAcceleration      = 200,
      weaponTimer             = 3.5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 600,
    },


    EMG  = {
      name                    = [[EMG]],
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 16,
        subs    = 0.8,
      },

      explosionGenerator      = [[custom:BRAWLIMPACTS]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 2,
      renderType              = 4,
      rgbColor                = [[1 0.5 0]],
      size                    = 1,
      soundStart              = [[weapon/emg]],
      soundTrigger            = true,
      sprayAngle              = 1024,
      stages                  = 50,
      tolerance               = 64000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 960,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Tempest]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1125,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 292.5,
      object           = [[tempest_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 292.5,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Tempest]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1125,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 292.5,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 292.5,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Tempest]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1125,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 146.25,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 146.25,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armpnix = unitDef })
