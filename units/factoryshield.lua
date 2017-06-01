unitDef = {
  unitname                      = [[factoryshield]],
  name                          = [[Shield Bot Factory]],
  description                   = [[Produces Tough Robots, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 600,
  builder                       = true,
  collisionVolumeOffsets        = [[-4 0 -20]],
  collisionVolumeScales         = [[112 96 40]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[-4 0 4]],
  selectionVolumeScales         = [[112 16 96]],
  selectionVolumeType           = [[box]],
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 8,
  buildingGroundDecalType       = [[factoryshield_decal.png]],


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
    sortName       = [[1]],
	solid_factory = [[4]],
	default_spacing = 8,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
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
  objectName                    = [[factoryshield.s3o]],
  script                        = "factoryshield.lua",
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[ooooooo ooooooo ooooooo ccccccc ccccccc ccccccc]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      collisionVolumeOffsets        = [[-4 0 -20]],
      collisionVolumeScales         = [[112 96 40]],
      collisionVolumeType           = [[box]],
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 6,
      object           = [[factoryshield_dead.dae]],
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
