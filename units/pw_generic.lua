unitDef = {
  unitname                      = [[pw_generic]],
  name                          = [[Generic Neutral Structure]],
  description                   = [[Blank]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  autoHeal                      = 40,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 1000,
  buildCostMetal                = 1000,
  builder                       = false,
  buildTime                     = 1000,
  category                      = [[SINK UNARMED]],
  collisionVolumeTest           = 1,
  --corpse                        = [[DEAD]],

  customParams                  = {
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 9,
  levelGround                   = false,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 336,
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[pw_techlab.obj]],
  script                		= [[nullscript.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],
  side                          = [[ARM]],
  sightDistance                 = 273,
  smoothAnim                    = true,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

}

return lowerkeys({ pw_generic = unitDef })
