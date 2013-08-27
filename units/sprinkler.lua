unitDef = {
  unitname                      = [[sprinkler]],
  name                          = [[Sprinkler]],
  description                   = [[Important irrigation structure]],
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
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[24 50 24]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Versteckter Gaussturm]],
    helptext 	   = [[The Sprinkler is an indispensable agriculture utility agreed for some sorts cleansing.]],
	helptext_de	   = [[Der Gauss ist ein kompakter Turm mit einem Gausswerfer mittleren Bereichs. Wenn er sich in seine Panzerung zurückgezogen hat, ist es sehr schwer ihn zu zerstören, was ihn effektive gegen gegnerische Artillerie macht.]],
	modelradius    = [[15]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defense]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  mass                          = 252,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[gauss_91.dae]],
  script                 		= [[sprinkler.lua]],
  seismicSignature              = 16,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
 
  sfxtypes               = {
    explosiongenerators = {
      [[custom:flashmuzzle1]],
    },
  }, 
  
  side                          = [[ARM]],
  sightDistance                 = 660,
  smoothAnim                    = true,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    LASER = {
      name                    = [[Laser Blaster]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50000,
        planes  = 9.77,
        subs    = 0.61,
      },

      duration                = 0.06,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 0.107,
      rgbColor                = [[1 0 0]],
      --soundHit                = [[weapon/laser/lasercannon_hit]],
      --0soundStart              = [[weapon/laser/small_laser_fire2]],
      soundTrigger            = true,
      targetMoveError         = 0.0,
      thickness               = 2.55,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Gauss]],
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
      object           = [[gauss_91_dead1.dae]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Gauss]],
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
      description      = [[Debris - Gauss]],
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

return lowerkeys({ sprinkler = unitDef })
