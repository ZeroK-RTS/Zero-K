return { amphaa = {
  unitname               = [[amphaa]],
  name                   = [[Angler]],
  description            = [[Amphibious Anti-Air Bot]],
  acceleration           = 0.54,
  activateWhenBuilt      = true,
  brakeRate              = 2.25,
  buildCostMetal         = 180,
  buildPic               = [[amphaa.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 20,
    amph_submerged_at = 40,
    sink_on_emp    = 1,
    floattoggle = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[amphaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 36,
  maxVelocity            = 1.6,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT3]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[amphaa.s3o]],
  script                 = [[amphaa.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },
  },

  sightDistance          = 660,
  sonarDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 30,
  turnRate               = 1000,
  upright                = true,

  weapons                = {

    {
      def                = [[MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    MISSILE = {
      name                    = [[Missile Pack]],
      areaOfEffect            = 48,
      canAttackGround         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

      customParams            = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        script_reload = [[12]],
        script_burst = [[4]],
        light_color = [[0.5 0.6 0.6]],
        light_radius = 380,
      },

      damage                  = {
        default = 15.01,
        planes  = 150.1,
        subs    = 8,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]],
      noSelfDamage            = true,
      range                   = 820,
      reloadtime              = 0.3,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 650,
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 141,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 850,
    },

  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[amphaa_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
