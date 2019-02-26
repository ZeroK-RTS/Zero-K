unitDef = {
  unitname                      = [[factoryplane]],
  name                          = [[Airplane Plant]],
  description                   = [[Produces Airplanes, Builds at 10 m/s]],
  acceleration                  = 0,
  activateWhenBuilt             = false,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[factoryplane_aoplane.dds]],

  buildoptions                  = {
    [[planecon]],
    [[planefighter]],
    [[planeheavyfighter]],
	[[bomberprec]],
	[[bomberriot]],
    [[bomberdisarm]],
    [[bomberheavy]],
    [[planescout]],
  },

  buildPic                      = [[factoryplane.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[FLOAT UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pad_count = 1,
    landflystate   = [[0]],
    sortName = [[4]],
	modelradius    = [[51]], -- at 50 planefighter won't respond to Bugger Off calls
	midposoffset   = [[0 20 0]],
	nongroundfac = [[1]],
	default_spacing = 8,
	factorytab       = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  fireState                     = 0,
  footprintX                    = 8,
  footprintZ                    = 7,
  iconType                      = [[facair]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  moveState        				= 2,
  noAutoFire                    = false,
  objectName                    = [[CORAP.s3o]],
  script                        = [[factoryplane.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline						= 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[oooooooo oooooooo oooooooo occooooo occooooo oooooooo oooooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 6,
      object           = [[corap_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryplane = unitDef })
