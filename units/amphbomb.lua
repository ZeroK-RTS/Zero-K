return { amphbomb = {
  unitname               = [[amphbomb]],
  name                   = [[Limpet]],
  description            = [[Amphibious Slow Bomb]],
  acceleration           = 0.45,
  activateWhenBuilt      = true,
  brakeRate              = 1.2,
  buildCostMetal         = 160,
  buildPic               = [[AMPHBOMB.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[16 12 22]],
  collisionVolumeType    = [[box]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 10,
    amph_submerged_at = 30,
    midposoffset   = [[0 5 0]],
 },

  explodeAs              = [[AMPHBOMB_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphbomb]],
  kamikaze               = true,
  kamikazeDistance       = 120,
  kamikazeUseLOS         = true,
  leaveTracks            = true,
  maxDamage              = 400,
  maxSlope               = 36,
  maxVelocity            = 4,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[amphbomb.s3o]],
  pushResistant          = 0,
  script                 = [[amphbomb.lua]],
  selfDestructAs         = [[AMPHBOMB_DEATH]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:RIOTBALL]],
    },

  },
  sightDistance          = 240,
  sonarDistance          = 240,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShortLarge]],
  trackWidth             = 30,
  turnRate               = 3600,
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphbomb_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },
  weaponDefs = {
    AMPHBOMB_DEATH = {
      areaOfEffect       = 500,
      craterBoost        = 1,
      craterMult         = 3.5,
      customparams = {
          lups_explodespeed = 1.04,
          lups_explodelife = 0.88,
          timeslow_damagefactor = 10,
          timeslow_overslow_frames = 2*30, --2 seconds before slow decays
          nofriendlyfire = 1,
          light_color = [[1.88 0.63 2.5]],
          light_radius = 320,
      },
     
      damage = {
        default          = 120.1,
      },
     
      edgeEffectiveness  = 0.4,
      explosionGenerator = "custom:riotballplus2_purple_limpet",
      explosionSpeed     = 10,
      impulseBoost       = 0,
      impulseFactor      = 0.3,
      name               = "Slowing Explosion",
      soundHit           = [[weapon/aoe_aura2]],
      soundHitVolume     = 4,
    },
  }
} }
