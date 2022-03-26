return { turretantiheavy = {
  unitname                      = [[turretantiheavy]],
  name                          = [[Lucifer]],
  description                   = [[Tachyon Projector - Power by connecting to a 50 energy grid]],
  activateWhenBuilt             = true,
  buildCostMetal                = 2200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[turretantiheavy_aoplane.dds]],
  buildPic                      = [[turretantiheavy.png]],
  category                      = [[SINK TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  --collisionVolumeScales         = [[75 100 75]],
  --collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 1,
    bait_level_target_armor = 1,

    keeptooltip    = [[any string I want]],

    neededlink     = 50,
    pylonrange     = 50,

    aimposoffset   = [[0 32 0]],
    midposoffset   = [[0 0 0]],
    modelradius    = [[40]],

    dontfireatradarcommand = '0',
  },

  damageModifier                = 0.333,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[fixedtachyon]],
  losEmitHeight                 = 65,
  maxDamage                     = 6000,
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[arm_annihilator.s3o]],
  onoffable                     = true,
  script                        = [[turretantiheavy.lua]],
  selfdestructas                = [[ESTOR_BUILDING]],
  sightDistance                 = 780,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo oooo oooo oooo]],

  weapons                       = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },

  },

  weaponDefs                    = {

    ATA = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      avoidFeature            = false,
      avoidNeutral            = false,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        burst = Shared.BURST_RELIABLE,

        light_color = [[1.6 1.05 2.25]],
        light_radius = 320,
      },

      damage                  = {
        default = 4000.1,
        planes  = 4000.1,
      },

      explosionGenerator      = [[custom:ataalaser]],
      fireTolerance           = 8192, -- 45 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 16.94,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 1200,
      reloadtime              = 10,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
      soundStartVolume        = 15,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16.94,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1400,
    },

  },

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[arm_annihilator_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
