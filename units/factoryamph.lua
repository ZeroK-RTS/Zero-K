unitDef = {
  unitname         = [[factoryamph]],
  name             = [[Amphibious Bot Plant]],
  description      = [[Produces Amphibious Bots, Builds at 10 m/s]],
  buildCostEnergy  = 600,
  buildCostMetal   = 600,
  builder          = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factoryjump_aoplane.dds]],  

  buildoptions     = {
    [[amphcon]],
    [[amphraider3]],
    [[amphraider2]],
    [[amphfloater]],
    [[amphriot]],	
    [[amphassault]],
    [[amphaa]],
    [[amphtele]],
  },

  buildPic         = [[factoryamph.png]],
  buildTime        = 600,
  canAttack        = true,
  canMove          = true,
  canPatrol        = true,
  canstop          = true,
  category         = [[UNARMED SINK]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[104 70 36]],
  collisionVolumeType    = [[box]],
  selectionVolumeOffsets = [[0 0 30]],
  selectionVolumeScales  = [[104 70 96]],
  selectionVolumeType    = [[box]],
  corpse           = [[DEAD]],

  customParams     = {
    helptext       = [[The Amphibious Operations Plant builds the slow but sturdy amphibious bots, providing an alternative approach to land/sea warfare. Units from this factory typically regenerate while submerged.]],
	modelradius    = [[38]],
    aimposoffset   = [[0 0 -26]],
    midposoffset   = [[0 0 -26]],
    sortName = [[8]],
	solid_factory = [[3]],
  },

  energyMake       = 0.3,
  energyUse        = 0,
  explodeAs        = [[LARGE_BUILDINGEX]],
  footprintX       = 7,
  footprintZ       = 7,
  iconType         = [[facamph]],
  idleAutoHeal     = 5,
  idleTime         = 1800,
  maxDamage        = 4000,
  maxSlope         = 15,
  metalMake        = 0.3,
  minCloakDistance = 150,
  moveState        = 1,
  noAutoFire       = false,
  objectName       = [[factory2.s3o]],
  script           = "factoryamph.lua",
  seismicSignature = 4,
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  workerTime       = 10,
  yardMap          = [[ooooooo ooooooo ooooooo ccccccc ccccccc ccccccc ccccccc]],

  featureDefs      = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[FACTORY2_DEAD.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryamph = unitDef })
