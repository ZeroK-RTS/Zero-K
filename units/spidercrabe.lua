return { spidercrabe = {
  unitname               = [[spidercrabe]],
  name                   = [[Crab]],
  description            = [[Heavy Riot/Skirmish Spider - Curls into Armored Form When Stationary]],
  acceleration           = 0.66,
  brakeRate              = 1.08,
  buildCostMetal         = 1600,
  buildPic               = [[spidercrabe.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 60 60]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -10 0]],
    modelradius    = [[30]],
    unstick_leeway    = 60, -- Don't lose move orders for longer while preparing to move.

    outline_x = 110,
    outline_y = 110,
    outline_yoff = 5,
  },

  damageModifier         = 0.333,
  explodeAs              = [[BIG_UNIT]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[spidersupport]],
  leaveTracks            = true,
  maxDamage              = 4200,
  maxSlope               = 36,
  maxVelocity            = 1.35,
  maxWaterDepth          = 22,
  movementClass          = [[TKBOT4]],
  moveState              = 0,
  noChaseCategory        = [[FIXEDWING GUNSHIP]],
  objectName             = [[armcrabe.s3o]],
  pushResistant          = 0,
  script                 = [[spidercrabe.lua]],
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
    --  [[custom:spidercrabe_FLARE]],
      [[custom:LARGE_MUZZLE_FLASH_FX]],
      [[custom:spidercrabe_FLASH]],
      [[custom:spidercrabe_WhiteLight]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[crossFoot]],
  trackWidth             = 50,
  turnRate               = 720,

  weapons                = {

    {
      def                = [[ARM_CRABE_GAUSS]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },

  weaponDefs             = {

    ARM_CRABE_GAUSS = {
      name                    = [[Heavy Plasma Cannon]],
      areaOfEffect            = 200,
      craterBoost             = 0,
      craterMult              = 0.5,

      customParams            = {
        force_ignore_ground = [[1]],
        light_color = [[1.5 1.13 0.6]],
        light_radius = 450,
      },

      damage                  = {
        default = 600.5,
      },

      edgeEffectiveness       = 0.3,
      explosionGenerator      = [[custom:spidercrabe_EXPLOSION]],
      impulseBoost            = 0,
      impulseFactor           = 0.32,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4,
      soundHit                = [[weapon/cannon/cannon_hit3]],
      soundStart              = [[weapon/cannon/heavy_cannon2]],
      -- size = 5, -- maybe find a good size that is bigger than default
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 290,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 4,
      object           = [[crabe_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
