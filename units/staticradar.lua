return { staticradar = {
  unitname                      = [[staticradar]],
  name                          = [[Radar Tower]],
  description                   = [[Early Warning System]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostMetal                = 55,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticradar_aoplane.dds]],
  buildPic                      = [[staticradar.png]],
  canMove                       = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 -32 0]],
  collisionVolumeScales         = [[32 90 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],
  
  customParams = {
    morphto        = [[planelightscout]],
    morphtime      = 24,
    modelradius    = [[16]],
    priority_misc  = 2, -- High
    addfight       = 1,
    addpatrol      = 1,
  },
  
  energyUse                     = 0.8,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[radar]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 80,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[ARADARLVL1.s3o]],
  script                        = [[staticradar.lua]],
  onoffable                     = true,
  radarDistance                 = 2100,
  radarEmitHeight               = 32,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 800,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooo]],
  
    sfxtypes               = {

    explosiongenerators = {
      [[custom:scanner_ping]]
    },

  },

  weapons                       = {
    --{
    --  def                = [[TARGETER]],
    --  onlyTargetCategory = [[NONE]],
    --},
    --{
    --  def                = [[SCANNERSWEEP]],
    --  onlyTargetCategory = [[NONE]],
    --},
  },


  weaponDefs                    = {

    TARGETER = {
      name                    = [[Scanning Lidar]],
      avoidFeature            = false,
      avoidNeutral            = false,
      beamTime                = 1/30,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -1E-06,
        planes  = -1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      largeBeamLaser          = false,
      laserFlareSize          = 1,
      minIntensity            = 1,
      range                   = 500,
      reloadtime              = 0.033,
      rgbColor                = [[0 0.7 0.6]],
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 1,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
    },
    
    SCANNERSWEEP    = {
      name                    = [[Scanner Sweep]],
      areaOfEffect            = 1200,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = -1E-06,
      },

      customParams           = {
    lups_noshockwave = "1",
    nofriendlyfire = "1",
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:none]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1,
      soundHitVolume          = 1,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 230,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[ARADARLVL1_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
