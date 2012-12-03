unitDef = {
  unitname                      = [[dota_heavyturret_upd]],
  name                          = [[Sunlance]],
  description                   = [[Anti-Tank Turret - Requires 25 Power]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 700,
  buildCostMetal                = 700,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[heavyturret_decal.dds]],
  buildPic                      = [[heavyturret.png]],
  buildTime                     = 700,
  canAttack                     = true,
  canGuard                      = true,
  canstop                       = [[1]],
  category                      = [[FLOAT TURRET]],
  corpse                        = [[DEAD]],
  
  defaultmissiontype            = [[GUARD_NOMOVE]],
  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[defenseheavy]],
  levelGround                   = false,
  mass                          = 333,
  maxDamage                     = 5600,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[heavyturret.s3o]],
  script                        = [[heavyturret.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
	customParams                  = {
	neededlink     = 0,
	pylonrange     = 50,	
	},

  sfxtypes               = {

    explosiongenerators = {
      [[custom:none]],
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
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
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
      range                   = 2000,
      reloadtime              = 3,
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
    
    DISRUPTOR = {
      name                    = [[Disruptor Pulse Beam]],
      areaOfEffect            = 48,
      beamdecay 	      = 0.95,
      beamTime                = 0.1,
      beamttl                 = 50,
      coreThickness           = 0.3,
      craterBoost             = 0,
      craterMult              = 0,

      customParams			= {
		timeslow_damage = [[2500]],
      },
	
      damage                  = {
		default = 1400,
      },
	
      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.33,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 750,
      reloadtime              = 4,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/heavy_laser5]],
      soundStartVolume        = 5,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Sunlance]],
      blocking         = true,
      category         = [[arm_corpses]],
      damage           = 5600,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = 100,
      hitdensity       = 100,
      metal            = 280,
      object           = [[heavyturret_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 280,
    },


    HEAP = {
      description      = [[Debris - Sunlance]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 5600,
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

return lowerkeys({ dota_heavyturret_upd = unitDef })
