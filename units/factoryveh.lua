unitDef = {
  unitname                      = [[factoryveh]],
  name                          = [[Light Vehicle Factory]],
  description                   = [[Produces Wheeled Vehicles, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 600,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 8,
  buildingGroundDecalSizeY      = 8,
  buildingGroundDecalType       = [[factoryveh_aoplane.dds]],

  buildoptions                  = {
    [[corned]],
    [[corfav]],
    [[corgator]],
    [[cormist]],
    [[corlevlr]],
    [[corraid]],
    [[capturecar]],
    [[corgarp]],
    [[armmerl]],
    [[vehaa]],
  },

  buildPic                      = [[factoryveh.png]],
  buildTime                     = 600,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
	description_de = [[Produziert Radfahrzeug, Baut mit 10 M/s]],
    helptext       = [[A traditional favourite, the Vehicle Plant is the ideal blitzkrieg fac with its fast, highly aggressive units. Those units that lack speed make up for it with copious firepower. Key Units: Dart, Scorcher, Ravager, Leveler, Slasher]],
	helptext_de    = [[Der Traditionalist unter den Fabriken. Die Vehicle Plant ist ideal für den Blitzkrieg, denn schnelle und hoch aggressive Einheiten werden hier gebaut. Diese Einheiten machen ihren Mangel an Geschwindigkeit mit reichlich Feuerkraft wieder wett. Wichtigste Einheiten: Dart, Scorcher, Ravager, Leveler, Slasher]],
    sortName       = [[2]],
  },

  energyMake                    = 0.3,
  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[facvehicle]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[corvp.s3o]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = "yyoooyy yoooooy ooooooo occccco occccco occccco occccco",

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[corvp_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryveh = unitDef })
