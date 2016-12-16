unitDef = {
  unitname                      = [[armjamt]],
  name                          = [[Sneaky Pete]],
  description                   = [[Area Cloaker/Jammer]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 420,
  buildCostMetal                = 420,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[armjamt_aoplane.dds]],
  buildPic                      = [[ARMJAMT.png]],
  buildTime                     = 420,
  canAttack                     = false,
  category                      = [[SINK UNARMED]],
  cloakCost                     = 1,
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 70 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Verhüllender Turm / Störsender]],
    helptext       = [[Jammers such as this intefere with enemy radar waves, concealing your units' radar returns. Sneaky Pete is also equipped with a cloak shield to hide nearby units from enemy sight.]],
    helptext_de    = [[Störsender wie diese behindern das feindliche Radar, verschleiern, die von deinen Einheiten ausgelösten, Radarechos. Sneaky Pete bietet außerdem noch ein Deckmantel, um Einheiten in der Nähe vor dem Gegner zu verstecken.]],
	removewait     = 1,

    morphto = [[spherecloaker]],
    morphtime = 30,

    area_cloak = 1,
    area_cloak_upkeep = 12,
    area_cloak_radius = 550,
    area_cloak_decloak_distance = 75,
	
	priority_misc = 2, -- High
  },

  energyUse                     = 1.5,
  explodeAs                     = [[BIG_UNITEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[staticjammer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  initCloaked                   = true,
  levelGround                   = false,
  maxDamage                     = 700,
  maxSlope                      = 36,
  minCloakDistance              = 100,
  noAutoFire                    = false,
  objectName                    = [[radarjammer.dae]],
  onoffable                     = true,
  radarDistanceJam              = 550,
  script                        = [[armjamt.lua]],
  seismicSignature              = 16,
  selfDestructAs                = [[BIG_UNITEX]],
  sightDistance                 = 250,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oo oo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[radarjammer_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ armjamt = unitDef })
