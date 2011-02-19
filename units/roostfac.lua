unitDef = {
  unitname                      = [[roostfac]],
  name                          = [[Roost]],
  description                   = [[Spawns Big Chickens]],
  acceleration                  = 0,
  bmcode                        = [[0]],
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 0,
  buildCostMetal                = 0,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[roostfac_aoplane.dds]],

  buildoptions                  = {
    [[chicken_drone]],
    [[chickenf]],
    [[chicken_blimpy]],
    [[chicken_listener]],
    [[chickena]],
    [[chickenc]],
    [[chickenblobber]],
    [[chicken_spidermonkey]],
    [[chicken_tiamat]],
    [[chicken_dragon]],
  },

  buildPic                      = [[roostfac.png]],
  buildTime                     = 200,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  commander                     = false,

  customParams                  = {
    description_de = [[Erzeugt groﬂe Chicken]],
	helptext_de    = [[M‰chtige Kreaturen werden hier erzeugt und auf die Menschheit losgelassen.]],
    chickenFac = [[true]],
  },

  energyMake                    = 1,
  energyStorage                 = 50,
  energyUse                     = 0,
  explodeAs                     = [[NOWEAPON]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[factory]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 380,
  maxDamage                     = 8000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  metalMake                     = 1.05,
  metalStorage                  = 50,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[roostfac_big]],
  power                         = 1000,
  seismicSignature              = 4,
  selfDestructAs                = [[NOWEAPON]],

  sfxtypes                      = {

    explosiongenerators = {
      [[custom:dirt2]],
      [[custom:dirt3]],
      [[custom:Nano]],
    },

  },

  showNanoSpray                 = false,
  side                          = [[THUNDERBIRDS]],
  sightDistance                 = 273,
  smoothAnim                    = true,
  TEDClass                      = [[PLANT]],
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 42,
  yardMap                       = [[ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ooccccoo ]],

  featureDefs                   = {
  },

}

return lowerkeys({ roostfac = unitDef })
