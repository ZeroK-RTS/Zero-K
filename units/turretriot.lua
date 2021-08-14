return { turretriot = {
  unitname                      = [[turretriot]],
  name                          = [[Stardust]],
  description                   = [[Anti-Swarm Turret]],
  activateWhenBuilt             = true,
  buildCostMetal                = 220,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[turretriot_aoplane.dds]],
  buildPic                      = [[turretriot.png]],
  category                      = [[FLOAT TURRET]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[45 45 45]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_target = 4,
    aimposoffset   = [[0 12 0]],
    midposoffset   = [[0 4 0]],
    aim_lookahead  = 50,
    heat_per_shot  = 0.038, -- Heat is always a number between 0 and 1
    heat_decay     = 1/6, -- Per second
    heat_max_slow  = 0.5,
    heat_initial   = 1,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseriot]],
  levelGround                   = false,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  noChaseCategory               = [[FIXEDWING LAND SHIP SWIM GUNSHIP SUB HOVER]],
  objectName                    = [[afury.s3o]],
  script                        = "turretriot.lua",
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:DEVA_SHELLS]],
    },

  },

  sightDistance                 = 499, -- Range*1.1 + 48 for radar overshoot
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooo ooo ooo]],

  weapons                       = {

    {
      def                = [[turretriot_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      mainDir            = [[0 1 0]],
      maxAngleDif        = 240,
    },

  },

  weaponDefs                    = {

    turretriot_WEAPON = {
      name                    = [[Pulse Autocannon]],
      accuracy                = 2300,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      avoidFeature            = false,
      burnblow                = true,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      customparams = {
        light_color = [[0.8 0.76 0.38]],
        light_radius = 180,
        proximity_priority = 5, -- Don't use this unless required as it causes O(N^2) seperation checks per slow update.
      },

      damage                  = {
        default = 45,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 410,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      soundStartVolume        = 0.5,
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[afury_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
