unitDef = {
  unitname               = [[vehaa]],
  name                   = [[Crasher]],
  description            = [[Fast AA Vehicle]],
  acceleration           = 0.05952,
  brakeRate              = 0.14875,
  buildCostEnergy        = 260,
  buildCostMetal         = 260,
  builder                = false,
  buildPic               = [[vehaa.png]],
  buildTime              = 260,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[32 40 52]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    helptext       = [[The Crasher is a speedy solution to enemy bomber attacks, and also works well against gunships.]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehicleaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maneuverleashlength    = [[30]],
  mass                   = 242,
  maxDamage              = 900,
  maxSlope               = 18,
  maxVelocity            = 3.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[vehaa.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],
  
  sfxtypes               = {

  explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },
  
  side                   = [[CORE]],
  sightDistance          = 660,
  smoothAnim             = true,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 653,
  upright                = false,
  workerTime             = 0,

  weapons                       = {

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Heavy Missile]],
      areaOfEffect            = 32,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,

      damage                  = {
        default = 40,
        planes  = 400,
        subs    = 20,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fixedlauncher           = true,
      fireStarter             = 70,
      flightTime              = 3,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      range                   = 730,
      reloadtime              = 4,
      renderType              = 1,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundStart              = [[weapon/missile/missile_fire]],
      startVelocity           = 300,
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 250,
      weaponTimer             = 6,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 700,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Lancer]],
      blocking         = true,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[32 40 52]],
      collisionVolumeTest    = 1,
      collisionVolumeType    = [[box]],      
      damage           = 900,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 104,
      object           = [[vehaa_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 104,
    },


    HEAP  = {
      description      = [[Debris - Lancer]],
      blocking         = false,
      damage           = 900,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 52,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 52,
    },

  },

}

return lowerkeys({ vehaa = unitDef })
