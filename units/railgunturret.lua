unitDef = {
  unitname                      = [[railgunturret]],
  name                          = [[Splinter]],
  description                   = [[Railgun Turret (Anti-Heavy) - Requires 25 Power]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 700,
  buildCostMetal                = 700,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[railgunturret_decal.dds]],
  buildPic                      = [[railgunturret.png]],
  buildTime                     = 700,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[FLOAT]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Schienenkanoneturm (Panzerbrechend)]],
    helptext       = [[The Splinter's high velocity gauss cannon slices through enemy armor like a chainsaw through butter.]],
    helptext_de    = [[Seine Hochgeschwindigkeits-Gauﬂkanone schneidet sich durch die feindliche Panzerung wie eine Kettens‰ge durch Butter.]],
    keeptooltip    = [[any string I want]],
    neededlink     = 25,
    pylonrange     = 50,	
  },

  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[defenseheavy]],
  levelGround                   = false,
  mass                          = 333,
  maxDamage                     = 5000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[railgunturret.s3o]],
  script                        = [[railgunturret.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },  
  
  side                          = [[ARM]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    GAUSS = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 2,
      burstrate               = 0.4,
      cegTag                  = [[gauss_tag_m]],
      
      customParams			= {
	timeslow_damagefactor = [[1.2]],
      },
      
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 450,
        planes  = 450,
        subs    = 22.5,
      },

      explosionGenerator      = [[custom:gauss_hit_m_purple]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      noExplode               = true,
      numbounce               = 40,
      range                   = 650,
      reloadtime              = 3,
      rgbColor                = [[0.9 0.1 0.9]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[weapon/gauss_hit]],
      soundStart              = [[weapon/gauss_fire]],
      sprayangle              = 100,
      stages                  = 32,
      startsmoke              = [[1]],
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2400,
    },

  },


  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Splinter]],
      blocking         = true,
      category         = [[arm_corpses]],
      damage           = 5000,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = 100,
      hitdensity       = 100,
      metal            = 280,
      object           = [[railgunturret_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 280,
    },


    HEAP = {
      description      = [[Debris - Splinter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 5000,
      footprintX       = 3,
      footprintZ       = 3,
      height           = 4,
      hitdensity       = 100,
      metal            = 140,
      object           = [[debris4x4b.s3o]],
      reclaimable      = true,
      reclaimTime      = 140,
    },

  },

}

return lowerkeys({ railgunturret = unitDef })
