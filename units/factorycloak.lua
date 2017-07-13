unitDef = {
  unitname                      = [[factorycloak]],
  name                          = [[Cloaky Bot Factory]],
  description                   = [[Produces Cloaky Robots, Builds at 10 m/s]],
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factorycloak_aoplane.dds]],

  buildoptions                  = {
    [[cloakcon]],
    [[cloakraid]],
    [[cloakheavyraid]],
    [[cloakskirm]],
    [[cloakriot]],
    [[cloakassault]],
    [[cloakarty]],
    [[cloaksnipe]],
    [[cloakaa]],
    [[cloakbomb]],
    [[cloakjammer]],
  },

  buildPic                      = [[factorycloak.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    sortName       = [[1]],
	default_spacing = 8,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[fackbot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[cremfactory.s3o]],
  script                        = [[factorycloak.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WhiteLight]],
    },

  },

  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = "ooooooo ooooooo ooooooo occccco occccco occccco occccco",

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[cremfactorywreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ factorycloak = unitDef })
