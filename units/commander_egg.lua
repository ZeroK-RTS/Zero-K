return { commander_egg = {
  name                = [[Commander Egg]],
  description         = [[Morphs into a Commander. EMP explosion on death.]],
  builder             = false,
  buildPic            = [[commander_egg.png]],
  canMove             = true,
  cantBeTransported   = false,
  category            = [[LAND UNARMED]],
  collisionVolumeOffsets  = [[0 0 0]],
  collisionVolumeScales   = [[36 45 36]],
  collisionVolumeType     = [[CylY]],
  selectionVolumeOffsets  = [[0 0 0]],
  selectionVolumeScales   = [[40 40 40]],
  selectionVolumeType     = [[CylY]],
  corpse              = [[DEAD]],

  customParams        = {
    instantselfd = [[1]],
    midposoffset = [[0 15 0]],
    modelradius = [[15]],
    stats_show_death_explosion = 1,

    morphto_1    = [[dynstrike0]],
    morphtime_1  = 60,
    morphcost_1  = 0,
    combatmorph_1 = [[0]],

    morphto_2    = [[dynassault0]],
    morphtime_2  = 60,
    morphcost_2  = 0,
    combatmorph_2 = [[0]],

    morphto_3    = [[dynrecon0]],
    morphtime_3  = 60,
    morphcost_3  = 0,
    combatmorph_3 = [[0]],

    morphto_4    = [[dynsupport0]],
    morphtime_4  = 60,
    morphcost_4  = 0,
    combatmorph_4 = [[0]],
  },

  explodeAs           = [[COMMANDER_EGG_EMP]],
  footprintX          = 3,
  footprintZ          = 3,
  health              = 1500,
  iconType            = [[commander_egg]],
  maxSlope            = 36,
  metalCost           = 600,
  movementClass       = [[KBOT3]],
  objectName          = [[commander_egg.s3o]],
  script              = [[commander_egg.lua]],
  selfDestructAs      = [[COMMANDER_EGG_EMP]],
  sightDistance        = 300,
  speed               = 40,

  weaponDefs          = {
    COMMANDER_EGG_EMP = {
      name                    = [[Egg Explosion]],
      areaOfEffect            = 280,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        burst = Shared.BURST_RELIABLE,
        light_color = [[1.35 1.35 0.36]],
        light_radius = 450,
        disarmDamageMult = 1,
        disarmTimer      = 25, -- seconds
        timeslow_damagefactor = 1,
        timeslow_overslow_frames = 12.5*30, -- Slow runs out at the same time as disarm.
        timeslow_onlyslow = 1,
      },

      damage                  = {
        default = 20000.6,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:SLOW_DISARM_EXPLOSION]],
      explosionSpeed          = 7.5,
      impulseBoost            = 0,
      impulseFactor           = 0,
      soundHit                = [[weapon/missile/slow_disarm_missile_hit]],
	  soundHitVolume          = 10,
    },
  },

  featureDefs         = {
    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },
  },
} }
