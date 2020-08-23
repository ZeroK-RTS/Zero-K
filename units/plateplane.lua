return { plateplane = {
  unitname                      = [[plateplane]],
  name                          = [[Airplane Plate]],
  description                   = [[Augments Production]],
  acceleration                  = 0,
  activateWhenBuilt             = false,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_PLATE_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[pad_decal_square.dds]],

  buildoptions                  = {
    [[planecon]],
    [[planefighter]],
    [[planeheavyfighter]],
    [[bomberprec]],
    [[bomberriot]],
    [[bomberdisarm]],
    [[bomberheavy]],
    [[planescout]],
    [[planelightscout]],
  },

  buildPic                      = [[plateplane.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[FLOAT UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    landflystate       = [[0]],
    sortName           = [[4]],
    modelradius        = [[51]], -- at 50 planefighter won't respond to Bugger Off calls
    midposoffset       = [[0 20 0]],
    nongroundfac       = [[1]],
    default_spacing    = 4,
    child_of_factory   = [[factoryplane]],
  },

  energyUse                     = 0,
  explodeAs                     = [[FAC_PLATEEX]],
  fireState                     = 0,
  footprintX                    = 6,
  footprintZ                    = 7,
  iconType                      = [[padair]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = Shared.FACTORY_PLATE_HEALTH,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  moveState                     = 2,
  noAutoFire                    = false,
  objectName                    = [[pad_plane.dae]],
  script                        = [[factoryplane.lua]],
  selfDestructAs                = [[FAC_PLATEEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline                     = 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[oooooo oooooo oooooo oooooo oooooo oooooo oooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 6,
      object           = [[corap_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
