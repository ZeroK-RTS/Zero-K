unitDef = {
  unitname                      = [[missilesilo]],
  name                          = [[Missile Silo]],
  description                   = [[Produces Missiles, Builds at 10 m/s]],
  buildCostEnergy               = 1200,
  buildCostMetal                = 1200,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  buildingGroundDecalSizeY      = 6,
  buildingGroundDecalType       = [[missilesilo_aoplane.dds]],

  buildoptions                  = {
    [[tacnuke]],
    [[seismic]],
    [[empmissile]],
    [[napalmmissile]],
  },

  buildPic                      = [[missilesilo.png]],
  buildTime                     = 1200,
  canFight                      = false,
  canMove                       = false,
  canPatrol                     = false,
  canstop                       = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeTest           = 1,
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Produziert Raketen, Baut mit 10 M/s]],
    description_pl = [[Buduje rakiety taktyczne, moc 10 m/s]],
    helptext       = [[The Missile Silo constructs and holds up to four different cruise missiles, each with a unique warhead. It offers excellent standoff strike capability for offensive and defensive purposes.]],
    helptext_de    = [[Das Raketensilo erzeugt und lagert bis zu vier verschiedene Marschflugkörper, jede mit einem einzigartigen Sprengkopf. Das Silo bietet hervorragende Schlagkraft in Pattsituationen, sowohl für offensive, als auch defensive Zwecke.]],
    helptext_pl    = [[Silos Rakietowy buduje i przechowuje do czterech jednorazowych rakiet taktycznych dalekiego zasiegu. Silos oferuje kilka roznych glowic, co daje swietne mozliwosci zarowno defensywne, jak i ofensywne.]],
  },

  energyMake                    = 0.3,
  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 6,
  footprintZ                    = 6,
  iconType                      = [[cruisemissile]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  objectName                    = [[missilesilo.s3o]],
  script                        = [[missilesilo.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[oooooo occcco occcco occcco occcco oooooo]],

  featureDefs                   = {

    DEAD = {
      description      = [[Wreckage - Missile Silo]],
      blocking         = true,
      damage           = 4000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 6
      footprintZ       = 6,
      metal            = 480,
      object           = [[missilesilo_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 480,
    },

    HEAP = {
      description      = [[Debris - Missile Silo]],
      blocking         = false,
      damage           = 4000,
      energy           = 0,
      footprintX       = 6,
      footprintZ       = 6,
      metal            = 240,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 240,
    },

  },

}

return lowerkeys({ missilesilo = unitDef })
