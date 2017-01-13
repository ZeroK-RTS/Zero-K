unitDef = {
  unitname                      = [[factoryshield]],
  name                          = [[Shield Bot Factory]],
  description                   = [[Produces Tough Robots, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostEnergy               = 600,
  buildCostMetal                = 600,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 7,
  buildingGroundDecalSizeY      = 7,
  buildingGroundDecalType       = [[factoryshield_aoplane.dds]],

  buildoptions                  = {
    [[cornecro]],
	[[corclog]],
    [[corak]],
    [[corstorm]],
	[[corthud]],
	[[cormak]],
	[[shieldfelon]],
	[[shieldarty]],
	[[corcrash]],
    [[corroach]],
    [[core_spectre]],
  },

  buildPic                      = [[factoryshield.png]],
  buildTime                     = 600,
  canMove                       = true,
  canPatrol                     = true,
  canstop                       = [[1]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Produit des Robots d'Infanterie L. une vitesse de 10 m/s]],
	description_de = [[Produziert zähe Roboter, Baut mit 10 M/s]],
    helptext       = [[The Shield Bot Factory is tough yet flexible. Its units are built to take the pain and dish it back out, without compromising mobility. Clever use of unit combos is well rewarded. Key units: Bandit, Thug, Outlaw, Rogue, Racketeer]],
	helptext_de    = [[Die Shield Bot Factory ist robust aber flexibel. Diese Einheiten werden gebaut, um all die Schmerzen auf sich zu nehmen und wieder zu verteilen, aber ohne Kompromisse bei der Mobilität. Schlauer Einsatz von Einheitenkombos wird gut belohnt. Wichtigste Einheiten: Bandit, Thug, Outlaw, Roach, Dirtbag]],
    sortName       = [[1]],
  },

  energyMake                    = 0.3,
  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 6,
  footprintZ                    = 6,
  iconType                      = [[facwalker]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  metalMake                     = 0.3,
  minCloakDistance              = 150,
  moveState        				= 1,
  noAutoFire                    = false,
  objectName                    = [[factory.s3o]],
  script                        = "factoryshield.lua",
  seismicSignature              = 4,
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,
  yardMap                       = [[oooooo occcco occcco occcco occcco occcco]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[factory_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ factoryshield = unitDef })
