return { veharty = {
  unitname            = [[veharty]],
  name                = [[Badger]],
  description         = [[Artillery Minelayer Rover]],
  acceleration        = 0.168,
  brakeRate           = 0.96,
  buildCostMetal      = 270,
  builder             = false,
  buildPic            = [[veharty.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    selection_scale   = 0.85,
    bait_level_default = 0,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  highTrajectory      = 1,
  iconType            = [[vehiclearty]],
  leaveTracks         = true,
  maneuverleashlength = [[650]],
  maxDamage           = 450,
  maxSlope            = 18,
  maxVelocity         = 1.85,
  maxWaterDepth       = 22,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[corwolv.s3o]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:wolvmuzzle0]],
      [[custom:wolvmuzzle1]],
      [[custom:wolvflash]],
    },

  },
  sightDistance       = 660,
  trackOffset         = 6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turninplace         = 0,
  turnRate            = 640, --NB: be wary about large turning circles wandering into HLT.
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MINE]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    MINE = {
      name                    = [[Light Mine Artillery]],
      accuracy                = 1500,
      areaOfEffect            = 96,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        reaim_time = 8, -- COB
        damage_vs_shield = [[190]],
        damage_vs_feature = [[190]],
        force_ignore_ground = [[1]],

        spawns_name = "wolverine_mine",
        spawns_expire = 60,
        spawn_blocked_by_shield = 1,
        
        light_radius = 0,
      },
      
      damage                  = {
        default = 20,
        planes  = 20,
      },

      explosionGenerator      = [[custom:dirt]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      model                   = [[clawshell.s3o]],
      myGravity               = 0.34,
      noSelfDamage            = true,
      range                   = 750,
      reloadtime              = 5.6,
      soundHit                = [[weapon/cannon/badger_hit]],
      soundStart              = [[weapon/cannon/badger_fire]],
      soundHitVolume          = 8,
      soundStartVolume        = 12,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[corwolv_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
