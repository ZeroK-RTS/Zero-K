return { energygeo = {
  unitname                      = [[energygeo]],
  name                          = [[Geothermal Generator]],
  description                   = [[Medium Powerplant (+25)]],
  activateWhenBuilt             = true,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[energygeo_aoplane.dds]],
  buildPic                      = [[energygeo.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[84 84 84]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],
  

  customParams                  = {
    pylonrange = 150,
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -10 0]],
    modelradius    = [[42]],
    removewait     = 1,
    selectionscalemult = 1.15,
    
    morphto = [[energyheavygeo]],
    morphtime = [[90]],
    
    priority_misc = 1, -- Medium
    default_spacing = 0,
  },

  energyMake                    = 25,
  energyUse                     = 0,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 5,
  footprintZ                    = 5,
  iconType                      = [[energygeo]],
  maxDamage                     = 1750,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[geo.dae]],
  script                        = [[energygeo.lua]],
  selfDestructAs                = [[ESTOR_BUILDING]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooo ogggo ogggo ogggo ooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[geo_dead.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
