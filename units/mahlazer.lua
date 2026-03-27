return { mahlazer = {
  name                          = [[Starlight]],
  description                   = [[Planetary Energy Chisel]],
  activateWhenBuilt             = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[starlight_aoplate.dds]],
  buildPic                      = [[mahlazer.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[150 200 150]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    modelradius    = [[80]],
    aimposoffset   = [[0 35 0]],
    midposoffset   = [[0 0 0]],
    select_no_rotate   = [[1]], -- tells selection widgets to treat the unit as if it has no rotation.
    bait_level_default = 0,
    want_precise_proximity_targetting = 1,
    draw_blueprint_facing = 1,
    superweapon = 1,
    normaltex = [[unittextures/starlight_normals.dds]],

    keeptooltip    = [[any string I want]],
    neededlink     = 600,
    pylonrange     = 200,

    outline_x = 235,
    outline_y = 235,
    outline_yoff = 42.5,
  },

  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 10,
  footprintZ                    = 10,
  health                        = 12000,
  iconType                      = [[mahlazer]],
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  metalCost                     = 60000,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[starlight.dae]],
  script                        = [[mahlazer.lua]],
  onoffable                     = true,
  selfDestructAs                = [[ATOMIC_BLAST]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:IMMA_LAUNCHIN_MAH_LAZER]],
    },
  },
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo]],

  weapons                       = {
    {
      def                = [[TARGETER]],
      badTargetCategory  = [[FIXEDWING GUNSHIP SATELLITE]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP SATELLITE]],
    },
    {
      def                = [[RELAYLAZER]],
      onlyTargetCategory = [[NONE]],
    },
    {
      def                = [[RELAYCUTTER]],
      onlyTargetCategory = [[NONE]],
    },
  },


  weaponDefs                    = {

    TARGETER = {
      name                    = [[Aimer (Fake)]],
      alwaysVisible           = 18,
      areaOfEffect            = 56,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      coreThickness           = 0.5,

      customParams              = {
        light_radius = 0,
      },

      damage                  = {
        default = -0.00001,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 10000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser8]],
      soundTrigger            = true,
      texture1                = [[largelaser]],
      texture2                = [[none]],
      texture3                = [[none]],
      texture4                = [[none]],
      thickness               = 0,
      tolerance               = 65536,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
    RELAYLAZER    = {
      name                    = [[Craterpuncher]],
      alwaysVisible           = 18,
      areaOfEffect            = 140,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams              = {
        stats_damage = 18000,
        stats_hide_shield_damage = 1,
        light_radius = 0,
        lups_noshockwave = [[1]],
      },

      damage                  = {
        default = 800,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 10000,
      reloadtime              = 20,
      rgbColor                = [[0.25 0 1]],
      scrollSpeed             = 8,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      --texture2                = [[flare]],
      --texture3                = [[flare]],
      --texture4                = [[smallflare]],
      thickness               = 100,
      tolerance               = 65536,
      tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
    RELAYCUTTER    = {
      name                    = [[Cutter]],
      alwaysVisible           = 18,
      areaOfEffect            = 140,
      avoidFeature            = false,
      avoidNeutral            = false,
      avoidGround             = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 2,
      craterMult              = 4,

      customParams              = {
        light_radius = 0,
        stats_hide_damage = 1,
        stats_hide_reload = 1,
      },

      damage                  = {
        default = 150,
      },

      explosionGenerator      = [[custom:FLASHLAZER]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 12,
      minIntensity            = 1,
      range                   = 10000,
      reloadtime              = 1/30,
      rgbColor                = [[0.25 0 1]],
      scrollSpeed             = 8,
      soundTrigger            = true,
      texture1                = [[largelaser]],
      --texture2                = [[flare]],
      --texture3                = [[flare]],
      --texture4                = [[smallflare]],
      thickness               = 50,
      tolerance               = 65536,
      tileLength              = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      collisionVolumeScales = [[150 200 150]],
      collisionVolumeType   = [[ellipsoid]],
      featureDead      = [[HEAP]],
      footprintX       = 10,
      footprintZ       = 10,
      object           = [[starlight_dead.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 10,
      footprintZ       = 10,
      object           = [[debris3x3c.s3o]],
    },

  },
} }
