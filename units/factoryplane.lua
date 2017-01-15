unitDef = {
  unitname                      = [[factoryplane]],
  name                          = [[Airplane Plant]],
  description                   = [[Produces Airplanes, Builds at 10 m/s]],
  acceleration                  = 0,
  activateWhenBuilt             = false,
  brakeRate                     = 0,
  buildCostEnergy               = 600,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factoryplane_aoplane.dds]],

  buildoptions                  = {
    [[armca]],
    [[fighter]],
    [[corvamp]],
	[[corshad]],
	[[corhurc2]],
    [[armstiletto_laser]],
    [[armcybr]],
    [[corawac]],
  },

  buildPic                      = [[factoryplane.png]],
  buildTime                     = 600,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[FLOAT UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pad_count = 1,
    landflystate   = [[0]],
    description_de = [[Produziert Flugzeuge, Baut mit 10 M/s]],
    helptext       = [[The Airplane Plant offers a variety of fixed-wing aircraft to suit your needs. Choose between multirole fighters that can double as light attackers or specialized interceptors, and between precision bombers for taking down specific targets or their saturation counterparts for destroying swarms. The plant also comes bundled with one rearm pad.]],
	helptext_de    = [[Das Airplane Plant ermöglicht den Bau vielfältiger Starrflügelflugzeuge, um deine Bedürfnisse zu stillen. Wähle zwischen Allzweckjägern, die sowohl leichte Attacken fliegen können, als auch als Abfangjäger fungieren, und präzisen Bombern, um spezielle Ziele zu vernichten. Es befüllt außerdem die Bomber.]],
    sortName = [[4]],
	modelradius    = [[50]],
	midposoffset   = [[0 20 0]],
  },

  energyMake                    = 0.3,
  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  fireState                     = 0,
  footprintX                    = 8,
  footprintZ                    = 6,
  iconType                      = [[facair]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  moveState        				= 2,
  noAutoFire                    = false,
  objectName                    = [[CORAP.s3o]],
  script                        = [[factoryplane.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  waterline						= 0,
  workerTime                    = 10,
  yardMap                       = [[oooooooo oooooooo oooooooo occooooo occooooo oooooooo]],

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
