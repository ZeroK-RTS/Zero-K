return { platecloak = {
  unitname                      = [[platecloak]],
  name                          = [[Cloakbot Plate]],
  description                   = [[Parallel Unit Production]],
  buildCostMetal                = Shared.FACTORY_PLATE_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[platecloak_aoplane.dds]],

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

  buildPic                      = [[platecloak.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 22 -6]],
  collisionVolumeScales         = [[44 50 44]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 15 20]],
  selectionVolumeScales         = [[64 50 80]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    sortName           = [[1]],
    default_spacing    = 4,
    midposoffset       = [[0 0 -20]],
    aimposoffset       = [[0 15 -20]],
    modelradius        = [[50]],
    solid_factory      = [[3]],
    unstick_help       = [[1]],
    selectionscalemult = 1,
    child_of_factory   = [[factorycloak]],
  },

  energyUse                     = 0,
  explodeAs                     = [[FAC_PLATEEX]],
  footprintX                    = 5,
  footprintZ                    = 6,
  iconType                      = [[padbot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = Shared.FACTORY_PLATE_HEALTH,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[plate_cloak.s3o]],
  script                        = [[platecloak.lua]],
  selfDestructAs                = [[FAC_PLATEEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WhiteLight]],
    },

  },

  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = "ooooo ooooo ooooo yyyyy yyyyy yyyyy",

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[plate_cloak_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
