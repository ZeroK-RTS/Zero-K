unitDef = {
  unitname                      = [[missiletower]],
  name                          = [[Hacksaw]],
  description                   = [[SAM Tower (Anti-Bomber)]],
  bmcode                        = [[0]],
  buildAngle                    = 8192,
  buildCostEnergy               = 300,
  buildCostMetal                = 300,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[missiletower_aoplane.dds]],
  buildPic                      = [[missiletower.png]],
  buildTime                     = 300,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Flugabwehrraketenturm]],
    helptext       = [[The Hacksaw's twin missiles can drop even the most heavily armored bomber in one pair of hits, but take a considerable amount of time to reload, making them less than ideal against light targets.]],
	helptext_de    = [[Seine Zwillingsraketen können sogar die schwersten Bomber mit einem Schuss vom Himmel holen, brauchen aber eine beachtliche Zeit zum Nachladen, was sie gegen leichtere Ziele nicht sehr effektiv macht.]],
  },

  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseaa]],
  levelGround                   = false,
  mass                          = 208,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[missiletower.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  shootme                       = [[1]],
  side                          = [[CORE]],
  sightDistance                 = 660,
  TEDClass                      = [[FORT]],
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 24,
      burst                   = 2,
      burstrate               = 1.4,
      canattackground         = false,
      cegTag                  = [[missiletrailbluebig]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 60,
        planes  = 600,
        subs    = 30,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[wep_m_fury.s3o]],
      noSelfDamage            = true,
      range                   = 850,
      reloadtime              = 13,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/missile_fire3]],
      startsmoke              = [[1]],
      startVelocity           = 650,
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 141,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 900,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Hacksaw]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2200,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[missiletower_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Hacksaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 120,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 120,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hacksaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 60,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 60,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ missiletower = unitDef })
