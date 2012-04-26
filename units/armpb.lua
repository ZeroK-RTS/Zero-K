unitDef = {
  unitname                      = [[armpb]],
  name                          = [[Gauss]],
  description                   = [[Ambush Gauss Turret]],
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
    description_de = [[Versteckter Raketenturm]],
    helptext 	   = [[The Gauss is a compact, resilent turret with a medium-range gauss cannon. When popped down, it receives a quarter of incoming damage, making it a good choice when the enemy is using artillery.]],
	helptext_de	   = [[Der Gauss ist ein kompakter Turm mit einem Raktenwerfer mittleren Bereichs. Wenn er sich in seine Panzerung zurückgezogen hat, ist es sehr schwer ihn zu zerstören, was ihn effektive gegen gegnerische Artillerie macht.]],
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
  objectName                    = [[ARMPB]],
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

  weapons                       = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    GAUSS = {
      name                    = [[Light Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
	  avoidfeature            = false,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      cegTag                  = [[gauss_tag_l]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 160,
        planes  = 160,
        subs    = 8,
      },

      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 560,
      reloadtime              = 2,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundHitVolume          = 3,
      soundStart              = [[weapon/gauss_fire]],
      soundStartVolume        = 2.5,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2200,
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
      object           = [[wreck2x2b.s3o]],
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

return lowerkeys({ armpb = unitDef })
