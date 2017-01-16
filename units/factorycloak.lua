unitDef = {
  unitname                      = [[factorycloak]],
  name                          = [[Cloaky Bot Factory]],
  description                   = [[Produces Cloaky Robots, Builds at 10 m/s]],
  buildCostEnergy               = 600,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factorycloak_aoplane.dds]],

  buildoptions                  = {
    [[armrectr]],
    [[armpw]],
    [[spherepole]],
    [[armrock]],
    [[armwar]],
    [[armzeus]],
    [[armham]],
    [[armsnipe]],
    [[armjeth]],
    [[armtick]],
    [[spherecloaker]],
  },

  buildPic                      = [[factorycloak.png]],
  buildTime                     = 600,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Produziert Tarnroboter, Baut mit 10 M/s]],
    helptext       = [[Emphasizing guile over brute force, the Cloaky Bot Factory makes good use of stealth, mobility and EMP weapons to strike at the enemy's weak points. Key units:  Glaive, Rocko, Warrior, Zeus, Hammer]],
    helptext_de    = [[List statt pure Gewalt lautet hier das Motto. Die Cloaky Bot Plant ermöglicht die Nutzung von Tarnung, Mobilität und EMP-Waffen, um die feindlichen Schwachstellen empfindlich zu treffen. Wichtigste Einheiten: Glaive, Rocko, Warrior, Zeus, Hammer]],
    sortName       = [[1]],
  },

  energyMake                    = 0.3,
  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[fackbot]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxWaterDepth                 = 0,
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[cremfactory.s3o]],
  script                        = [[factorycloak.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:WhiteLight]],
    },

  },

  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = "ooooooo ooooooo ooooooo occccco occccco occccco occccco",

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[cremfactorywreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ factorycloak = unitDef })
