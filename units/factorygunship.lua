unitDef = {
  unitname                      = [[factorygunship]],
  name                          = [[Gunship Plant]],
  description                   = [[Produces Gunships, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[factorygunship_aoplane.dds]],

  buildoptions                  = {
    [[gunshipcon]],
    [[gunshipbomb]],
    [[gunshipemp]],
    [[gunshipraid]],
    [[gunshipskirm]],
    [[gunshipheavyskirm]],
    [[gunshipassault]],
    [[gunshipkrow]],
	[[gunshipaa]],
    [[gunshiptrans]],
    [[gunshipheavytrans]],
  },

  buildPic                      = [[factorygunship.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[86 86 86]],
  collisionVolumeType           = [[ellipsoid]],
  selectionVolumeOffsets        = [[0 10 0]],
  selectionVolumeScales         = [[104 60 96]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    landflystate   = [[0]],
    sortName = [[3]],
	modelradius    = [[43]],
	nongroundfac = [[1]],
	default_spacing = 8,
    selectionscalemult = 1,
	factorytab       = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[facgunship]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[CORPLAS.s3o]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline						= 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[yyoooyy yoooooy ooooooo ooooooo ooooooo yoooooy yyoooyy]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 6,
      object           = [[corplas_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factorygunship = unitDef })
