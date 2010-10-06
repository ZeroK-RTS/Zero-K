unitDef = {
  unitname            = [[corhurc2]],
  name                = [[Firestorm]],
  description         = [[Napalm Bomber]],
  amphibious          = true,
  buildCostEnergy     = 350,
  buildCostMetal      = 350,
  builder             = false,
  buildPic            = [[corhurc2.png]],
  buildTime           = 350,
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
    description_bp = [[Bombardeiro de Napalm]],
    description_fr = [[Bombardier Napalm]],
    helptext       = [[The Firestorm's napalm bombs decimate large clumps of units and light structures.]],
    helptext_bp    = [[Este avi?o lança várias bombas de napalm sobre o alvo, incendiando uma grande área. Foi projetado para atacar grandes números de pequenas unidades, móveis ou n?o, mas em números suficientes pode destruir bases inteiras.]],
    helptext_fr    = [[Une escardre de Firestorm est une des pires chose qui puisse apparaître sur les radars ennemis. Rapides et efficaces, le Firestorm tapisse le sol de bombes au napalm faisant des dégâts r l'impact et sur la durée.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[bomberraider]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1380]],
  mass                = 175,
  maxAcc              = 0.5,
  maxDamage           = 700,
  maxFuel             = 1000,
  maxVelocity         = 10,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[firestorm.s3o]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  TEDClass            = [[VTOL]],
  workerTime          = 0,

  weapons             = {

    {
      def                = [[NAPALM]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    LASER  = {
      name                    = [[Laser]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterMult              = 0,

      damage                  = {
        default = 16,
        subs    = 0.8,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      pitchtolerance          = [[2000]],
      projectiles             = 2,
      range                   = 550,
      reloadtime              = 0.2,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/small_laser_fire2]],
      soundTrigger            = true,
      sprayangle              = 256,
      sweepfire               = false,
      thickness               = 3.60555127546399,
      tolerance               = 2000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 825,
    },


    NAPALM = {
      name                    = [[Napalm Bombs]],
      areaOfEffect            = 256,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 15,
      burstrate               = 0.09,
      collideFriendly         = false,
      commandfire             = true,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 25,
        planes  = 25,
        subs    = 2.5,
      },

      dropped                 = true,
      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:NAPALM_Expl]],
      fireStarter             = 250,
      flameGfxTime            = 2,
      impulseBoost            = 0,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      manualBombSettings      = true,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 0.7,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 10,
      renderType              = 6,
      soundHit                = [[weapon/burn_mixed]],
      soundStart              = [[weapon/bomb_drop_short]],
      sprayangle              = 64000,
      weaponType              = [[AircraftBomb]],
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Firestorm]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 140,
      object           = [[firestorm_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Firestorm]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 140,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Firestorm]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 70,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 70,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corhurc2 = unitDef })
