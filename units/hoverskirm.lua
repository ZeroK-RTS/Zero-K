return { hoverskirm = {
  unitname            = [[hoverskirm]],
  name                = [[Scalpel]],
  description         = [[Skirmisher/Anti-Heavy Hovercraft]],
  acceleration        = 0.2175,
  activateWhenBuilt   = true,
  brakeRate           = 2.05,
  buildCostMetal      = 220,
  builder             = false,
  buildPic            = [[hoverskirm.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[38 38 38]],

  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
    turnatfullspeed = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 680,
  maxSlope            = 18,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[nsaclash.s3o]],
  script              = [[hoverskirm.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:JANUSMUZZLE]],
      [[custom:JANUSBACK]],
    },

  },

  sightDistance       = 484,
  sonarDistance       = 484,
  turninplace         = 0,
  turnRate            = 420,
  workerTime          = 0,
  
  weapons             = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

  },


  weaponDefs          = {

    MISSILE = {
      name                    = [[Heavy Missile Battery]],
      areaOfEffect            = 80,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 1.4,
      
      customParams        = {
        burst = Shared.BURST_RELIABLE,

        light_camera_height = 3000,
        light_color = [[1 0.58 0.17]],
        light_radius = 200,
      },
      
      damage                  = {
        default = 330,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.1,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      leadlimit               = 0,
      model                   = [[wep_m_dragonsfang.s3o]],
      projectiles             = 2,
      range                   = 440,
      reloadtime              = 10,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startVelocity           = 190,
      texture2                = [[lightsmoketrail]],
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 21000,
      turret                  = true,
      weaponAcceleration      = 90,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 180,
    },
    
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[nsaclash_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
