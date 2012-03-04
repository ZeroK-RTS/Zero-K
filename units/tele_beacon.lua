unitDef = {
  unitname                      = [[tele_beacon]],
  name                          = [[Lighthouse]],
  description                   = [[Teleport Bridge Entry Beacon, right click to teleport.]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 800,
  buildCostMetal                = 800,
  builder                       = false,
  buildTime                     = 800,
  category                      = [[SINK UNARMED]],

  customParams                  = {
  	dontcount = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[BIG_UNIT]],
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
  script                		= [[tele_beacon.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[BIG_UNIT]],
  selfDestructCountdown			= 5,
  side                          = [[ARM]],
  sightDistance                 = 160,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

}

return lowerkeys({ tele_beacon = unitDef })
