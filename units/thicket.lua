unitDef = {
  unitname                      = [[thicket]],
  name                          = [[Thicket]],
  description                   = [[Barricade]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[thicket_aoplane.dds]],
  buildPic                      = [[thicket.png]],
  buildTime                     = 20,
  category                      = [[SINK UNARMED]],

  customParams                  = {
  },

  corpse                        = [[DEAD]],
  footprintX                    = 2,
  footprintZ                    = 2,
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  isFeature                     = true,
  levelGround                   = false,
  maxDamage                     = 1500,
  maxSlope                      = 255,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  objectName                    = [[Tyranid2.s3o]],
  sightDistance                 = 1,
  turnRate                      = 0,
  upright                       = false,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ff ff]],

  featureDefs                   = {

    DEAD = {
      description      = [[Embedded Thicket]],
      blocking         = true,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[Tyranid2.s3o]],
    },

  },

}

return lowerkeys({ thicket = unitDef })
