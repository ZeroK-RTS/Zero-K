return { turretaaclose = {
  unitname                      = [[turretaaclose]],
  name                          = [[Hacksaw]],
  description                   = [[Burst Anti-Air Turret]],
  buildCostMetal                = 220,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[turretaaclose_aoplane.dds]],
  buildPic                      = [[turretaaclose.png]],
  category                      = [[FLOAT]],
  collisionVolumeOffsets        = [[0 12 0]],
  collisionVolumeScales         = [[42 53 42]],
  collisionVolumeType            = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_default = 1,
    aim_lookahead      = 120,
    okp_damage = 500.1,
  },

  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[defenseskirmaa]],
  levelGround                   = false,
  maxDamage                     = 580,
  maxSlope                      = 18,
  noAutoFire                    = false,
  noChaseCategory               = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName                    = [[turretaaclose.s3o]],
  script                        = [[turretaaclose.lua]],
  selfDestructAs                = [[SMALL_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },
  sightDistance                 = 560,
  useBuildingGroundDecal        = true,
  waterline                     = 10,
  workerTime                    = 0,
  yardMap                       = [[ooooooooo]],

  weapons                       = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 24,
      canattackground         = false,
      cegTag                  = [[missiletrailbluebig]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 3,

      customParams = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        script_reload = [[15]],
        script_burst = [[2]],
        light_color = [[0.5 0.6 0.6]],
      },

      damage                  = {
        default = 50.1,
        planes  = 500.1,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      leadLimit               = 0,
      model                   = [[wep_m_phoenix.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 490,
      reloadtime              = 0.2,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/missile_fire3]],
      startVelocity           = 620,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      tracks                  = true,
      turnRate                = 130000,
      turret                  = true,
      weaponAcceleration      = 0,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 620,
    },

  },


  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[turretaaclose_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
