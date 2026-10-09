return { vehheavyassault = {
  name                = [[Demolisher]],
  description         = [[Heavy Assault Rover]],
  acceleration        = 0.191,
  brakeRate           = 1.488,
  builder             = false,
  buildPic            = [[vehheavyassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[63 63 63]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    selection_scale   = 0.85,
    aim_lookahead     = 100,
    set_target_range_buffer = 50,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  health              = 7200,
  iconType            = [[vehicleassault]],
  leaveTracks         = true,
  maxSlope            = 18,
  maxWaterDepth       = 22,
  metalCost           = 1700,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[demolisher.s3o]],
  script              = [[vehheavyassault.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RIOT_SHELL_L]],
    },

  },
  sightDistance       = 800,
  speed               = 63,
  trackOffset         = 7,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 28,
  turninplace         = 0,
  turnRate            = 624,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DEMOLISHER_BLASTER]],
      accurateLeading    = 1,
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    DEMOLISHER_BLASTER  = {
      name                    = [[Obliteration Blaster]],
      areaOfEffect            = 112,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      avoidNeutral            = false,
      burst                   = 3,
      burstRate               = 0.1 + 1/30,
      coreThickness           = 2.5,
      craterBoost             = 2,
      craterMult              = 2,
      commandFire             = true,

      customparams = {
        light_radius = 380,
        light_color = [[0.5 0.95 0]],
        gatherradius = [[192]],
        smoothradius = [[128]],
        smoothmult   = [[0.7]],
        smoothexponent = [[0.8]],
        smoothheightoffset = [[22]],
        burst = Shared.BURST_UNRELIABLE,
        -- no `movestructures` because then they can "dodge" via sudden movement
      },
      
      damage                  = {
        default = 1200.1,
      },

      duration                = 0.05,
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:slam]],
      fallOffRate             = 0.1,
      fireStarter             = 10,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      range                   = 700,
      reloadtime              = 10 + 6/30,
      rgbColor                = [[0.1 1 0]],
      rgbColor2               = [[0.5 0.1 0.2]],
      sprayAngle              = 300,
      soundHit                = [[explosion/mini_nuke]],
      soundStart              = [[PulseLaser]],
      soundTrigger            = false,
      sweepfire               = false,
      texture1                = [[largelaser_long]],
      texture2                = [[flare]],
      texture3                = [[largelaser_long]],
      texture4                = [[largelaser_long]],
      thickness               = 9,
      tolerance               = 2000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1500,
    },
  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[demolisher_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
