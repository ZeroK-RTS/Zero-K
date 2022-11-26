return { factorycloak = {
  unitname                      = [[factorycloak]],
  name                          = [[Cloakbot Factory]],
  description                   = [[Produces Cloaked, Mobile Robots]],
  buildCostMetal                = Shared.FACTORY_COST,
  buildDistance                 = Shared.FACTORY_PLATE_RANGE,
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
    ploppable = 1,
    sortName            = [[1]],
    default_spacing     = 8,
    midposoffset        = [[0 0 -24]],
    solid_factory       = [[7]],
    unstick_help        = [[1]],
    unstick_help_buffer = 0.3,
    selectionscalemult  = 1,
    factorytab          = 1,
    shared_energy_gen   = 1,
    parent_of_plate     = [[platecloak]],
    buggeroff_offset    = 35,

    outline_x = 250,
    outline_y = 250,
    outline_yoff = 5,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 10,
  iconType                      = [[fackbot]],
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
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
