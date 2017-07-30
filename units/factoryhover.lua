unitDef = {
  unitname         = [[factoryhover]],
  name             = [[Hovercraft Platform]],
  description      = [[Produces Hovercraft, Builds at 10 m/s]],
  acceleration     = 0,
  brakeRate        = 0,
  buildCostMetal   = 600,
  builder          = true,

  buildoptions     = {
    [[hovercon]],
    [[hoverraid]],
    [[hoverskirm]],
    [[hoverassault]],
	[[hoverdepthcharge]],
	[[hoverriot]],
    [[hoverarty]],
    [[hoveraa]],
  },

  buildPic         = [[factoryhover.png]],
  canMove          = true,
  canPatrol        = true,
  category         = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[0 3 -37]],
  collisionVolumeScales  = [[120 20 48]],
  collisionVolumeType    = [[Box]],
  
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[110 4 110]],
  selectionVolumeType    = [[Box]],
  corpse           = [[DEAD]],

  customParams     = {
    sortName = [[8]],
    solid_factory = 3,
  	aimposoffset   = [[0 0 0]],
	  midposoffset   = [[0 -25 0]],
	  modelradius    = [[60]],
	  default_spacing = 8,
  },

  energyUse        = 0,
  explodeAs        = [[LARGE_BUILDINGEX]],
  footprintX       = 8,
  footprintZ       = 8,
  iconType         = [[fachover]],
  idleAutoHeal     = 5,
  idleTime         = 1800,
  levelGround      = false,
  maxDamage        = 4000,
  maxSlope         = 15,
  maxVelocity      = 0,
  minCloakDistance = 150,
  moveState        = 1,
  noAutoFire       = false,
  objectName       = [[factoryhover.s3o]],
  script           = [[factoryhover.lua]],
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  turnRate         = 0,
  waterline        = 1,
  workerTime       = 10,
  yardMap          = [[oooooooo oooooooo oooooooo cccccccc cccccccc cccccccc cccccccc cccccccc]],

  featureDefs      = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 8,
      collisionVolumeOffsets = [[0 3 -37]],
      collisionVolumeScales  = [[120 20 48]],
      collisionVolumeType    = [[Box]],
      object           = [[factoryhover_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 8,
      footprintZ       = 7,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryhover = unitDef })
