unitDef = {
  unitname               = [[corsktl]],
  name                   = [[Skuttle]],
  description            = [[Cloaked Jumping Anti-Heavy Bomb]],
  acceleration           = 0.18,
  brakeRate              = 0.54,
  buildCostMetal         = 550,
  builder                = false,
  buildPic               = [[CORSKTL.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 5,
  cloakCostMoving        = 15,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    canjump          = 1,
    jump_range       = 400,
    jump_height      = 120,
    jump_speed       = 6,
    jump_reload      = 10,
    jump_from_midair = 0,

    description_fr = [[Bombe Rampante Avancée Camouflable]],
	description_de = [[Fortgeschrittene, verschleierbare Crawling Bombe]],
    helptext       = [[This slow-moving, expensive cloaked unit can jump on to enemy units and blast even a heavy tank straight to hell. Counter with swarms of cheap screening units. Be careful of its very small explosion radius when using it.]],
    helptext_fr    = [[Le Skuttle est une arme redoutable, il s'agit en fait d'un mine armée d'une tete nucléaire légcre, équipée d'un camouflage optique et d'un jetpack. Capable de se faufiler dans les endroits les plus inatendus, le souffle de son explosion est capable de faire des dégâts effroyables. Il se fera cependant détecter si il approche trop d'une cible ennemie. ]],
	helptext_de    = [[Der Skuttle wirft sich als Kamikazekrieger in die Schlacht und kann dir enorme Vorteile erarbeiten. Hochwirksam gegen schwere Ziele. Der Explosionsradius ist minimal, deshalb gilt: sorgfältig nutzen.]],
	aimposoffset   = [[0 0 0]],
	midposoffset   = [[0 0 0]],
	modelradius    = [[10]],
  },

  explodeAs              = [[CORSKTL_DEATH]],
  fireState              = 0,
  footprintX             = 1,
  footprintZ             = 1,
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
  movementClass          = [[KBOT1]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK TURRET SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[skuttle.s3o]],
  selfDestructAs         = [[CORSKTL_DEATH]],
  selfDestructCountdown  = 0,
  script                 = [[corsktl.lua]],
  sightDistance          = 280,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 26,
  turnRate               = 2000,
  workerTime             = 0,
  
  featureDefs            = {

    DEAD      = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[wreck2x2b.s3o]],
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
  CORSKTL_DEATH = {
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
      lups_explodelife = 1.5,
	},
    damage = {
      default          = 8007.1,
    },
  },
}
unitDef.weaponDefs = weaponDefs

--------------------------------------------------------------------------------
return lowerkeys({ corsktl = unitDef })
