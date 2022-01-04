return { tele_beacon = {
  unitname                      = [[tele_beacon]],
  name                          = [[Lamp]],
  description                   = [[Teleport Bridge Entry Beacon, right click to teleport.]],
  buildCostMetal                = 100,
  builder                       = false,
  buildPic                      = [[tele_beacon.png]],
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
  maxDamage                     = 1500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[amphteleportbeacon.s3o]],
  reclaimable                   = false,
  script                        = [[tele_beacon.lua]],
  selfDestructAs                = [[TINY_BUILDINGEX]],
  selfDestructCountdown         = 5,
  sightDistance                 = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

} }
