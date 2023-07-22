return { tele_beacon = {
  name                          = [[Lamp]],
  description                   = [[Teleport Bridge Entry Beacon, right click to teleport.]],
  builder                       = false,
  buildPic                      = [[tele_beacon.png]],
  category                      = [[SINK UNARMED]],

  customParams                  = {
      dontcount = [[1]],
  },

  explodeAs                     = [[TINY_BUILDINGEX]],
  footprintX                    = 2,
  footprintZ                    = 2,
  health                        = 1500,
  levelGround                   = false,
  iconType                      = [[statictransport]],
  maxSlope                      = 18,
  metalCost                     = 100,
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
