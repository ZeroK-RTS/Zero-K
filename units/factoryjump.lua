unitDef = {
  unitname                      = [[factoryjump]],
  name                          = [[Jump/Specialist Plant]],
  description                   = [[Produces Jumpjets and Special Walkers, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factoryjump_aoplane.dds]],

  buildoptions                  = {
    [[jumpcon]],
    [[jumpscout]],
    [[jumpraid]],
	[[jumpblackhole]],
	[[jumpskirm]],
    [[jumpassault]],
    [[jumpsumo]],
	[[jumparty]],
    [[jumpaa]],
	[[jumpbomb]],
  },

  buildPic                      = [[factoryjump.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[104 70 40]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 0 30]],
  selectionVolumeScales         = [[104 70 100]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset   = [[0 0 -28]],
    midposoffset   = [[0 0 -28]],
    canjump  = [[1]],
	no_jump_handling = [[1]],
    sortName = [[5]],
	modelradius    = [[38]],
	solid_factory = [[3]],
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[facjumpjet]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[factoryjump.s3o]],
  script						= [[factoryjump.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[ooooooo ooooooo ooooooo ccccccc ccccccc ccccccc ccccccc]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[factoryjump_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryjump = unitDef })
