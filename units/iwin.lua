unitDef = {
  unitname                      = [[iwin]],
  name                          = [[I Win Button]],
  description                   = [[Giant "I Win" Button]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildAngle                    = 32700,
  buildCostEnergy               = 35000,
  buildCostMetal                = 35000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[mahlazer_aoplane.dds]],
  buildPic                      = [[mahlazer.png]],
  buildTime                     = 35000,
  canAttack                     = true,
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 120 120]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    helptext       = [[I Win!!!]],
	modelradius    = [[60]],
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 2013,
  maxDamage                     = 12000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[iwin.s3o]],
  script                        = [[iwin.lua]],
  onoffable                     = true,
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:IMMA_LAUNCHIN_MAH_LAZER]],
    },

  },

  side                          = [[ARM]],
  sightDistance                 = 99999,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {

    {
      def                = [[LAZER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },
  },


  weaponDefs                    = {

    LAZER    = {
      name                    = [[I Win Lazer!]],
      accuracy                = 0,
      alwaysVisible           = true,
      areaOfEffect            = 40,
      avoidFeature            = false,
      avoidNeutral            = false,
      beamTime                = 0.1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

      damage                  = {
        default = 99999,
      },

      explosionGenerator      = [[custom:megapartgun]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      --interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 30000,	-- extra 1000 to prevent cutoff at max range
      reloadtime              = 0.2,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 48,
      tolerance               = 1000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1400,
    },
  },


  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Starlight]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 12000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 14000,
      object           = [[wreck7x7a.s3o]],
      reclaimable      = true,
      reclaimTime      = 14000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Starlight]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 12000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 7000,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 7000,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },
  },

}

return lowerkeys({ iwin = unitDef })
