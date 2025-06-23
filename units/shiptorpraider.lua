return { shiptorpraider = {
  name                = [[Hunter]],
  description         = [[Torpedo Raider Ship (Anti-Sub)]],
  acceleration        = 0.288,
  activateWhenBuilt   = true,
  brakeRate           = 0.516,
  builder             = false,
  buildPic            = [[shiptorpraider.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category               = [[SHIP SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 0 -2]],
  collisionVolumeScales  = [[30 30 60]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius        = [[14]],
    turnatfullspeed    = [[1]],
    aim_lookahead      = 80,
    bait_level_default = 0,
    okp_damage = 180,
    model_rescale = 0.9,
    selectionscalemult = 1.3,
    selectionwidthscalemult = 1.75,
    selectioninherit = 1,
  },


  explodeAs           = [[SMALL_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  health              = 360,
  iconType            = [[shiptorpraider]],
  maneuverleashlength = [[1280]],
  metalCost           = 100,
  minWaterDepth       = 5,
  movementClass       = [[BOAT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE HOVER]],
  objectName          = [[shiptorpraider.dae]],
  script              = [[shiptorpraider.lua]],
  selfDestructAs      = [[SMALL_UNITEX]],
  sightDistance       = 560,
  sonarDistance       = 560,
  speed               = 126,
  turnRate            = 1280,
  waterline           = 0,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    TORPEDO = {

      name                    = [[Torpedo]],
      areaOfEffect            = 64,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.5,
      burnblow                = 1,
      canAttackGround          = false, -- workaround for range hax
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[torpedo_trail]],

      customParams = {
        burst = Shared.BURST_RELIABLE,

        stays_underwater = 1,
      },

      damage                  = {
        default = 220.1,
      },

      edgeEffectiveness       = 0.6,

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      fixedLauncher           = true,
      groundbounce            = 1,
      impulseBoost            = 1,
      impulseFactor           = 0.9,
      interceptedByShieldType = 1,
      flightTime              = 0.9,
      leadlimit               = 0,
      model                   = [[wep_t_barracuda.s3o]],
      myGravity               = 10.1,
      numbounce               = 4,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 2.6,
      soundHit                = [[TorpedoHitVariable]],
      soundHitVolume          = 5,
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 5.2,
      startVelocity           = 60,
      tolerance               = 100000,
      tracks                  = true,
      turnRate                = 200000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 440,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[shiptorpraider_dead.dae]],
    },


    HEAP  = {
      blocking         = false,

      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
