unitDef = {
  unitname           = [[coratl]],
  name               = [[Lamprey]],
  description        = [[Advanced Torpedo Launcher]],
  acceleration       = 0,
  activateWhenBuilt  = true,
  bmcode             = [[0]],
  brakeRate          = 0,
  buildAngle         = 16384,
  buildCostEnergy    = 1400,
  buildCostMetal     = 1400,
  builder            = false,
  buildPic           = [[CORATL.png]],
  buildTime          = 1400,
  canAttack          = true,
  canstop            = [[1]],
  category           = [[SINK]],
  corpse             = [[DEAD]],

  customParams       = {
    helptext = [[The Lamprey is a long-ranged torpedo launcher with extremely high firepower. It is submerged to conceal and protect it from the enemy, but can be countered with torpedo bombers and standoff submarines, or simply bypassed with hovercraft.]],
  },

  defaultmissiontype = [[GUARD_NOMOVE]],
  explodeAs          = [[BIG_UNITEX]],
  footprintX         = 3,
  footprintZ         = 3,
  iconType           = [[defense]],
  idleAutoHeal       = 5,
  idleTime           = 1800,
  mass               = 700,
  maxDamage          = 1600,
  maxSlope           = 18,
  maxVelocity        = 0,
  minCloakDistance   = 150,
  minWaterDepth      = 58,
  noAutoFire         = false,
  noChaseCategory    = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName         = [[CORATL]],
  seismicSignature   = 4,
  selfDestructAs     = [[BIG_UNITEX]],
  side               = [[CORE]],
  sightDistance      = 660,
  smoothAnim         = true,
  TEDClass           = [[WATER]],
  turnRate           = 0,
  waterline          = 55,
  workerTime         = 0,
  yardMap            = [[ooooooooo]],

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
      description      = [[Wreckage - Lamprey]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1600,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 560,
      object           = [[CORATL_DEAD]],
      reclaimable      = true,
      reclaimTime      = 560,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Lamprey]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1600,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 560,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 560,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Lamprey]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1600,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 280,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 280,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ coratl = unitDef })
