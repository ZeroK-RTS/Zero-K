return { hoveraa = {
  unitname            = [[hoveraa]],
  name                = [[Flail]],
  description         = [[Anti-Air Hovercraft]],
  acceleration        = 0.288,
  activateWhenBuilt   = true,
  brakeRate           = 0.516,
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
    bait_level_default = 0,
    modelradius    = [[25]],
    midposoffset   = [[0 8 0]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoveraa]],
  maxDamage           = 950,
  maxSlope            = 36,
  maxVelocity         = 3.5,
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
  turnRate            = 985,
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
      texture1                = [[flarescale01]],
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

} }
