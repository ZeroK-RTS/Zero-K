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
  collisionVolumeScales  = [[90 60 40]],
  collisionVolumeType    = [[box]],
  corpse           = [[DEAD]],

  customParams     = {
    helptext       = [[The Amphibious Operations Plant builds the slow but sturdy amphibious bots, providing an alternative approach to land/sea warfare. Units from this factory typically regenerate while submerged.]],
    aimposoffset   = [[0 0 -20]],
    midposoffset   = [[0 0 -20]],
    sortName = [[8]],
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
  noAutoFire       = false,
  objectName       = [[factory2.s3o]],
  script           = "factoryamph.lua",
  seismicSignature = 4,
  selfDestructAs   = [[LARGE_BUILDINGEX]],
  showNanoSpray    = false,
  sightDistance    = 273,
  workerTime       = 10,
  yardMap          = [[ooooooo ooooooo ooooooo occccco occccco occccco ccccccc]],

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
