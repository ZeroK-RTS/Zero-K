unitDef = {
  unitname                      = [[corgrav]],
  name                          = [[Newton]],
  description                   = [[Gravity Turret - On to Repulse, Off to Attract]],
  activateWhenBuilt             = true,
  bmcode                        = [[0]],
  buildCostEnergy               = 200,
  buildCostMetal                = 200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[corgrav_aoplane.dds]],
  buildPic                      = [[corgrav.png]],
  buildTime                     = 200,
  canAttack                     = true,
  canstop                       = [[1]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[50 50 50]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Tourrelle r Gravité Répulsive/Attractive]],
	description_de = [[Gravitationsturm - An zum Abstoßen, Aus zum Anziehen]],
    helptext       = [[The Newton is armed with an experimental graviton projector. This weapon does virtually no damage directly, but can push units toward or away from the Newton. You can use it on your own units as well, but beware of friendly fire.]],
    helptext_fr    = [[Le Newton est un équipement toute dernicre génération utilisant des flux de gravitron densifiés pour repousser ou attirer ses cibles. Régler par défaut sur repousser, il empechera les ennemis de grimper sur une collinne fortifiée par exemple. Il peut également attirer dans l'eau des unités non-amphibies.]],
	helptext_de    = [[Der Newton ist mit einem experimentellen Gravitonprojektor bewaffnet. Diese Waffe so gut wie keinen direkten Schaden, denn sie kann Einheiten anziehen und abstoßen. Das kann entweder mit deinen eigenen Einheiten passieren oder mit feindlichen.]],
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  healtime                      = [[-1]],
  iconType                      = [[defenseriot]],
  levelGround                   = false,
  mass                          = 208,
  maxDamage                     = 2000,
  maxSlope                      = 36,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[corgrav]],
  onoffable                     = true,
  seismicSignature              = 4,
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],
  shootme                       = [[1]],
  side                          = [[CORE]],
  sightDistance                 = 506,
  TEDClass                      = [[FORT]],
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],

  weapons                       = {

    {
      def                = [[GRAVITY_POS]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND SHIP GUNSHIP]],
    },

  },


  weaponDefs                    = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    impulse = [[-125]],
	  },
	  
      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      predictBoost            = 1,
      proximityPriority       = -15,
      range                   = 460,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },


    GRAVITY_POS = {
      name                    = [[Repulsive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = false,
      burst                   = 6,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

	  customParams            = {
	    impulse = [[125]],
	  },
	  
      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      intensity               = 0.7,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      predictBoost            = 1,
      proximityPriority       = 15,
      range                   = 440,
      reloadtime              = 0.2,
      renderType              = 4,
      rgbColor                = [[1 0 0]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Newton]],
      blocking         = true,
      category         = [[core_corpses]],
      damage           = 2000,
      featureDead      = [[DEAD2]],
      featurereclamate = [[smudge01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[25]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[corgrav_dead]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Newton]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2000,
      featureDead      = [[HEAP]],
      featurereclamate = [[smudge01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Newton]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2000,
      featurereclamate = [[smudge01]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[tree1reclamate]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corgrav = unitDef })
