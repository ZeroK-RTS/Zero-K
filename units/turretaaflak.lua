return { turretaaflak = {
  unitname                      = [[turretaaflak]],
  name                          = [[Thresher]],
  description                   = [[Anti-Air Flak Gun]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 450,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[turretaaflak_aoplane.dds]],
  buildPic                      = [[turretaaflak.png]],
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 11 -4]],
  collisionVolumeScales         = [[50 86 50]],
  collisionVolumeType            = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset   = [[0 16 0]],
  },

  explodeAs                     = [[MEDIUM_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticaa]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 3000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 5000,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[corflak.s3o]],
  script                        = [[turretaaflak.lua]],
  selfDestructAs                = [[MEDIUM_BUILDINGEX]],
  
  sfxtypes               = {

  explosiongenerators = {
      [[custom:HEAVY_CANNON_MUZZLE]],
    },

  },
  sightDistance                 = 660,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooo ooo ooo]],

  weapons                       = {

    {
      def                = [[ARMFLAK_GUN]],
      --badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    ARMFLAK_GUN = {
      name                    = [[Flak Cannon]],
      accuracy                = 500,
      areaOfEffect            = 128,
      burnblow                = true,
      canattackground         = false,
      cegTag                  = [[flak_trail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        light_radius = 0,
      },

      damage                  = {
        default = 13.2,
        planes  = 132,
        subs    = 7,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:flakplosion]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 1000,
      reloadtime              = 0.5,
      size                    = 0.01,
      soundHit                = [[weapon/flak_hit]],
      soundStart              = [[weapon/flak_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corflak_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
