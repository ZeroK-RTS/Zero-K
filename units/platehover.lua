return { platehover = {
  unitname                      = [[platehover]],
  name                          = [[Hovercraft Plate]],
  description                   = [[Parallel Unit Production]],
  buildCostMetal                = Shared.FACTORY_PLATE_COST,
  buildDistance                 = Shared.FACTORY_PLATE_RANGE,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[platehover_aoplane.dds]],

  buildoptions     = {
    [[hovercon]],
    [[hoverraid]],
    [[hoverheavyraid]],
    [[hoverskirm]],
    [[hoverassault]],
    [[hoverdepthcharge]],
    [[hoverriot]],
    [[hoverarty]],
    [[hoveraa]],
  },

  buildPic         = [[platehover.png]],
  canMove          = true,
  canPatrol        = true,
  category         = [[UNARMED FLOAT]],
  collisionVolumeOffsets        = [[0 5 1]],
  collisionVolumeScales         = [[64 24 32]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 15 30]],
  selectionVolumeScales         = [[84 40 84]],
  selectionVolumeType           = [[box]],
  corpse           = [[DEAD]],

  customParams     = {
    sortName           = [[8]],
    modelradius        = [[50]],
    default_spacing    = 4,
    aimposoffset       = [[0 5 -30]],
    midposoffset       = [[0 0 -30]],
    solid_factory      = [[2]],
    unstick_help       = [[1]],
    selectionscalemult = 1,
    child_of_factory   = [[factoryhover]],
    buggeroff_offset   = 40,

    outline_x = 165,
    outline_y = 165,
    outline_yoff = 27.5,
  },

  energyUse        = 0,
  explodeAs        = [[FAC_PLATEEX]],
  footprintX       = 6,
  footprintZ       = 6,
  iconType         = [[padhover]],
  levelGround      = false,
  maxDamage        = Shared.FACTORY_PLATE_HEALTH,
  maxSlope         = 15,
  maxVelocity      = 0,
  moveState        = 1,
  noAutoFire       = false,
  objectName       = [[plate_hover.s3o]],
  script           = [[platehover.lua]],
  selfDestructAs   = [[FAC_PLATEEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  useBuildingGroundDecal = true,
  waterline        = 1,
  workerTime       = Shared.FACTORY_BUILDPOWER,
  yardMap          = [[oooooo oooooo yyyyyy yyyyyy yyyyyy yyyyyy]],

  featureDefs      = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[plate_hover_dead.s3o]],

    },


    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
