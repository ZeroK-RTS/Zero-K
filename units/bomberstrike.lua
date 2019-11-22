return { bomberstrike = {
  unitname            = [[bomberstrike]],
  name                = [[Kestrel]],
  description         = [[Tactical Strike Bomber]],
  brakerate           = 0.4,
  buildCostMetal      = 400,
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
    --modelradius    = [[10]],
  },

  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[bomber]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxAcc              = 0.5,
  maxDamage           = 900,
  maxElevator         = 0.02,
  maxRudder           = 0.006,
  maxFuel             = 1000000,
  maxVelocity         = 7.8,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[bomberstrike.s3o]],
  script              = [[bomberstrike.lua]],
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {},
  sightDistance       = 660,
  turnRadius          = 80,
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
        default = 450,
        planes  = 450,
      },

      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      model                   = [[wep_m_dragonsfang.s3o]],
      projectiles             = 2,
      range                   = 360,
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
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 90,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
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
