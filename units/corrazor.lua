unitDef = {
  unitname                      = [[corrazor]],
  name                          = [[Razor's Kiss]],
  description                   = [[Hardened Anti-Air Laser]],
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
  category                      = [[FLOAT UNARMED STUPIDTARGET]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Laser Anti-Air]],
	description_de = [[Gehärtetes Flugabwehrlaser]],
    helptext       = [[The Razor's Kiss is a hardy anti-air turret. Its high hit points and 4x armour bonus when closed makes it very hard for the enemy to dislodge.]],
    helptext_fr    = [[le Razor est une tourelle Anti-Air de portée moyenne. Enterrée et protégée par un blindage, elle sort et tir avec son laser r haute cadence. Assez imprécise r distance, elle compense par sa solidité.]],
	helptext_de    = [[Der Razor's Kiss ist ein abgehärteter Flugabwehrturm, dessen hohe Trefferpunkte und Panzerungsbonus es für Gegner, sobald geschlossen, enorm schwer macht, ihn zu zerstören.]],
  },

  damageModifier                = 0.25,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseaa]],
  levelGround                   = false,
  mass                          = 256,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[aapopup.s3o]],
  power                         = 50,
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },

  side                          = [[CORE]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[AAGUN]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    AAGUN = {
      name                    = [[Anti-Air Laser]],
      accuracy                = 50,
      areaOfEffect            = 8,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargetting      = 1,

      damage                  = {
        default = 1.64,
        planes  = 16.38,
        subs    = 0.8,
      },

      duration                = 0.02,
      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:FLASH1RED]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      pitchtolerance          = [[1000]],
      predictBoost            = 1,
      proximityPriority       = 4,
      range                   = 1040,
      reloadtime              = 0.1,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      startsmoke              = [[1]],
      thickness               = 2.25,
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
      damage           = 3000,
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
      damage           = 3000,
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
      damage           = 3000,
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
