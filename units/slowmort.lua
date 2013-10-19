unitDef = {
  unitname            = [[slowmort]],
  name                = [[Moderator]],
  description         = [[Slowbeam Walker]],
  acceleration        = 0.2,
  activateWhenBuilt   = true,
  brakeRate           = 0.2,
  buildCostEnergy     = 220,
  buildCostMetal      = 220,
  builder             = false,
  buildPic            = [[slowmort.png]],
  buildTime           = 220,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Kurzstrahl Roboter]],
    helptext       = [[The Moderator's slowing missile reduces enemy speed and rate of fire by up to 50%. Though doing no damage themselves, Moderators are effective against almost all targets.]],
	helptext_de    = [[Seine verlangsamender Strahl reduziert die Geschwindigkeit feindlicher Einheiten und die Feuerrate um bis zu 50%. Obwohl Moderatoren kein Schaden machen, sind sie effektiv gegen fast alle Ziele.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[fatbotsupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 164,
  maxDamage           = 680,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB UNARMED]],
  objectName          = [[CORMORT.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:NONE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 0.8,
  trackType           = [[ComTrack]],
  trackWidth          = 14,
  turnRate            = 1800,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SLOWMISSILE]],
      badTargetCategory  = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SLOWMISSILE = {
      name                    = [[Slowing Missile Launcher]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[moderatortrail]],
      collisionSize           = 0.05,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 350,
      },

      explosionGenerator      = [[custom:flashslow]],
      fireStarter             = 30,
      flightTime              = 6,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1.0,
      range                   = 600,
      reloadtime              = 1.0,
      rgbColor                = [[1 0 1]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med17]],
      soundStart              = [[weapon/missile/missile_fire11]],
      soundStartVolume        = 11,
      soundTrigger            = true,
      startVelocity           = 817.5,
      texture1                = [[flare]],
      tolerance               = 18000,
      tracks                  = true,
      trajectoryHeight        = 0.767326988,
      turnRate                = 200000,
      turret                  = true,
      weaponAcceleration      = 0,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 817.5,
    },
  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Moderator]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 680,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 84,
      object           = [[CORMORT_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 84,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description = [[Debris - Moderator]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 680,
      energy      = 0,
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 42,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 42,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ slowmort = unitDef })
