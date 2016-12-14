unitDef = {
  unitname                      = [[armwin]],
  name                          = [[Wind/Tidal Generator]],
  description                   = [[Produces Energy]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 35,
  buildCostMetal                = 35,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armwin_aoplane.dds]],
  buildPic                      = [[armwin.png]],
  buildTime                     = 35,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[30 60 30]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Produziert Energie (variabel)]],
    description_fr = [[Produit de l'énergie]],
    helptext       = [[Wind generators produce a variable amount of energy, depending on altitude and wind speed. They are extremely fragile and chain explode when bunched, so consider their placement carefully. When placed in water, they become somewhat more sturdy tidal generators with a good, constant output.]],
    helptext_de    = [[Windräder produzieren eine variable Menge an Energie, je nach Höhenlage und Windgeschwindigkeit. Sie sind extrem verletzlich und explodieren in einer Kettenreaktion, sobald sie zerstört werden. Platziere sie also mit Bedacht.]],
    helptext_fr    = [[Sur terre, l'éolienne produit de l'énergie en quantité variable, selon l'altitude et la vitesse du vent. Elles sont très fragiles et explosent à la chaine quand elles sont trop proches l'une de l'autre. Dans l'eau, la génératrice marémotrice est plus résistante et produit une énérgie constante.]],
    pylonrange     = 60,
    windgen        = true,
    modelradius    = [[15]],
	removewait     = 1,
  },

  energyMake                    = 1.2,
  energyUse                     = 0,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[energywind]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  losEmitHeight                 = 30,
  maxDamage                     = 130,
  maxSlope                      = 255,
  minCloakDistance              = 150,
  objectName                    = [[arm_wind_generator.s3o]],
  script                        = [[armwin.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  windGenerator                 = 0,
  yardMap                       = [[ooooooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[arm_wind_generator_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

    DEADWATER = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[arm_wind_generator_dead_water.s3o]],
	  customparams = {
		health_override = 400,
	  },
    }

  },

}

return lowerkeys({ armwin = unitDef })
