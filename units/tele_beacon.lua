unitDef = {
  unitname                      = [[tele_beacon]],
  name                          = [[Lighthouse]],
  description                   = [[Teleport Bridge Entry Beacon]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildTime                     = 0,
  canSelfDestruct				= false,
  category                      = [[SINK UNARMED]],

  customParams                  = {
  	dontcount = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[ESTOR_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  levelGround                   = false,
  iconType                      = [[statictransport]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 336,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  modelCenterOffsets			= [[0 0 0]],
  noAutoFire                    = false,
  objectName                    = [[amphteleportbeacon.s3o]],
  power							= 100,
  reclaimable					= false,
  script                		= [[nullscript.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ESTOR_BUILDINGEX]],
  selfDestructCountdown			= 5,
  side                          = [[ARM]],
  sightDistance                 = 0,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

}

return lowerkeys({ tele_beacon = unitDef })
