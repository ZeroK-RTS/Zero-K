unitDef = {
  unitname                      = [[corrazor]],
  name                          = [[Razor's Kiss]],
  description                   = [[Anti-Air Laser]],
  bmcode                        = [[0]],
  buildAngle                    = 8192,
  buildCostEnergy               = 280,
  buildCostMetal                = 280,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[corrazor_aoplane.dds]],
  buildPic                      = [[corrazor.png]],
  buildTime                     = 280,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Laser Anti-Air]],
    helptext       = [[The Razor's Kiss is a hardy anti-air turret. Its high hit points and armour bonus when closed makes it very hard for the enemy to dislodge.]],
    helptext_fr    = [[le Razor est une tourelle Anti-Air de portée moyenne. Enterrée et protégée par un blindage, elle sort et tir avec son laser r haute cadence. Assez imprécise r distance, elle compense par sa solidité.]],
  },

  damageModifier                = 0.2,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseaa]],
  levelGround                   = false,
  mass                          = 230,
  maxDamage                     = 3400,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[aapopup.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
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
      def                = [[corrazor_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    corrazor_WEAPON = {
      name                    = [[Anti-Air Laser]],
      accuracy                = 50,
      areaOfEffect            = 8,
      beamWeapon              = true,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 1,
        planes  = 10,
        subs    = 0.1,
      },

      duration                = 0.02,
      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:FLASH1RED]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      pitchtolerance          = [[1000]],
      predictBoost            = 1,
      proximityPriority       = 4,
      range                   = 1040,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      thickness               = 2.25346954716499,
      tolerance               = 1000,
      turnRate                = 48000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1500,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Razor's Kiss]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 2200,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[aapopup_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Razor's Kiss]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Razor's Kiss]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2200,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 56,
      object           = [[debris3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 56,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corrazor = unitDef })
