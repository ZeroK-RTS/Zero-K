unitDef = {
  unitname           = [[armatl]],
  name               = [[Moray]],
  description        = [[Advanced Torpedo Launcher]],
  acceleration       = 0,
  activateWhenBuilt  = true,
  bmcode             = [[0]],
  brakeRate          = 0,
  buildAngle         = 16384,
  buildCostEnergy    = 1300,
  buildCostMetal     = 1300,
  builder            = false,
  buildPic           = [[ARMATL.png]],
  buildTime          = 1300,
  canAttack          = true,
  canstop            = [[1]],
  category           = [[SINK]],
  corpse             = [[DEAD]],

  customParams       = {
    helptext = [[The Moray is a long-ranged torpedo launcher with extremely high firepower. It is submerged to conceal and protect it from the enemy, but can be countered with torpedo bombers and standoff submarines, or simply bypassed with hovercraft.]],
  },

  defaultmissiontype = [[GUARD_NOMOVE]],
  explodeAs          = [[GUNSHIPEX]],
  footprintX         = 4,
  footprintZ         = 4,
  iconType           = [[defense]],
  idleAutoHeal       = 5,
  idleTime           = 1800,
  mass               = 650,
  maxDamage          = 1500,
  maxSlope           = 18,
  maxVelocity        = 0,
  minCloakDistance   = 150,
  minWaterDepth      = 58,
  noAutoFire         = false,
  noChaseCategory    = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName         = [[ARMATL]],
  seismicSignature   = 4,
  selfDestructAs     = [[GUNSHIPEX]],
  side               = [[ARM]],
  sightDistance      = 660,
  smoothAnim         = true,
  TEDClass           = [[WATER]],
  turnRate           = 0,
  waterline          = 55,
  workerTime         = 0,
  yardMap            = [[oooooooooooooooo]],

  weapons            = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs         = {

    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 2500,
        subs    = 2500,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[wep_t_barracuda.s3o]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 900,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP1]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 0,
      tolerance               = 1024,
      tracks                  = true,
      turnRate                = 96000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 100,
      weaponTimer             = 12,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs        = {

    DEAD  = {
      description      = [[Wreckage - Moray]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 520,
      object           = [[ARMATL_DEAD]],
      reclaimable      = true,
      reclaimTime      = 520,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Moray]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 520,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 520,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Moray]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 260,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 260,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armatl = unitDef })
