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
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -10 0]],
    modelradius    = [[30]],
  },

  damageModifier         = 0.25,
  explodeAs              = [[BIG_UNIT]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[spidersupport]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 4000,
  maxSlope               = 36,
  maxVelocity            = 1.35,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT4]],
  moveState              = 0,
  noChaseCategory        = [[FIXEDWING GUNSHIP]],
  objectName             = [[ARMCRABE]],
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
  turnRate               = 600,

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
        light_color = [[1.5 1.13 0.6]],
        light_radius = 450,
      },

      damage                  = {
        default = 600.5,
        subs    = 30,
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
