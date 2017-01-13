unitDef = {
  unitname                      = [[factorygunship]],
  name                          = [[Gunship Plant]],
  description                   = [[Produces Gunships, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 600,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factorygunship_aoplane.dds]],

  buildoptions                  = {
    [[gunshipcon]],
    [[blastwing]],
    [[bladew]],
    [[armkam]],
    [[gunshipsupport]],
    [[armbrawl]],
    [[blackdawn]],
    [[corcrw]],
	[[gunshipaa]],
    [[corvalk]],
    [[corbtrans]],
  },

  buildPic                      = [[factorygunship.png]],
  buildTime                     = 600,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[86 86 86]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    landflystate   = [[0]],
	description_de = [[Produziert Kampfhubschrauber, Baut mit 10 M/s]],
	helptext       = [[The Gunship Plant is designed for close air support. It includes a selection of transports for hauling land units around, and combat gunships which can perform a variety of offensive or defensive roles.]],
    helptext_de    = [[Kampfhubschrauber bieten aufgrund ihrer Beweglichkeit eine enorme Bandbreite an Einsetzbarkeit.]],
    sortName = [[3]],
	modelradius    = [[43]],
  },

  energyMake                    = 0.3,
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
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[CORPLAS.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline						= 0,
  workerTime                    = 10,
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
