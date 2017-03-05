unitDef = {
  unitname                      = [[armnanotc]],
  name                          = [[Caretaker]],
  description                   = [[Static Constructor, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 1.5,
  buildCostEnergy               = 220,
  buildCostMetal                = 220,
  buildDistance                 = 500,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armnanotc_aoplane.dds]],
  buildPic                      = [[armnanotc.png]],
  buildTime                     = 220,
  canGuard                      = true,
  canMove                       = false,
  canPatrol                     = true,
  canStop                       = true,
  cantBeTransported             = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[48 48 48]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Nanoturm, Baut mit 10 M/s]],
    helptext       = [[The most cost-effective source of buildpower, the Caretaker is ideal for increasing the output of factories or automatically repairing nearby defenses. It cannot start any construction projects itself, however.]],
    helptext_de    = [[Die effektivste Quelle an Baukraft: der Caretake ist ideal, um die Produktionsrate von Fabriken zu erhöhen oder nahegelegene Verteidigungsanlagen zu reparieren. Der Caretaker kann aber selbst keine neuen Bauten beginnen.]],

    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -4 0]],
    modelradius    = [[24]],
  },

  explodeAs                     = [[NANOBOOM2]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticbuilder]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 500,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  movementClass                 = [[KBOT1]],
  objectName                    = [[armsenan.s3o]],
  script                        = [[armnanotc.lua]],
  selfDestructAs                = [[NANOBOOM2]],
  showNanoSpray                 = false,
  sightDistance                 = 380,
  terraformSpeed                = 600,
  turnRate                      = 1,
  upright                       = true,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,

  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ armnanotc = unitDef })
