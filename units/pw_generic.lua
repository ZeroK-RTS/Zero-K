return { pw_generic = {
  unitname                      = [[pw_generic]],
  name                          = [[Generic Neutral Structure]],
  description                   = [[Blank]],
  activateWhenBuilt             = true,
  autoHeal                      = 5,
  buildCostMetal                = 1000,
  builder                       = false,
  canSelfDestruct               = false,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 100 130]],
  collisionVolumeType           = [[Box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    dontcount = [[1]],
    planetwars_structure = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 9,
  levelGround                   = false,
  iconType                      = [[mahlazer]],
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[pw_techlab.dae]],
  reclaimable                   = false,
  script                        = [[nullscriptWithCorpse.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  selfDestructCountdown         = 20,
  sightDistance                 = 273,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
    DEAD  = {
      blocking         = true,
      resurrectable    = 0,
      featureDead      = [[HEAP]],
      --footprintX       = 8, -- autoset by featuredefs_post
      --footprintZ       = 8,
      object           = [[pw_techlab_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      --footprintX       = 8,
      --footprintZ       = 8,
      object           = [[debris8x8a.s3o]],
    },
  },

} }
