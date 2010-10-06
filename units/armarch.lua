unitDef = {
  unitname                      = [[armarch]],
  name                          = [[Packo]],
  description                   = [[Popup Anti-Air Autocannon]],
  activateWhenBuilt             = true,
  buildAngle                    = 65536,
  buildCostEnergy               = 280,
  buildCostMetal                = 280,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armarch_aoplane.dds]],
  buildPic                      = [[armarch.png]],
  buildTime                     = 280,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Mitrailleuse Anti-Air Camouflable]],
    helptext       = [[The Packo is a medium-range anti-air turret. Though inaccurate at its max range, it does well against units flying directly over it and gunships. Its high hit points and armour bonus when closed makes it very hard for the enemy to dislodge.]],
    helptext_fr    = [[Le Packo est une tourelle Anti-Air moyenne, capable de se débarrasser de la plupart des menaces aeriennes facilement. De plus, sa position fermée le rends beaucoup plus solide et quasi impossible r déloger.]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseaa]],
  levelGround                   = false,
  mass                          = 140,
  maxDamage                     = 2200,
  maxSlope                      = 18,
  minCloakDistance              = 60,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[armarch]],
  seismicSignature              = 16,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
    },

  },

  shootme                       = [[1]],
  side                          = [[ARM]],
  sightDistance                 = 660,
  TEDClass                      = [[FORT]],
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[ARCH_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    ARCH_WEAPON = {
      name                    = [[Anti-Air Autocannon]],
      accuracy                = 512,
      alphaDecay              = 0.7,
      areaOfEffect            = 16,
      canattackground         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 2.5,
        planes  = [[25]],
        subs    = 1.25,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:ARCHPLOSION]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.8,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      pitchtolerance          = [[12000]],
      predictBoost            = 1,
      proximityPriority       = 4,
      range                   = 1040,
      reloadtime              = 0.1,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundStart              = [[brawlemg]],
      stages                  = 10,
      startsmoke              = [[0]],
      sweepfire               = false,
      tolerance               = 6000,
      turret                  = true,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Packo]],
      blocking         = true,
      category         = [[core_corpses]],
      damage           = 2200,
      featureDead      = [[DEAD2]],
      featurereclamate = [[smudge01]],
      footprintX       = 4,
      footprintZ       = 4,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[ARM_PACKO_D.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Packo]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featureDead      = [[HEAP]],
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Packo]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featurereclamate = [[smudge01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 56,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 56,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armarch = unitDef })
