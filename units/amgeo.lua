unitDef = {
  unitname                      = [[amgeo]],
  name                          = [[Advanced Geothermal]],
  description                   = [[Large Powerplant (+100) - HAZARDOUS]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 1500,
  buildCostMetal                = 1500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[amgeo_aoplane.dds]],
  buildPic                      = [[AMGEO.png]],
  buildTime                     = 1500,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Erzeugt Energie (100) - RISKANT]],
    description_fr = [[Produit de l'énergie (100) - DANGEREUX]],
    helptext       = [[The Advanced Geothermal Powerplant produces a massive amount of energy. It requires protection, though, as destroying it results in a devastating explosion.]],
    helptext_de    = [[Das Verbessert Geothermisches Kraftwerk erzeugt eine große Menge an Energie, doch stellt es auch ein lohnendes Angriffsziel dar.]],
    helptext_fr    = [[La centrale géothermique superieure produit une quantité important d'énergie. Son explosion peut être catastrophique selon son emplacement.]],
    pylonrange     = 150,
	removewait     = 1,
  },

  energyMake                    = 100,
  energyUse                     = 0,
  explodeAs                     = [[NUCLEAR_MISSILE]],
  footprintX                    = 5,
  footprintZ                    = 5,
  iconType                      = [[energymohogeo]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 3250,
  maxSlope                      = 255,
  minCloakDistance              = 150,
  objectName                    = [[amgeo.s3o]],
  script                        = [[amgeo.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[NUCLEAR_MISSILE]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooo ogggo ogggo ogggo ooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[amgeo_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ amgeo = unitDef })
