unitDef = {
  unitname            = [[corcrus]],
  name                = [[Executioner]],
  description         = [[Cruiser (Assault/Anti-Sub)]],
  acceleration        = 0.042,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.062,
  buildAngle          = 16384,
  buildCostEnergy     = 1800,
  buildCostMetal      = 1800,
  builder             = false,
  buildPic            = [[CORCRUS.png]],
  buildTime           = 1800,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Croiseur d'Assaut (Anti-Sousmarins)]],
    helptext       = [[The workhorse of the open seas, the Executioner possesses a hefty complement of weapons: a double-barreled high-energy laser, twin deck lasers, and a depthcharge launcher for fending off sub ambush.]],
    helptext_fr    = [[Veritable couteau suisse des mers, le Executioner dispose d'un double canon laser lourd, d'un lance grenade sousmarin et d'une tourelle de laser anti-air l?g?re. Capable de se battre contre tout type de menace, il trouve sa place dans toutes les flottes.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[heavyship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 900,
  maxDamage           = 4650,
  maxVelocity         = 2.84,
  minCloakDistance    = 75,
  minWaterDepth       = 10,
  movementClass       = [[BOAT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[CORCRUS]],
  scale               = [[0.5]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_YELLOW]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  sonarDistance       = 375,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turninplace         = 0,
  turnRate            = 448,
  waterline           = 4,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DECKLASER]],
      badTargetCategory  = [[FIXEDWING]],
      MainDir            = [[1.48 0 1]],
      MaxAngleDif        = 247,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DECKLASER]],
      badTargetCategory  = [[FIXEDWING]],
      MainDir            = [[-1.48 0 1]],
      MaxAngleDif        = 247,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    DECKLASER   = {
      name                    = [[Deck Laser]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      cegTag                  = [[redlaser_ak]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 8,
        planes  = 8,
        subs    = 0.4,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 30,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 0.2,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[laserhit]],
      soundStart              = [[OTAunit/lasrlit3]],
      soundTrigger            = true,
      targetMoveError         = 0.1,
      thickness               = 2.54950975679639,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1800,
    },


    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 128,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 420,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:TORPEDO_HIT]],
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[DEPTHCHARGE]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 500,
      reloadtime              = 6,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP2]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 110,
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 9800,
      turret                  = false,
      waterWeapon             = true,
      weaponAcceleration      = 15,
      weaponTimer             = 10,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 200,
    },


    LASER       = {
      name                    = [[High-Energy Laser]],
      areaOfEffect            = 14,
      beamWeapon              = true,
      burst                   = 2,
      burstrate               = 0.2,
      canattackground         = true,
      cegTag                  = [[yellowlaser_hlt]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 420,
        planes  = 420,
        subs    = 21,
      },

      duration                = 0.05,
      energypershot           = 28,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      noSelfDamage            = true,
      range                   = 530,
      reloadtime              = 4.5,
      renderType              = 0,
      rgbColor                = [[1 1 0]],
      soundHit                = [[psionic/laserhit]],
      soundStart              = [[psionic/laser]],
      targetMoveError         = 0.2,
      thickness               = 10.988630487918,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2120,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Executioner]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 4650,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[CORCRUS_DEAD]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Executioner]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4650,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      hitdensity       = [[100]],
      metal            = 720,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 720,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Executioner]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4650,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corcrus = unitDef })
