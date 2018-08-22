unitDef = {
  unitname            = [[tankheavyassault]],
  name                = [[Cyclops]],
  description         = [[Very Heavy Tank Buster]],
  acceleration        = 0.0282,
  brakeRate           = 0.052,
  buildCostMetal      = 2200,
  builder             = false,
  buildPic            = [[tankheavyassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 12000,
  maxSlope            = 18,
  maxVelocity         = 2.05,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[corgol_512.s3o]],
  script	      = [[tankheavyassault.cob]],
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance       = 540,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 50,
  turninplace         = 0,
  turnRate            = 312,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[COR_GOL]],
	  badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
  },

  weaponDefs          = {

    COR_GOL             = {
      name                    = [[Tankbuster Cannon]],
      areaOfEffect            = 32,
      
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        burst = Shared.BURST_RELIABLE,

        reaim_time = 8, -- COB

        gatherradius = [[105]],
        smoothradius = [[70]],
        smoothmult   = [[0.4]],

        light_radius = 320,
        timeslow_damagefactor = 3,
        timeslow_overslow_frames = 2*30,
        light_color = [[1.88 0.63 2.5]],
      },
      
      damage                  = {
        default = 1000,
        subs    = 50,
      },

      cegTag                  = [[cyclopstrail]],
      stages                  = 20,
      rgbcolor                = [[1.0 0.2 1.0]],
      separation              = 2,

      explosionGenerator      = [[custom:cyclops_hit]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 450,
      reloadtime              = 3.5,
      soundHit                = [[weapon/laser/heavy_disrupter_hit]],
      soundStart              = [[weapon/laser/heavy_disrupter]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 310,
    },
  },


  featureDefs         = {

    DEAD       = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[golly_d.s3o]],
    },

	
    HEAP       = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ tankheavyassault = unitDef })
