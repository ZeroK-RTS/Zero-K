unitDef = {
  unitname            = [[cormak]],
  name                = [[Outlaw]],
  description         = [[Riot Bot]],
  acceleration        = 0.102,
  bmcode              = [[1]],
  brakeRate           = 0.135,
  buildCostEnergy     = 250,
  buildCostMetal      = 250,
  builder             = false,
  buildPic            = [[cormak.png]],
  buildTime           = 250,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô dispersador]],
    description_es = [[Robot de alboroto]],
    description_fr = [[Robot ?meurier]],
    description_it = [[Robot da rissa]],
    helptext       = [[The Outlaw emits an electromagnetic disruption pulse in a wide circle around it that damages and slows enemy units. Friendly units are unaffected.]],
    nofriendlyfire = 1,
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerriot]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[500]],
  mass                = 182,
  maxDamage           = 1100,
  maxSlope            = 36,
  maxVelocity         = 1.5,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING GUNSHIP SATELLITE SUB]],
  objectName          = [[behethud.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RIOT_SHELL_L]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  shootme             = [[1]],
  side                = [[CORE]],
  sightDistance       = 347,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  threed              = [[1]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turninplace         = 0,
  turnRate            = 1051,
  upright             = true,
  workerTime          = 0,
  zbuffer             = [[1]],

  weapons             = {

    {
      def                = [[FAKEGUN1]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },


    {
      def                = [[BLAST]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },


    {
      def                = [[FAKEGUN2]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs          = {

    BLAST    = {
      name                    = [[Disruptor Pulser]],
      areaOfEffect            = 512,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 5,
      },

      edgeeffectiveness       = 0.6,
      explosionGenerator      = [[custom:riotball]],
      explosionSpeed          = 5,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 120,
      reloadtime              = 1.5,
      renderType              = 4,
      soundHit                = [[weapon/aoe_aura]],
      soundHitVolume          = 1,
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },


    FAKEGUN1 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 32,
      reloadtime              = 1.5,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },


    FAKEGUN2 = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
        subs    = 5E-08,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 256,
      reloadtime              = 1.5,
      size                    = 1E-06,
      smokeTrail              = false,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Outlaw]],
      blocking         = true,
      catagory         = [[corcorpses]],
      damage           = 1100,
      featureDead      = [[DEAD2]],
      featurereclamate = [[smudge01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[10]],
      hitdensity       = [[23]],
      metal            = 100,
      object           = [[behethud_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },


    DEAD2 = {
      description      = [[Debris - Outlaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      featureDead      = [[HEAP]],
      featurereclamate = [[smudge01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[4]],
      metal            = 100,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },


    HEAP  = {
      description      = [[Debris - Outlaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1100,
      featurereclamate = [[smudge01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[4]],
      metal            = 50,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 50,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[all]],
    },

  },

}

return lowerkeys({ cormak = unitDef })
