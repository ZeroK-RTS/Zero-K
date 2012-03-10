unitDef = {
  unitname               = [[armbanth]],
  name                   = [[Bantha]],
  description            = [[Heavy Standoff Strider]],
  acceleration           = 0.1047,
  bmcode                 = [[1]],
  brakeRate              = 0.2212,
  buildCostEnergy        = 10500,
  buildCostMetal         = 10500,
  builder                = false,
  buildPic               = [[ARMBANTH.png]],
  buildTime              = 10500,
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

  explodeAs              = [[ATOMIC_BLAST]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3generic]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 1387,
  maxDamage              = 36000,
  maxSlope               = 36,
  maxVelocity            = 1.72,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE SUB]],
  objectName             = [[ARMBANTH]],
  seismicSignature       = 4,
  selfDestructAs         = [[ATOMIC_BLAST]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  side                   = [[ARM]],
  sightDistance          = 720,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.5,
  trackType              = [[ComTrack]],
  trackWidth             = 42,
  turnRate               = 1056,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[CORKROG_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    ATA            = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 600,
        planes  = 600,
        subs    = 30,
      },

      explosionGenerator      = [[custom:ataalaser]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 16.94,
      minIntensity            = 1,
      noSelfDamage            = true,
	  projectiles             = 5,
      range                   = 950,
      reloadtime              = 10,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
	  soundStartVolume        = 3,
      targetMoveError         = 0.3,
      texture1                = [[largelaserdark]],
      texture2                = [[flaredark]],
      texture3                = [[flaredark]],
      texture4                = [[smallflaredark]],
      thickness               = 16.9,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },


    CORKROG_ROCKET = {
      name                    = [[Heavy Rockets]],
      areaOfEffect            = 96,
	  cegTag                  = [[raventrail]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 850,
        subs    = 42.5,
      },

      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_kickback.s3o]],
      range                   = 800,
      reloadtime              = 2.75,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_launch]],
      startsmoke              = [[1]],
      tolerance               = 9000,
      tracks                  = true,
      weaponAcceleration      = 230,
      weaponTimer             = 2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 10000,
    },


    LIGHTNING      = {
      name                    = [[Lightning Cannon]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = [[320]],
      },

      damage                  = {
        default        = 960,
        empresistant75 = 240,
        empresistant99 = 9.6,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzer               = true,
      paralyzeTime            = 1.5,
      range                   = 465,
      reloadtime              = 1,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/LightningBolt]],
      soundStartVolume        = 2,
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
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 4200,
      object           = [[armbanth_dead]],
      reclaimable      = true,
      reclaimTime      = 4200,
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
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 2100,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 2100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armbanth = unitDef })
