return { factorycloak = {
  unitname                      = [[factorycloak]],
  name                          = [[Cloakbot Factory]],
  description                   = [[Produces Cloaked, Mobile Robots, Builds at 10 m/s]],
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 13,
  buildingGroundDecalSizeY      = 13,
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
    sortName        = [[1]],
    default_spacing = 8,
    midposoffset    = [[0 0 -24]],
    solid_factory   = [[7]],
    unstick_help    = [[1]],
    selectionscalemult = 1,
    factorytab       = 1,
    shared_energy_gen = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 10,
  iconType                      = [[fackbot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState                     = 1,
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
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = "ooooooo ooooooo ooooooo occccco occccco occccco occccco yyyyyyy yyyyyyy yyyyyyy",

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

} }
