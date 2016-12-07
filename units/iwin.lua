unitDef = {
  unitname                      = [[iwin]],
  name                          = [[I Win Button]],
  description                   = [[Giant "I Win" Button]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 250000,
  buildCostMetal                = 250000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[mahlazer_aoplane.dds]],
  buildPic                      = [[iwin.png]],
  buildTime                     = 250000,
  canAttack                     = true,
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 120 120]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_pl = [[Wielki Guzik Wygranej]],
    helptext       = [[I Win!!!]],
    helptext_pl    = [[Wygralam!!!]],
	modelradius    = [[60]],
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 12000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[iwin.blend]],
  script                        = [[iwin.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:IMMA_LAUNCHIN_MAH_LAZER]],
    },

  },
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[wreck7x7a.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },
  },

}

return lowerkeys({ iwin = unitDef })
