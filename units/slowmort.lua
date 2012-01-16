unitDef = {
  unitname            = [[slowmort]],
  name                = [[Moderator]],
  description         = [[Slowbeam Walker]],
  acceleration        = 0.2,
  activateWhenBuilt   = true,
  brakeRate           = 0.2,
  buildCostEnergy     = 280,
  buildCostMetal      = 280,
  builder             = false,
  buildPic            = [[slowmort.png]],
  buildTime           = 280,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_de = [[Kurzstrahl Roboter]],
    helptext       = [[The Moderator's slow-ray reduces enemy speed and rate of fire by up to 50%. Though doing no damage themselves, Moderators are effective against almost all targets.]],
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
  maxDamage           = 550,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB UNARMED]],
  objectName          = [[CORMORT.s3o]],
  onoffable           = true,
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
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamlaser               = 1,
      beamTime                = 0.1,
      beamttl                 = 40,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 100,
      },

      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 2,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Morty]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 550,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[CORMORT_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description = [[Debris - Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 550,
      energy      = 0,
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 56,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 56,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ slowmort = unitDef })
