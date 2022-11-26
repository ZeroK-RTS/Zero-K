return { factoryshield = {
  unitname                      = [[factoryshield]],
  name                          = [[Shieldbot Factory]],
  description                   = [[Produces Tough, Shielded Robots]],
  buildCostMetal                = Shared.FACTORY_COST,
  buildDistance                 = Shared.FACTORY_PLATE_RANGE,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 12,
  buildingGroundDecalSizeY      = 12,
  buildingGroundDecalType       = [[factoryshield_aoplane.dds]],

  buildoptions                  = {
    [[shieldcon]],
    [[shieldscout]],
    [[shieldraid]],
    [[shieldskirm]],
    [[shieldassault]],
    [[shieldriot]],
    [[shieldfelon]],
    [[shieldarty]],
    [[shieldaa]],
    [[shieldbomb]],
    [[shieldshield]],
  },

  buildPic                      = [[factoryshield.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    ploppable = 1,
    sortName            = [[1]],
    midposoffset        = [[0 0 -24]],
    solid_factory       = [[6]],
    unstick_help        = [[1]],
    unstick_help_buffer = 0.2,
    factorytab          = 1,
    shared_energy_gen   = 1,
    parent_of_plate     = [[plateshield]],
    buggeroff_offset    = 28,

    outline_x = 250,
    outline_y = 250,
    outline_yoff = 5,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 9,
  iconType                      = [[facwalker]],
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[factory.s3o]],
  script                        = "factoryshield.lua",
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[ooooooo occccco occccco occccco occccco occccco yyyyyyy yyyyyyy yyyyyyy]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[factory_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
