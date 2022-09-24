return { jumpraid = {
  unitname              = [[jumpraid]],
  name                  = [[Pyro]],
  description           = [[Raider/Riot Jumper]],
  acceleration          = 1.2,
  brakeRate             = 7.2,
  buildCostMetal        = 220,
  builder               = false,
  buildPic              = [[jumpraid.png]],
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  category              = [[LAND FIREPROOF TOOFAST]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                = [[DEAD]],

  customParams          = {
    canjump            = 1,
    jump_range         = 400,
    jump_speed         = 6,
    jump_reload        = 10,
    jump_from_midair   = 1,
    fireproof          = [[1]],
    stats_show_death_explosion = 1,
    aim_lookahead      = 80,
    set_target_range_buffer = 30,
    set_target_speed_buffer = 8,
  },

  explodeAs             = [[PYRO_DEATH]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[jumpjetraider]],
  leaveTracks           = true,
  maxDamage             = 690,
  maxSlope              = 36,
  maxVelocity           = 3,
  maxWaterDepth         = 22,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING GUNSHIP SUB]],
  objectName            = [[m-5.s3o]],
  script                = [[jumpraid.lua]],
  selfDestructAs        = [[PYRO_DEATH]],
  selfDestructCountdown = 5,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  sightDistance         = 560,
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ComTrack]],
  trackWidth            = 22,
  turnRate              = 2160,
  upright               = true,
  workerTime            = 0,

  weapons               = {

    {
      def                = [[FLAMETHROWER]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs            = {

    FLAMETHROWER = {
      name                    = [[Flamethrower]],
      areaOfEffect            = 64,
      avoidGround             = false,
      avoidFeature            = false,
      avoidFriendly           = true,
      collideFeature          = false,
      collideGround           = false,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,
      cegTag                  = [[flamer]],

      customParams            = {
        flamethrower = [[1]],
        setunitsonfire = "1",
        burnchance = "0.4", -- Per-impact
        burntime = [[450]],
          
        light_camera_height = 2800,
        light_color = [[0.6 0.39 0.18]],
        light_radius = 260,
        light_fade_time = 10,
        light_beam_mult_frames = 5,
        light_beam_mult = 5,
      
        combatrange = 280,
      },
    
      damage                  = {
        default = 9.2,
      },

      duration                = 0.01,
      explosionGenerator      = [[custom:SMOKE]],
      fallOffRate             = 1,
      fireStarter             = 100,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.3,
      interceptedByShieldType = 1,
      leadLimit               = 2,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 240,
      reloadtime              = 0.133,
      rgbColor                = [[1 1 1]],
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      texture1                = [[flame]],
      thickness               = 0,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 800,
    },

    PYRO_DEATH = {
        name                    = [[Napalm Blast]],
        areaofeffect            = 256,
        craterboost             = 1,
        cratermult              = 3.5,

        customparams              = {
            setunitsonfire = "1",
            burnchance     = "1",
            burntime       = 60,

            area_damage = 1,
            area_damage_radius = 128,
            area_damage_dps = 20,
            area_damage_duration = 13.3,
        },

        damage                  = {
            default = 50,
        },

        edgeeffectiveness       = 0.5,
        explosionGenerator      = [[custom:napalm_pyro]],
        impulseboost            = 0,
        impulsefactor           = 0,
        soundhit                = [[explosion/ex_med3]],
    },
  },

  featureDefs           = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[m-5_dead.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
