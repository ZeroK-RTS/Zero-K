unitDef = {
  unitname            = [[armroy_radar]],
  name                = [[Radar Crusader]],
  description         = [[Destroyer (Artillery/Anti-Sub)]],
  acceleration        = 0.054,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.13,
  buildAngle          = 16384,
  buildCostEnergy     = 800,
  buildCostMetal      = 800,
  builder             = false,
  buildPic            = [[ARMROY.png]],
  buildTime           = 800,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[This upgraded Destroyer is equipped with a short-range radar.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[destroyer]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 400,
  maxDamage           = 3090,
  maxVelocity         = 3.3,
  minCloakDistance    = 75,
  minWaterDepth       = 10,
  movementClass       = [[BOAT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[armroy.s3o]],
  radarDistance       = 1200,
  scale               = [[0.5]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  sonarDistance       = 400,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turnRate            = 199,
  waterline           = 0,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    DEPTHCHARGE = {
      name                    = [[DepthCharge]],
      areaOfEffect            = 32,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 210,
      },

      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:TORPEDO_HIT]],
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[depthcharge.s3o]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 400,
      reloadtime              = 2.5,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP2]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 100,
      tolerance               = 1000,
      tracks                  = true,
      turnRate                = 1600,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 1,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 100,
    },


    PLASMA      = {
      name                    = [[Plasma Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 390,
        planes  = 390,
        subs    = 19.5,
      },

      explosionGenerator      = [[custom:FLASH3]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-25]],
      noSelfDamage            = true,
      range                   = 710,
      reloadtime              = 4.5,
      renderType              = 4,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/CANNON3]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 330,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Radar Crusader]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 3090,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[ARMROY_DEAD]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Radar Crusader]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 3090,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Radar Crusader]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 3090,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armroy_radar = unitDef })
