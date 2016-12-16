unitDef = {
  unitname                      = [[geo]],
  name                          = [[Geothermal Generator]],
  description                   = [[Medium Powerplant (+25)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 500,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[geo_aoplane.dds]],
  buildPic                      = [[GEO.png]],
  buildTime                     = 500,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[84 84 84]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],
  

  customParams                  = {
    description_de = [[Erzeugt Energie (25)]],
    helptext       = [[Geothermal plants are highly efficient energy sources that can only be built on geovents on the map. They explode quite violently when destroyed, so avoid placing anything directly adjacent.]],
    helptext_de    = [[Geothermische Anlagen sind hocheffiziente Energiequellen, die nur auf Thermalquellen auf der Karte gebaut werden können. Sie explodieren heftig, wenn sie zerstört werden. Von daher vermeide es, sie in unmittelbarer Nähe zu deiner Basis zu bauen.]],
    pylonrange = 150,
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -10 0]],
    modelradius    = [[42]],
	removewait     = 1,
    
    morphto = [[amgeo]],
    morphtime = [[90]],
	
	priority_misc = 1, -- Medium
  },

  energyMake                    = 25,
  energyUse                     = 0,
  explodeAs                     = [[ESTOR_BUILDING]],
  footprintX                    = 5,
  footprintZ                    = 5,
  iconType                      = [[energygeo]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 1750,
  maxSlope                      = 255,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[geo.dae]],
  script                        = [[geo.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ESTOR_BUILDING]],
  sightDistance                 = 273,
  turnRate                      = 0,
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

}

return lowerkeys({ geo = unitDef })
