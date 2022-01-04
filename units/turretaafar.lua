return { turretaafar = {
  unitname                      = [[turretaafar]],
  name                          = [[Chainsaw]],
  description                   = [[Long-Range Anti-Air Missile Battery]],
  buildCostMetal                = 900,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 3.6,
  buildingGroundDecalSizeY      = 3.6,
  buildingGroundDecalType       = [[turretaafar_aoplane.dds]],
  buildPic                      = [[turretaafar.png]],
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 12 0]],
  collisionVolumeScales         = [[58 76 58]],
  collisionVolumeType            = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 1,
    aimposoffset   = [[0 10 0]],
    modelradius    = [[19]],
    okp_damage = 200.1,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 4,
  footprintZ                    = 4,
  iconType                      = [[staticskirmaa]],
  losEmitHeight                 = 40,
  maxDamage                     = 2500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 5000,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[armcir.s3o]],
  script                        = [[turretaafar.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  sightDistance                 = 702,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oooooooooooooooo]],
    
  sfxtypes            = {

    explosiongenerators = {
      [[custom:light_red_short]],
      [[custom:light_green_short]],
      [[custom:light_blue_short]],
    },

  },
    
  weapons                       = {

    {
      def                = [[MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Long-Range SAM]],
      areaOfEffect            = 24,
      canattackground         = false,
      cegTag                  = [[chainsawtrail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        light_color = [[0.6 0.7 0.7]],
        light_radius = 420,
      },

      damage                  = {
        default = 22.51,
        planes  = 225.1,
      },

      explosionGenerator      = [[custom:MISSILE_HIT_PIKES_160]],
      fireStarter             = 20,
      flightTime              = 4,
      impactOnly              = true,
      impulseBoost            = 0.123,
      impulseFactor           = 0.0492,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 1800,
      reloadtime              = 1,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/med_aa_hit]],
      soundStart              = [[weapon/missile/med_aa_fire]],
      soundTrigger            = true,
      startVelocity           = 550,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      tolerance               = 16000,
      tracks                  = true,
      turnRate                = 55000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 550,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[chainsaw_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
