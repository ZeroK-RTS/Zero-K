unitDef = {
  unitname            = [[armpnix4]],
  name                = [[Phoenix IV]],
  description         = [[Mine Dropper (10 metal each)]],
  acceleration        = 0.072,
  altfromsealevel     = [[1]],
  amphibious          = true,
  attackrunlength     = [[300]],
  bankscale           = [[1]],
  bmcode              = [[1]],
  brakeRate           = 5,
  buildCostEnergy     = 550,
  buildCostMetal      = 550,
  builder             = false,
  buildPic            = [[armpnix3.png]],
  buildTime           = 550,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  corpse              = [[HEAP]],
  cruiseAlt           = 220,
  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[BIG_UNITEX]],
  fireState           = 1,
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomber]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1380]],
  mass                = 275,
  maxDamage           = 1020,
  maxVelocity         = 9.57,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[ARMPNIX]],
  scale               = [[1]],
  seismicSignature    = 0,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 402,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ARMADVBOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    ARMADVBOMB = {
      name                    = [[AdvancedBombs]],
      areaOfEffect            = 180,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 10,
      burstrate               = 0.4,
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = -1E-06,
      },

      dropped                 = true,
      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:BigBulletImpact]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      manualBombSettings      = true,
      model                   = [[ARMMINE1]],
      noSelfDamage            = true,
      range                   = 1280,
      reloadtime              = 10,
      renderType              = 6,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/BOMBREL]],
      sprayAngle              = 4000,
      weaponType              = [[AircraftBomb]],
    },


    EMG        = {
      name                    = [[EMG]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 8,
        planes  = 1.6,
        subs    = 0.4,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:BRAWLIMPACTS]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 640,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[1 0.5 0]],
      size                    = 1,
      soundStart              = [[flashemg]],
      soundTrigger            = true,
      sprayAngle              = 1024,
      stages                  = 50,
      startsmoke              = [[0]],
      tolerance               = 64000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 960,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Phoenix IV]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1020,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[ARMHAM_DEAD]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Phoenix IV]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1020,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Phoenix IV]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1020,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armpnix4 = unitDef })
