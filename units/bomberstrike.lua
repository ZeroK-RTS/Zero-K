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
  collisionVolumeScales  = [[80 10 30]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  cruiseAlt           = 160,

  customParams        = {
    reallyabomber    = [[1]],
    reammoseconds    = [[5]],
    refuelturnradius = [[90]],
    requireammo      = [[1]],
    modelradius      = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomberskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxAcc              = 0.5,
  maxDamage           = 850,
  maxElevator         = 0.02,
  maxRudder           = 0.006,
  maxFuel             = 1000000,
  maxVelocity         = 7.4,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[bomberstrike.s3o]],
  script              = [[bomberstrike.lua]],
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {},
  sightDistance       = 780,
  turnRadius          = 120,
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
        default = 330,
        planes  = 330,
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
      startVelocity           = 220,
      texture2                = [[lightsmoketrail]],
      tolerance               = 8000,
      tracks                  = true,
      trajectoryHeight        = 0,
      turnRate                = 9000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 40,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 230,
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
