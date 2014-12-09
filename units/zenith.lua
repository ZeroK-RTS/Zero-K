unitDef = {
  unitname                      = [[zenith]],
  name                          = [[Zenith]],
  description                   = [[Meteor Controller]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  buildCostEnergy               = 30000,
  buildCostMetal                = 30000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[zenith_aoplane.dds]],
  buildPic                      = [[zenith.png]],
  buildTime                     = 30000,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[90 194 90]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[cylY]],
  corpse                        = [[DEAD]],
  
  customParams                  = {
    helptext       = [[The Zenith summons down meteorites from the sky, causing massive widespread destruction. The meteorites shatter on impact and do not leave any reclaimable metal.]],
    description_pl = [[Kontroler Meteorow]],
    helptext_pl    = [[Zenith przyciaga w dowolne miejsce meteory z orbity, ktore niszcza trafione obiekty i z ktorych mozna odzyskac metal.]],
    keeptooltip = [[any string I want]],
    --neededlink  = 150,
    --pylonrange  = 150,
	modelradius    = [[45]],
  },  
  
  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 17500,
  maxDamage                     = 12000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[zenith.s3o]],
  onoffable                     = true,
  script                        = [[zenith.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[METEOR]],
      badTargetCateogory = [[MOBILE]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[GRAVITY_NEG]],
	  onlyTargetCategory = [[NONE]],
    },

  },


  weaponDefs                    = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity (fake)]],
      avoidFriendly           = false,
	  canAttackGround		  = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 2,
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 6000,
      reloadtime              = 0.2,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 32,
      thickness               = 32,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 6000,
    },


    METEOR      = {
      name                    = [[Meteor]],
	  accuracy                = 700,
      alwaysVisible           = 1,
      areaOfEffect            = 160,
      avoidFriendly           = false,
      avoidFeature            = false,
      avoidGround             = false,
      cegTag                  = [[METEOR_TAG]],
      collideFriendly         = true,

      customparams            = {
        spawns_name = "asteroid_dead",
        spawns_feature = 1,
      },

      craterBoost             = 0,
      craterMult              = 6,

      damage                  = {
        default = 1000,
        planes  = 1000,
        subs    = 50,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:TESS]],
      fireStarter             = 70,
      flightTime              = 30,
      impulseBoost            = 250,
      impulseFactor           = 0.5,
      interceptedByShieldType = 2,
      model                   = [[asteroid.s3o]],
      range                   = 9000,
      reloadtime              = 0.7,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/supergun_bass_boost]],
      startsmoke              = [[1]],
      startVelocity           = 1500,

      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      trajectoryHeight        = 0,
      turret                  = true,
	  turnrate                = 512,
      weaponAcceleration      = 200,
      weaponTimer             = 10,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1500,
      wobble                  = 2048,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Zenith]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 12000,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 12000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

    HEAP  = {
      description      = [[Debris - Zenith]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 6000,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 6000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ zenith = unitDef })
