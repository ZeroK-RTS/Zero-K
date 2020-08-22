return { plateship = {
  unitname                      = [[plateship]],
  name                          = [[Naval Plate]],
  description                   = [[Augments Production]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_PLATE_COST,
  builder                       = true,

  buildoptions                  = {
    [[shipcon]],
    [[shipscout]],
    [[shiptorpraider]],
    [[subraider]],
    [[shipriot]],
    [[shipskirm]],
    [[shipassault]],
    [[shiparty]],
    [[shipaa]],
  },

  buildPic                      = [[plateship.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[UNARMED FLOAT]],
  collisionVolumeOffsets        = [[-22 5 0]],
  collisionVolumeScales         = [[48 48 184]],
  collisionVolumeType           = [[cylZ]],
  selectionVolumeOffsets        = [[18 0 0]],
  selectionVolumeScales         = [[130 50 184]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    sortName               = [[7]],
    unstick_help           = 1,
    aimposoffset           = [[60 0 -15]],
    midposoffset           = [[0 0 -15]],
    solid_factory          = [[2]],
    modelradius            = [[100]],
    solid_factory_rotation = [[1]], -- 90 degrees counter clockwise
    default_spacing        = 4,
    selectionscalemult     = 1,
    cus_noflashlight       = 1,
    child_of_factory       = [[factoryship]],
  },

  energyUse                     = 0,
  explodeAs                     = [[FAC_PLATEEX]],
  footprintX                    = 6,
  footprintZ                    = 8,
  iconType                      = [[padship]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = Shared.FACTORY_PLATE_HEALTH * 3 / 2,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  minWaterDepth                 = 15,
  moveState                     = 1,
  objectName                    = [[pad_ship.dae]],
  script                        = [[plateship.lua]],
  selfDestructAs                = [[FAC_PLATEEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  waterline                     = 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[ooyyyy ooyyyy ooyyyy ooyyyy ooyyyy ooyyyy ooyyyy ooyyyy]],

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[wreck4x4a.s3o]],
    },



    HEAP  = {
      blocking         = false,
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
