unitDef = {
  unitname               = [[jumpbomb]],
  name                   = [[Skuttle]],
  description            = [[Cloaked Jumping Anti-Heavy Bomb]],
  acceleration           = 0.18,
  brakeRate              = 0.54,
  buildCostMetal         = 550,
  builder                = false,
  buildPic               = [[jumpbomb.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 5,
  cloakCostMoving        = 15,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 28]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    canjump          = 1,
    jump_range       = 400,
    jump_height      = 120,
    jump_speed       = 6,
    jump_reload      = 10,
    jump_from_midair = 0,
	aimposoffset   = [[0 2 0]],
	midposoffset   = [[0 2 0]],
	modelradius    = [[10]],
    selection_scale = 1, -- Maybe change later
  },

  explodeAs              = [[jumpbomb_DEATH]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[jumpjetbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  initCloaked            = true,
  kamikaze               = true,
  kamikazeDistance       = 25,
  kamikazeUseLOS         = true,
  maneuverleashlength    = [[140]],
  maxDamage              = 250,
  maxSlope               = 36,
  maxVelocity            = 1.5225,
  maxWaterDepth          = 15,
  minCloakDistance       = 180,
  movementClass          = [[SKBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[skuttle.s3o]],
  selfDestructAs         = [[jumpbomb_DEATH]],
  selfDestructCountdown  = 0,
  script                 = [[jumpbomb.lua]],
  sightDistance          = 280,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 34,
  turnRate               = 2000,
  workerTime             = 0,
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[skuttle_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },
}

--------------------------------------------------------------------------------

local weaponDefs = {
  jumpbomb_DEATH = {
    areaOfEffect       = 180,
    craterBoost        = 4,
    craterMult         = 5,
    edgeEffectiveness  = 0.3,
    explosionGenerator = "custom:NUKE_150",
    explosionSpeed     = 10000,
    impulseBoost       = 0,
    impulseFactor      = 0.1,
    name               = "Explosion",
    soundHit           = "explosion/mini_nuke",
	
	customParams       = {
		burst = Shared.BURST_UNRELIABLE,

      lups_explodelife = 1.5,
	},
    damage = {
      default          = 8007.1,
    },
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------
return lowerkeys({ jumpbomb = unitDef })
