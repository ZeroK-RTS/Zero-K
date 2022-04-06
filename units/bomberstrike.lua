return { bomberstrike = {
  unitname            = [[bomberstrike]],
  name                = [[Kestrel]],
  description         = [[Tactical Strike Bomber]],
  brakerate           = 0.4,
  buildCostMetal      = 240,
  builder             = false,
  buildPic            = [[bomberstrike.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 18 80]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 160,

  customParams        = {
    reallyabomber    = [[1]],
    reammoseconds    = [[8]],
    refuelturnradius = [[150]],
    requireammo      = [[1]],
    modelradius      = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberskirm]],
  maxAcc              = 0.5,
  maxAileron          = 0.02,
  maxDamage           = 780,
  maxElevator         = 0.01,
  maxRudder           = 0.007,
  maxFuel             = 1000000,
  maxVelocity         = 8.4,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[bomberstrike.s3o]],
  script              = [[bomberstrike.lua]],
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {},
  sightDistance       = 780,
  turnRadius          = 500,
  workerTime          = 0,

  weapons             = {
    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SINK SUB]],
    },
  },


  weaponDefs          = {
  
    MISSILE = {
      name                    = [[Heavy Missiles]],
      areaOfEffect            = 96,
      cegTag                  = [[missiletrailgreen]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 270,
        planes  = 270,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.2,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[wep_m_dragonsfang.s3o]],
      projectiles             = 2,
      range                   = 400,
      reloadtime              = 10,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/rapid_rocket_fire2]],
      soundStartVolume        = 7,
      startVelocity           = 260,
      texture2                = [[lightsmoketrail]],
      tolerance               = 4000,
      tracks                  = true,
      trajectoryHeight        = 0,
      turnRate                = 8000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 40,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 260,
    },
    
  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[bomberstrike_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
