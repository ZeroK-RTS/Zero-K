unitDef = {
  unitname                      = [[armarad]],
  name                          = [[Advanced Radar]],
  description                   = [[Long-Range Radar]],
  activateWhenBuilt             = true,
  buildCostEnergy               = 250,
  buildCostMetal                = 250,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[armarad_aoplane.dds]],
  buildPic                      = [[armarad.png]],
  buildTime                     = 250,
  canAttack                     = false,
  category                      = [[UNARMED FLOAT]],
  collisionVolumeOffsets        = [[0 -8 0]],
  collisionVolumeScales         = [[32 83 32]],
  collisionVolumeTest           = 1,
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Langstreckenradar, halbiert Radarungenauigkeit]],
    description_pl = [[Radar Dalekiego Zasiegu z ulepszeniem dokladnosci]],
    helptext       = [[The advanced Radar Tower has a considerably greater range than the basic version and allows you to see further into the enemy's base, at a price.]],
    helptext_de    = [[Der erweiterte Radarturm hat eine weitaus größere Radarreichweite als die Standardvariante. Zusätzlich wird das hin und her wackeln von Zielen halbiert. Dieser Effekt ist global und wirkt such auf alle verbündeten Radartürme aus. Ein, zwei solcher Türme können sehr nützlich sein, haben allerdings ihren Preis.]],
    helptext_pl    = [[Ten radar ma zdecydowanie wiekszy zasieg niz podstawowa wersja. Ponadto, kazdy taki budynek zwieksza dokladnosc namiaru wszystkich wlasnych i sprzymierzonych radarow.]],
    modelradius    = [[16]],
	removewait     = 1,
	priority_misc  = 2, -- High
  },

  energyUse                     = 3,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[advradar]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 330,
  maxSlope                      = 36,
  minCloakDistance              = 150,
  objectName                    = [[novaradar.s3o]],
  script                        = [[armarad.lua]],
  onoffable                     = true,
  radarDistance                 = 4000,
  radarEmitHeight               = 32,
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 800,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo]],

  featureDefs                   = {

    DEAD  = {
      description      = [[Wreckage - Advanced Radar]],
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[novaradar_dead.s3o]],
    },

    HEAP  = {
      description      = [[Debris - Advanced Radar]],
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ armarad = unitDef })
