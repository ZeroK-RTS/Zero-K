unitDef = {
  unitname               = [[armbanth]],
  name                   = [[Bantha]],
  description            = [[Heavy Combat Strider]],
  acceleration           = 0.1047,
  bmcode                 = [[1]],
  brakeRate              = 0.2212,
  buildCostEnergy        = 12000,
  buildCostMetal         = 12000,
  builder                = false,
  buildPic               = [[ARMBANTH.png]],
  buildTime              = 12000,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -8 -2]],
  collisionVolumeScales  = [[62 80 48]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Mechwarrior d'Assaut Lourd]],
	description_de = [[Schwerer Kampfstreicher]],
	helptext_de    = [[Der Bantha ist die Lösung für eine besonders schwierig zu knackende Verteidigungslinie. Dazu besitzt er einen Tachyonen Beschleuniger und Marschflugkörper für Pattsituationen, blitzschnelle Handfeuerwaffen für den normalen Kampf und haufenweise Munition. Dennoch gib Acht darauf, dass er gegen Luftangriffe fast schutzlos ist.]],
    helptext       = [[The Bantha is an even heavier solution to a particularly uncrackable defense line, with a tachyon projector and cruise missiles for stand-off engagements, lightning hand cannons for general purpose combat, and plenty of armor. Beware though, for it is defenseless against air and cannot be used effectively on its own.]],
    helptext_fr    = [[Supérieur au Razorback en taille, en blindage, en prix, en portée, en armement mais pas en vitesse. Le Bantha est aussi cher et lent qu'il est inarretable. Il dispose de canons lasers, d'un canon accelerateur tachyon et de missiles. Courez.]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[ATOMIC_BLASTSML]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3generic]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  immunetoparalyzer      = [[1]],
  maneuverleashlength    = [[640]],
  mass                   = 1387,
  maxDamage              = 35000,
  maxSlope               = 36,
  maxVelocity            = 1.718,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE SUB]],
  objectName             = [[ARMBANTH]],
  seismicSignature       = 4,
  selfDestructAs         = [[ATOMIC_BLASTSML]],
  selfDestructCountdown  = 10,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 720,
  smoothAnim             = true,
  steeringmode           = [[2]],
  TEDClass               = [[KBOT]],
  turnRate               = 1056,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[CORKROG_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    ATA            = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      beamlaser               = 1,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 3000,
        planes  = 3000,
        subs    = 150,
      },

      explosionGenerator      = [[custom:ataalaser]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 16.94,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 950,
      reloadtime              = 10,
      renderType              = 0,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
      targetMoveError         = 0.3,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16.9373846859543,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },


    CORKROG_ROCKET = {
      name                    = [[Heavy Rockets]],
      areaOfEffect            = 96,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 850,
        subs    = 12,
      },

      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 70,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      minIntensity            = 1,
      model                   = [[wep_m_kickback.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 2.75,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startsmoke              = [[1]],
      tolerance               = 9000,
      tracks                  = true,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 230,
      weaponTimer             = 2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 10000,
    },


    LIGHTNING      = {
      name                    = [[Lightning Cannon]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = [[240]],
      },


      damage                  = {
        default        = 1200,
        commanders     = 120,
        empresistant75 = 300,
        empresistant99 = 12,
        planes         = 12,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 1,
      range                   = 465,
      reloadtime              = 1,
      renderType              = 7,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/LightningBolt]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Bantha]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 35000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 4800,
      object           = [[ARMBANTH_DEAD]],
      reclaimable      = true,
      reclaimTime      = 4800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Bantha]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 35000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 4800,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 4800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Bantha]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 35000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 2400,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 2400,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armbanth = unitDef })
