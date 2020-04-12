return { tele_beacon = {
  unitname                      = [[tele_beacon]],
  name                          = [[Lamp]],
  description                   = [[Teleport Bridge Entry Beacon, right click to teleport.]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 100,
  builder                       = false,
  category                      = [[SINK UNARMED]],

  customParams                  = {
      dontcount = [[1]],
  },

  energyUse                     = 0,
  explodeAs                     = [[TINY_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  levelGround                   = false,
  iconType                      = [[statictransport]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[amphteleportbeacon.s3o]],
  reclaimable                   = false,
  script                        = [[tele_beacon.lua]],
  selfDestructAs                = [[TINY_BUILDINGEX]],
  selfDestructCountdown         = 5,
  sightDistance                 = 0,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

} }
