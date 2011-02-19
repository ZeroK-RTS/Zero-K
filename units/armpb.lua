unitDef = {
  unitname                      = [[armpb]],
  name                          = [[Pit Bull]],
  description                   = [[Ambush Rocket Turret]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 400,
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armpb_aoplane.dds]],
  buildPic                      = [[ARMPB.png]],
  buildTime                     = 400,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[24 50 24]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Versteckter Raketenturm]],
    helptext       = [[The Pit Bull is a compact, resilent turret with a medium-range rocket launcher. When popped down, it is very difficult to destroy, making it a good choice when the enemy is using artillery.]],
    helptext_de    = [[Der Pit Bull ist ein kompakter Turm mit einem Raktenwerfer mittleren Bereichs. Wenn er sich in seine Panzerung zur?ckgezogen hat, ist es sehr schwer ihn zu zerst?ren, was ihn effektive gegen gegnerische Artillerie macht.]],
  },

  damageModifier                = 0.15,
  digger                        = [[1]],
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defense]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 252,
  maxDamage                     = 2250,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[ARMPB]],
  seismicSignature              = 16,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
    },

  },

  side                          = [[ARM]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  stealth                       = true,
  TEDClass                      = [[FORT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,

  weapons                       = {

    {
      def                = [[ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    ROCKET = {
      name                    = [[Rocket]],
      areaOfEffect            = 48,
      cegTag                  = [[missiletrailred]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 250,
        planes  = 250,
        subs    = 12.5,
      },

      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 560,
      reloadtime              = 1.5,
      renderType              = 1,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 300,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      trajectoryHeight        = 0.05,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Pit Bull]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2250,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[15]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Pit Bull]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2250,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Pit Bull]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2250,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armpb = unitDef })
