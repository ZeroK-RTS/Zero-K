return { turretheavylaser = {
  unitname                      = [[turretheavylaser]],
  name                          = [[Stinger]],
  description                   = [[High-Energy Laser Tower]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 420,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[turretheavylaser_aoplane.dds]],
  buildPic                      = [[turretheavylaser.png]],
  category                      = [[FLOAT TURRET]],
  collisionVolumeOffsets        = [[0 17 0]],
  collisionVolumeScales         = [[36 110 36]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset   = [[0 15 0]],
  },

  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseheavy]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  losEmitHeight                 = 80,
  maxDamage                     = 2475,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SHIP SATELLITE SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[hlt.s3o]],
  script                        = [[turretheavylaser.lua]],
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:HLTRADIATE0]],
      [[custom:beamlaser_hit_blue]],
    },

  },
  sightDistance                 = 730, -- Range*1.1 + 48 for radar overshoot
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooo ooo ooo]],

  weapons                       = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    LASER = {
      name                    = [[High-Energy Laserbeam]],
      areaOfEffect            = 14,
      beamTime                = 0.8,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        burst = Shared.BURST_UNRELIABLE,

        light_color = [[1.25 1.25 3.75]],
        light_radius = 180,
      },

      damage                  = {
        default = 850.1,
        planes  = 850.1,
        subs    = 45.1,
      },

      explosionGenerator      = [[custom:flash1bluedark]],
      fireStarter             = 90,
      fireTolerance           = 8192, -- 45 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 10.4,
      leadLimit               = 18,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 620,
      reloadtime              = 4.5,
      rgbColor                = [[0 0 1]],
      scrollSpeed             = 5,
      soundStart              = [[weapon/laser/heavy_laser3]],
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 10.4024486300101,
      tileLength              = 300,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2250,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corhlt_d.s3o]],
    },
    

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
