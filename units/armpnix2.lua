unitDef = {
  unitname            = [[armpnix2]],
  name                = [[Phoenix II]],
  description         = [[Area Laser Bomber]],
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
  buildPic            = [[ARMPNIX.png]],
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

  customParams        = {
    helptext = [[The laser bomber version of the Pheonix, this new model is armed with lasers similar to that of the Mumbo. Although the Pheonix II carries better shielding than the Mumbo, this leaves precious little room for targeting equipment. As such, the Pheonix II is designed to scatter its lasers over a wide area, making it good against swarms and large targets. Furthermore, the  bulky bomber missile has been removed for a more compact, if less accurate, Energy Machine Gun.]],
  },

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
  maxAcc              = 0.5,
  maxAileron          = 0.02,
  maxangledif4        = [[180]],
  maxBank             = 2,
  maxDamage           = 1500,
  maxElevator         = 0.02,
  maxFuel             = 1000,
  maxPitch            = 1.2,
  maxRudder           = 0.006,
  maxVelocity         = 9,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[ARMPNIX2]],
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
  turnRadius          = 100,
  turnRate            = 402,
  weaponmaindir4      = [[0 -1 0]],
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[EMG]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def                = [[LASER]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },


    {
      def               = [[BOGUS_MISSILE]],
      badTargetCategory = [[SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
    },

  },


  weaponDefs          = {

    BOGUS_BOMB    = {
      name                    = [[BogusBomb]],
      areaOfEffect            = 80,
      burst                   = 2,
      burstrate               = 5,
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0,
      },

      dropped                 = true,
      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      manualBombSettings      = true,
      model                   = [[bomb]],
      myGravity               = 1000,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.5,
      renderType              = 6,
      scale                   = [[0]],
      weaponType              = [[AircraftBomb]],
    },


    BOGUS_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 48,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 100,

      damage                  = {
        default = 0,
      },

      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      metalpershot            = 0,
      range                   = 300,
      reloadtime              = 0.5,
      renderType              = 1,
      startVelocity           = 450,
      tolerance               = 9000,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 101,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 650,
    },


    EMG           = {
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
      tolerance               = 32767,
      turret                  = false,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 960,
    },


    LASER         = {
      name                    = [[Laser]],
      areaOfEffect            = 32,
      avoidFeature            = false,
      avoidFriendly           = false,
      beamlaser               = 1,
      beamTime                = 0.01,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 25,
        subs    = 1.25,
      },

      explosionGenerator      = [[custom:flash1green]],
      fireStarter             = 100,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 5,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 1000,
      reloadtime              = 10,
      renderType              = 0,
      rgbColor                = [[0 1 0]],
      scrollSpeed             = 5,
      targetMoveError         = 5,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 5,
      tileLength              = 300,
      tolerance               = 32767,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Phoenix II]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1500,
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
      description      = [[Debris - Phoenix II]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Phoenix II]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armpnix2 = unitDef })
