unitDef = {
  unitname                      = [[factorytank]],
  name                          = [[Heavy Tank Factory]],
  description                   = [[Produces Heavy and Specialized Vehicles, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 8,
  buildingGroundDecalType       = [[factorytank_aoplane.dds]],

  buildoptions                  = {
    [[tankcon]],
    [[tankraid]],
	[[tankheavyraid]],
    [[tankriot]],
	[[tankassault]],
    [[tankheavyassault]],
	[[tankarty]],
	[[tankheavyarty]],
    [[tankaa]],
  },

  buildPic                      = [[factorytank.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 16 -30]],
  collisionVolumeScales         = [[150 32 70]],
  collisionVolumeType           = [[Box]],
  
  selectionVolumeOffsets        = [[0 0 0]],
  selectionVolumeScales         = [[150 4 110]],
  selectionVolumeType           = [[Box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Produziert schwere und speziallisierte Fahrzeuge, Baut mit 10 M/s]],
    helptext       = [[The Heavy Tank Factory is the ultimate in brute force methods - nothing gets the job done quite like a sustained artillery barrage followed by a decisive push with the largest tanks in the field. Key units: Pillager, Reaper, Banisher, Goliath]],
	helptext_de    = [[Die Heavy Tank Factory ist das Ultimum für brachiale Gewalt. Nicht erledigt den Auftrag zu gut, wie ein anhaltendes Artilleriefeuer, gefolgt von einem entscheidenen Vorstoß mit den größten Panzern auf dem Feld. Wichtigste Einheiten: Pillager, Reaper, Banisher, Goliath]],
    sortName = [[6]],
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 10,
  footprintZ                    = 8,
  iconType                      = [[factank]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[factorytank.s3o]],
  script                        = [[factorytank.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = "oooooooooo oooooooooo oooooooooo ooccccccoo ooccccccoo cccccccccc cccccccccc cccccccccc",

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      collisionVolumeOffsets        = [[0 16 -30]],
      collisionVolumeScales         = [[150 32 70]],
      collisionVolumeType           = [[Box]],
      featureDead      = [[HEAP]],
      footprintX       = 10,
      footprintZ       = 8,
      object           = [[factorytank_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ factorytank = unitDef })
