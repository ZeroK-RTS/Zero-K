unitDef = {
  unitname                      = [[pw_generic]],
  name                          = [[Generic Neutral Structure]],
  description                   = [[Blank]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  autoHeal                      = 5,
  brakeRate                     = 0,
  buildCostMetal                = 1000,
  builder                       = false,
  canSelfDestruct				= false,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets 		= [[0 0 0]],
  collisionVolumeScales  		= [[120 100 130]],
  collisionVolumeType    		= [[Box]],
  --corpse                        = [[DEAD]],

  customParams                  = {
	helptext       = [[This structure offers benefits to the faction holding the planet. Only members of the attacking or defending factions can harm it.]],
  	dontcount = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 9,
  levelGround                   = true,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 5000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[pw_techlab.obj]],
  reclaimable					= false,
  script                		= [[nullscript.lua]],
  selfDestructAs                = [[ATOMIC_BLAST]],
  selfDestructCountdown			= 20,
  sightDistance                 = 0,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

}

return lowerkeys({ pw_generic = unitDef })
