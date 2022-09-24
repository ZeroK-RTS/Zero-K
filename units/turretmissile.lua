return { turretmissile = {
  unitname                      = [[turretmissile]],
  name                          = [[Picket]],
  description                   = [[Light Missile Tower]],
  buildCostMetal                = 100,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[turretmissile_aoplane.dds]],
  buildPic                      = [[turretmissile.png]],
  category                      = [[FLOAT TURRET CHEAP]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[24 70 24]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset   = [[0 20 0]],
    bait_level_default = 0,
    okp_damage = 103,

    outline_x = 60,
    outline_y = 70,
    outline_yoff = 27.5,
  },

  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[defenseskirm]],
  levelGround                   = false,
  losEmitHeight                 = 40,
  maxDamage                     = 340,
  maxSlope                      = 36,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[lmt2.s3o]],
  script                        = [[turretmissile.lua]],
  selfDestructAs                = [[BIG_UNITEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:PULVMUZZLE]],
      [[custom:PULVBACK]],
    },

  },
  sightDistance                 = 719, -- Range*1.1 + 48 for radar overshoot
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[oo oo]],

  weapons                       = {

    {
      def                = [[ARMRL_MISSILE]],
      --badTargetCategory  = [[HOVER SWIM LAND SINK FLOAT SHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs                    = {

    ARMRL_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 8,
      avoidFeature            = true,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 5,

      customParams            = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        script_reload = [[12.5]],
        script_burst = [[3]],
        prevent_overshoot_fudge = 45, -- projectile speed is 25 elmo/frame

        light_camera_height = 2000,
        light_radius = 200,
      },

      damage                  = {
        default = 104.001,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 4,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[hobbes.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 610,
      reloadtime              = 1.2,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_small13]],
      soundStart              = [[weapon/missile/missile_fire11]],
      startVelocity           = 500,
      texture1                = [[flarescale01]],
      texture2                = [[lightsmoketrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Pulverizer_d.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
