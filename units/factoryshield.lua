unitDef = {
  unitname                      = [[factoryshield]],
  name                          = [[Shieldbot Factory]],
  description                   = [[Produces Tough, Shielded Robots, Builds at 10 m/s]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 12,
  buildingGroundDecalSizeY      = 12,
  buildingGroundDecalType       = [[factoryshield_aoplane.dds]],

  buildoptions                  = {
    [[shieldcon]],
	[[shieldscout]],
    [[shieldraid]],
    [[shieldskirm]],
	[[shieldassault]],
	[[shieldriot]],
	[[shieldfelon]],
	[[shieldarty]],
	[[shieldaa]],
    [[shieldbomb]],
    [[shieldshield]],
  },

  buildPic                      = [[factoryshield.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_fr = [[Produit des Robots d'Infanterie L. une vitesse de 10 m/s]],
	description_de = [[Produziert zähe Roboter, Baut mit 10 M/s]],
    helptext       = [[The Shieldbot Factory is tough yet flexible. Its units are built to take the pain and dish it back out, without compromising mobility. Clever use of unit combos is well rewarded. Key units: Bandit, Thug, Outlaw, Rogue, Racketeer]],
	helptext_de    = [[Die Shieldbot Factory ist robust aber flexibel. Diese Einheiten werden gebaut, um all die Schmerzen auf sich zu nehmen und wieder zu verteilen, aber ohne Kompromisse bei der Mobilität. Schlauer Einsatz von Einheitenkombos wird gut belohnt. Wichtigste Einheiten: Bandit, Thug, Outlaw, Snitch, Dirtbag]],
    sortName       = [[1]],
    midposoffset   = [[0 0 -24]],
    shield_emit_height = 9,
    solid_factory  = [[6]],
	factorytab       = 1,
	shared_energy_gen = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 6,
  footprintZ                    = 9,
  iconType                      = [[facwalker]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[factory.s3o]],
  onoffable                     = false,
  script                        = "factoryshield.lua",
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[oooooo occcco occcco occcco occcco occcco yyyyyy yyyyyy yyyyyy]],

  weapons                       = {
    {
      def = [[SHIELD]],
    },
  },

  weaponDefs                    = {
    SHIELD = {
      name = [[Energy Shield]],
      damage = {
        default = 10,
      },

      exteriorShield = true,
      shieldAlpha = 0.2,
      shieldBadColor = [[1 0.1 0.1 1]],
      shieldGoodColor = [[0.1 0.1 1 1]],
      shieldInterceptType = 3,
      shieldPower = 900,
      shieldPowerRegen = 9,
      shieldPowerRegenEnergy = 0,
      shieldRadius = 100,
      shieldRepulser = false,
      shieldStartingPower = 300,
      smartShield = true,
      visibleShield = false,
      visibleShieldRepulse = false,
      weaponType = [[Shield]],
    },
  },

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
