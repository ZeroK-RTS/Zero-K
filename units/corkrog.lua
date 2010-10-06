unitDef = {
  unitname              = [[corkrog]],
  name                  = [[Saktoth]],
  description           = [[Ulitmate Assault Strider]],
  acceleration          = 0.108,
  bmcode                = [[1]],
  brakeRate             = 0.238,
  buildCostEnergy       = 29000,
  buildCostMetal        = 29000,
  builder               = false,
  buildPic              = [[CORKROG.png]],
  buildTime             = 29000,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND]],
  corpse                = [[DEAD]],

  customParams          = {
    description_fr = [[Mechwarrior d'Assaut Éxperimental]],
    helptext       = [[Forged from the very essence of the greatest Logos commander who ever lived, the Saktoth is the single largest strider to walk the earth. This armed-to-the-teeth monstrosity's function is simple - obliterate large groups of lesser bots, tanks and turrets while marching into the enemy base. Note however that a lone Saktoth can be easily countered in a surprisingly large number of ways - prepare accordingly.]],
    helptext_fr    = [[Véritable concentré technologique, le Saktoth est tout simplement une invocation mécanisée de l'enfer meme. Un blindage résistant r de nombreux chocs nucléaires, une taille et une portée titanesque et une puissance de feu r faire palir plus d'une armée, voilr les avantages de ce monstre de métal. Le construire est un effort de longue durée, mais lorsqu'il sort enfin de sa fabrique, on sait que la victoire est proche.]],
  },

  damageModifier        = 1,
  defaultmissiontype    = [[Standby]],
  explodeAs             = [[NUCLEAR_MISSILE]],
  footprintX            = 6,
  footprintZ            = 6,
  iconType              = [[krogoth]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  immunetoparalyzer     = [[1]],
  maneuverleashlength   = [[640]],
  mass                  = 14500,
  maxDamage             = 133700,
  maxSlope              = 37,
  maxVelocity           = 1.488,
  maxWaterDepth         = 5000,
  minCloakDistance      = 75,
  movementClass         = [[AKBOT6]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName            = [[CORKROG]],
  seismicSignature      = 4,
  selfDestructAs        = [[NUCLEAR_MISSILE]],
  selfDestructCountdown = 10,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:RIOT_SHELL_H]],
    },

  },

  side                  = [[CORE]],
  sightDistance         = 845,
  smoothAnim            = true,
  steeringmode          = [[2]],
  TEDClass              = [[KBOT]],
  turnRate              = 380,
  upright               = true,
  workerTime            = 0,

  weapons               = {

    {
      def                = [[RIOT]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP GUNSHIP FIXEDWING HOVER]],
    },


    {
      def                = [[ATA]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[CORKROG_ROCKET]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs            = {

    ATA            = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 12,
      beamlaser               = 1,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 3300,
        planes  = 3300,
        subs    = 165,
      },

      energypershot           = 165,
      explosionGenerator      = [[custom:megapartgunblue]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 17.76,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 6,
      renderType              = 0,
      rgbColor                = [[0.5 0.5 1]],
      soundHit                = [[OTAunit/XPLOLRG1]],
      soundStart              = [[OTAunit/ANNIGUN1]],
      targetMoveError         = 0.3,
      texture1                = [[corelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 17.7640789234905,
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
        default = 360,
        subs    = 18,
      },

      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 70,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[fmdmisl]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 2.75,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOSML2]],
      soundStart              = [[OTAunit/ROCKHVY1]],
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


    RIOT           = {
      name                    = [[Heavy Riot Battery]],
      areaOfEffect            = 112,
      burst                   = 5,
      burstrate               = 0.04,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 325,
        planes  = 325,
        subs    = 16.25,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:FLASH96]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      minbarrelangle          = [[-50]],
      noSelfDamage            = true,
      pitchtolerance          = [[12000]],
      range                   = 590,
      reloadtime              = 1.4,
      renderType              = 3,
      rgbColor                = [[1 0.75 0.25]],
      size                    = 4,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/kroggie2]],
      sprayAngle              = 2750,
      startsmoke              = [[1]],
      tolerance               = 6000,
      turret                  = true,
      weaponTimer             = 2,
      weaponType              = [[Cannon]],
      weaponVelocity          = 900,
    },

  },


  featureDefs           = {

    DEAD  = {
      description      = [[Wreckage - Saktoth]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 133700,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 11600,
      object           = [[CORKROG_DEAD]],
      reclaimable      = true,
      reclaimTime      = 11600,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Saktoth]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 133700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 11600,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 11600,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Saktoth]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 133700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 5800,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 5800,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corkrog = unitDef })
