return { turretaaheavy = {
  unitname                      = [[turretaaheavy]],
  name                          = [[Artemis]],
  description                   = [[Very Long-Range Anti-Air Missile Tower, Drains 4 m/s, 20 second stockpile]],
  activateWhenBuilt             = true,
  buildCostMetal                = 2400,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[turretaaheavy_aoplane.dds]],
  buildPic                      = [[turretaaheavy.png]],
  category                      = [[SINK]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[74 74 74]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 2,
    modelradius    = [[37]],
    stockpilecost  = [[80]],
    stockpiletime  = [[20]],
    priority_misc  = 1, -- Medium
    okp_damage = 1600,
  },

  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[heavysam]],
  maxDamage                     = 3200,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  noAutoFire                    = false,
  objectName                    = [[SCREAMER.s3o]],
  onoffable                     = false,
  script                        = [[turretaaheavy.lua]],
  selfDestructAs                = [[ESTOR_BUILDING]],
  sightDistance                 = 660,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],

  weapons                       = {

    {
      def                = [[ADVSAM]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP SATELLITE]],
    },

  },


  weaponDefs                    = {

    ADVSAM = {
      name                    = [[Advanced Anti-Air Missile]],
      areaOfEffect            = 240,
      canAttackGround         = false,
      cegTag                  = [[turretaaheavytrail]],
      craterBoost             = 0.1,
      craterMult              = 0.2,
      cylinderTargeting       = 3.2,

      customParams              = {
        isaa = [[1]],
        radar_homing_distance = 1800,

        light_color = [[1.5 1.8 1.8]],
        light_radius = 600,
      },

      damage                  = {
        default    = 160.15,
        planes     = 1601.5,
      },

      edgeEffectiveness       = 0.25,
      energypershot           = 80,
      explosionGenerator      = [[custom:MISSILE_HIT_SPHERE_120]],
      fireStarter             = 90,
      flightTime              = 4,
      groundbounce            = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      metalpershot            = 80,
      model                   = [[wep_m_avalanche.s3o]], -- Model radius 180 for QuadField fix.
      noSelfDamage            = true,
      range                   = 2400,
      reloadtime              = 1.8,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/heavy_aa_hit]],
      soundStart              = [[weapon/missile/heavy_aa_fire2]],
      startVelocity           = 1000,
      stockpile               = true,
      stockpileTime           = 10000,
      texture1                = [[flarescale01]],
      tolerance               = 10000,
      tracks                  = true,
      trajectoryHeight        = 0.55,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 600,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1600,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[screamer_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
