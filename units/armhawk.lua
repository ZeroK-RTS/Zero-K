unitDef = {
  unitname            = [[armhawk]],
  name                = [[Hawk]],
  description         = [[Air Superiority Stealth Fighter]],
  amphibious          = true,
  buildCostEnergy     = 300,
  buildCostMetal      = 300,
  buildPic            = [[ARMHAWK.png]],
  buildTime           = 300,
  canAttack           = true,
  canDropFlare        = false,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  corpse              = [[DEAD]],
  cruiseAlt           = 220,

  customParams        = {
    description_bp = [[Caça de superioridade aérea invisível a radar]],
    description_fr = [[Chasseur Anti Air Supérieur]],
    helptext       = [[The Hawk is a powerful AA fighter. While it chews through bombers, gunships and other fighters, it has no anti-ground capacity.]],
    helptext_bp    = [[Hawk é um caça poderoso contra unidades aéreas mas incapaz de atacar unidades terrestres.]],
    helptext_fr    = [[Puissant contre l'air, le Hawk ne peut cepandent pas attaquer au sol. Il convient donc parfaitement r une contre attaque ou r une escorte de bombardiers. ]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[GUNSHIPEX]],
  fireState           = 2,
  floater             = true,
  footprintX          = 2,
  footprintZ          = 2,
  frontToSpeed        = 0.5,
  iconType            = [[stealthfighter]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 150,
  maxAcc              = 0.5,
  maxDamage           = 1000,
  maxVelocity         = 11,
  minCloakDistance    = 75,
  noChaseCategory     = [[TERRAFORM LAND SINK SHIP SWIM FLOAT SUB HOVER]],
  objectName          = [[trifighter.s3o]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:flash_teal7]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 810,
  smoothAnim          = true,
  speedToFront        = 0.5,
  stealth             = true,
  TEDClass            = [[VTOL]],

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[GUNSHIP]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    LASER = {
      name                    = [[Anti-Air Laser Battery]],
      areaOfEffect            = 12,
      avoidFriendly           = false,
      beamDecay               = 0.736,
      beamlaser               = 1,
      beamTime                = 0.01,
      beamttl                 = 15,
      canattackground         = false,
      canAttackGround         = 0,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 1.2,
        planes  = 12,
        subs    = 0.6,
      },

      energypershot           = 0.15,
      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 2.9,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      pitchtolerance          = 8192,
      range                   = 800,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 3,
      thickness               = 1.93649167310371,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Hawk]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[wreck2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Hawk]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hawk]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armhawk = unitDef })
