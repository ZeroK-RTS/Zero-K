unitDef = {
  unitname               = [[cormak]],
  name                   = [[Outlaw]],
  description            = [[Riot Bot]],
  acceleration           = 0.22,
  brakeRate              = 0.22,
  buildCostEnergy        = 250,
  buildCostMetal         = 250,
  builder                = false,
  buildPic               = [[cormak.png]],
  buildTime              = 250,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[46 48 37]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_bp = [[Robô dispersador]],
    description_es = [[Robot de alboroto]],
    description_fr = [[Robot ?meurier]],
    description_it = [[Robot da rissa]],
    description_de = [[Riot Roboter]],
    helptext       = [[The Outlaw emits an electromagnetic disruption pulse in a wide circle around it that damages and slows enemy units. Friendly units are unaffected.]],
    helptext_de    = [[Der Outlaw stößt einen elektromagnetischen Störungspuls, in einem weiten Kreis um sich herum, aus, welcher feindliche Einheiten schädigt und verlangsamt. Freundliche Einheiten sind davon aber nicht betroffen.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  mass                   = 177,
  maxDamage              = 1050,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SATELLITE SUB]],
  objectName             = [[behethud.s3o]],
  onoffable              = true,
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  script                 = [[cormak.lua]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RIOTBALL]],
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RIOT_SHELL_L]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 347,
  smoothAnim             = true,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2000,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[FAKEGUN1]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },


    {
      def                = [[BLAST]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },


    {
      def                = [[FAKEGUN2]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs             = {

    BLAST    = {
      name                    = [[Disruptor Pulser]],
      areaOfEffect            = 550,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50,
        planes  = 50,
        subs    = 2.5,
      },
	  
      customParams           = {
	    lups_explodespeed = 1.1,
	    lups_explodelife = 0.6,
	    nofriendlyfire = 1,
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      explosionSpeed          = 12,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.9,
      renderType              = 4,
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
      reloadtime              = 0.9,
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
	  avoidFriendly			  = false,
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
      range                   = 300,
      reloadtime              = 0.9,
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


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Outlaw]],
      blocking         = true,
      catagory         = [[corcorpses]],
      damage           = 1050,
      featureDead      = [[HEAP]],
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


    HEAP  = {
      description      = [[Debris - Outlaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1050,
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
