unitDef = {
  unitname                      = [[factoryshield]],
  name                          = [[Shield Bot Factory]],
  description                   = [[Produces Tough Robots, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
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
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[88 70 54]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 0 16]],
  selectionVolumeScales         = [[88 70 88]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    sortName       = [[1]],
    aimposoffset   = [[0 0 -16]],
    midposoffset   = [[0 0 -16]],
	solid_factory = [[3]],
	default_spacing = 8,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 6,
  footprintZ                    = 6,
  iconType                      = [[facwalker]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[factory.s3o]],
  script                        = "factoryshield.lua",
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[oooooo oooooo oooooo cccccc cccccc cccccc]],

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

}

return lowerkeys({ factoryshield = unitDef })
