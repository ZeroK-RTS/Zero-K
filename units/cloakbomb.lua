return { cloakbomb = {
  unitname               = [[cloakbomb]],
  name                   = [[Imp]],
  description            = [[All Terrain EMP Bomb (Burrows)]],
  acceleration           = 0.75,
  brakeRate              = 3.6,
  buildCostMetal         = 120,
  buildPic               = [[cloakbomb.png]],
  canMove                = true,
  category               = [[LAND SMALL TOOFAST]],
  cloakCost              = 0,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[16 16 16]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    midposoffset   = [[0 0 -2]],
    modelradius    = [[8]],
    instantselfd   = [[1]],
    idle_cloak = 1,
    selection_scale = 1, -- Maybe change later
  },

  explodeAs              = [[cloakbomb_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[spiderbomb]],
  kamikaze               = true,
  kamikazeDistance       = 85,
  kamikazeUseLOS         = true,
  leaveTracks            = true,
  maxDamage              = 50,
  maxSlope               = 72,
  maxVelocity            = 4.2,
  movementClass          = [[TKBOT2]],
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[armtick.s3o]],
  pushResistant          = 0,
  script                 = [[cloakbomb.lua]],
  selfDestructAs         = [[cloakbomb_DEATH]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:digdig]],
    },

  },

  sightDistance          = 240,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShortLarge]],
  trackWidth             = 20,
  turnRate               = 3600,
  
  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[armtick_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 1,
      footprintZ       = 1,
      object           = [[debris1x1a.s3o]],
    },

  },
  weaponDefs = {
    cloakbomb_DEATH = {
      areaOfEffect       = 352,
      craterBoost        = 0,
      craterMult         = 0,
      edgeEffectiveness  = 0.5,
      explosionGenerator = "custom:cloakbomb_EXPLOSION",
      explosionSpeed     = 10,
      impulseBoost       = 0,
      impulseFactor      = 0,
      name               = "EMP Explosion",
      paralyzer          = true,
      paralyzeTime       = 16,
      soundHit           = "weapon/more_lightning",
      damage = {
        default          = 2500,
      },
      customParams = {
        burst = Shared.BURST_UNRELIABLE,
       },
    },
  }
} }
