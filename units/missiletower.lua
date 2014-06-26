unitDef = {
  unitname                      = [[missiletower]],
  name                          = [[Hacksaw]],
  description                   = [[SAM Tower (Anti-Bomber)]],
  buildAngle                    = 8192,
  buildCostEnergy               = 400,
  buildCostMetal                = 400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[missiletower_aoplane.dds]],
  buildPic                      = [[missiletower.png]],
  buildTime                     = 400,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 12 0]],
  collisionVolumeScales         = [[50 62 50]],
  collisionVolumeTest	        = 1,
  collisionVolumeType	        = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    usetacai       = [[1]],
    description_de = [[Flugabwehrraketenturm]],
    description_pl = [[Wieza przeciwlotnicza]],
    helptext       = [[The Hacksaw's twin missiles can drop even the most heavily armored bomber in one pair of hits, but take a considerable amount of time to reload, making them less than ideal against light targets.]],
	helptext_de    = [[Seine Zwillingsraketen k�nnen sogar die schwersten Bomber mit einem Schuss vom Himmel holen, brauchen aber eine beachtliche Zeit zum Nachladen, was sie gegen leichtere Ziele nicht sehr effektiv macht.]],
	helptext_pl    = [[Podwojne rakiety, ktore wystrzeliwuje Hacksaw, zadaja bardzo duze obrazenia, jednak maja rownie dlugi czas przeladowania.]],
  },

  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseskirmaa]],
  levelGround                   = false,
  mass                          = 208,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[missiletower.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  waterline						= 10,
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
      cylinderTargeting       = 3,

	  customParams        	  = {
		isaa = [[1]],
	  },

      damage                  = {
        default = 59,
        planes  = 590,
        subs    = 32.5,
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
      model                   = [[wep_m_phoenix.s3o]],
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
      damage           = 1500,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[missiletower_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Hacksaw]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ missiletower = unitDef })
