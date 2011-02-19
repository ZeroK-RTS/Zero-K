unitDef = {
  unitname          = [[cortl]],
  name              = [[Urchin]],
  description       = [[Torpedo Launcher]],
  acceleration      = 0,
  activateWhenBuilt = true,
  brakeRate         = 0,
  buildAngle        = 16384,
  buildCostEnergy   = 260,
  buildCostMetal    = 260,
  builder           = false,
  buildPic          = [[CORTL.png]],
  buildTime         = 260,
  canAttack         = true,
  canstop           = [[1]],
  category          = [[FLOAT]],
  corpse            = [[DEAD]],

  customParams      = {
    description_fr = [[Lance Torpille]],
    helptext       = [[This Torpedo Launcher provides defense against both surface and submerged vessels. Remember to build sonar so that the Torpedo Launcher can hit submerged targets. The Torpedo Launcher cannot hit hovercraft.]],
    helptext_fr    = [[Ce lance torpille permet de torpiller les unit?s flottantes ou immerg?es. Construisez un sonar afin de d?tecter le plus t?t possible les cibles potentielles du Harpoon. Attention, le Harpoon est inefficace contre les Hovercraft.]],
  },

  explodeAs         = [[MEDIUM_BUILDINGEX]],
  footprintX        = 3,
  footprintZ        = 3,
  iconType          = [[defense]],
  idleAutoHeal      = 5,
  idleTime          = 1800,
  mass              = 215,
  maxDamage         = 2050,
  maxSlope          = 18,
  maxVelocity       = 0,
  minCloakDistance  = 150,
  noAutoFire        = false,
  noChaseCategory   = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName        = [[torpedo launcher.s3o]],
  seismicSignature  = 4,
  selfDestructAs    = [[MEDIUM_BUILDINGEX]],
  side              = [[CORE]],
  sightDistance     = 660,
  smoothAnim        = true,
  TEDClass          = [[WATER]],
  turnRate          = 0,
  waterline         = 1,
  workerTime        = 0,
  yardMap           = [[wwwwwwwww]],

  weapons           = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs        = {

    TORPEDO = {
      name                    = [[Torpedo Launcher]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 360,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[wep_t_longbolt.s3o]],
      noSelfDamage            = true,
      numbounce               = 4,
      propeller               = [[1]],
      range                   = 600,
      reloadtime              = 2,
      renderType              = 1,
      soundHit                = [[explosion/ex_underwater]],
      soundStart              = [[weapon/torpedo]],
      startVelocity           = 150,
      tracks                  = true,
      turnRate                = 22000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 22,
      weaponTimer             = 3,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 320,
    },

  },


  featureDefs       = {

    DEAD  = {
      description      = [[Wreckage - Urchin]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2050,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[torpedo launcher_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Urchin]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2050,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Urchin]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2050,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ cortl = unitDef })
