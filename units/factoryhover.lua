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
  corpse           = [[DEAD]],

  customParams     = {
    sortName = [[8]],
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
  objectName       = [[ARMFHP.s3o]],
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  turnRate         = 0,
  waterline        = 1,
  workerTime       = 10,
  yardMap          = [[xoooooox ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo xoccccox]],

  featureDefs      = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 7,
      object           = [[ARMFHP_DEAD.s3o]],
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
