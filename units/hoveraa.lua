unitDef = {
  unitname            = [[hoveraa]],
  name                = [[Flail]],
  description         = [[Anti-Air Hovercraft]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  brakeRate           = 0.043,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoveraa.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets = [[0 0 -5]],
  collisionVolumeScales  = [[40 40 40]],
  collisionVolumeType    = [[ellipsoid]], 
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[20]],
    midposoffset   = [[0 8 0]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoveraa]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maxDamage           = 950,
  maxSlope            = 36,
  maxVelocity         = 3.5,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName          = [[hoveraa.s3o]],
  script              = [[hoveraa.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  sightDistance       = 660,
  sonarDistance       = 660,  
  turninplace         = 0,
  turnRate            = 616,
  workerTime          = 0,
  weapons             = {

    {
      def                = [[WEAPON]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Medium SAM]],
      areaOfEffect            = 64,
      canattackground         = false,
      cegTag                  = [[missiletrailbluebig]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

      customParams            = {
		burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        light_color = [[0.5 0.6 0.6]],
      },

      damage                  = {
        default = 37.5,
        planes  = 375,
        subs    = 20.625,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 100,
      fixedlauncher           = true,
      flightTime              = 3.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[hovermissile.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 5.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/vlaunch_hit]],
      soundStart              = [[weapon/missile/missile_fire8]],
      startvelocity           = 200,
      texture2                = [[AAsmoketrail]],
      tolerance               = 4000,
      tracks                  = true,
      turnRate                = 64000,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoveraa_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

}

return lowerkeys({ hoveraa = unitDef })
