unitDef = {
  unitname                      = [[heavyturret]],
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
  category                      = [[FLOAT]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext       = [[The Sunlance's heavy disruptor beam cripples even the heaviest assault unit and will stop any armored assault dead in its tracks.]],
    keeptooltip    = [[any string I want]],
    neededlink     = 25,
    pylonrange     = 50,	
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[defenseheavy]],
  levelGround                   = false,
  maxDamage                     = 5600,
  maxSlope                      = 18,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[heavyturret.s3o]],
  script                        = [[heavyturret.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:none]],
    },

  },
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[DISRUPTOR]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[heavyturret_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ heavyturret = unitDef })
