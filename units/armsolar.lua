unitDef = {
  unitname                      = [[armsolar]],
  name                          = [[Solar Collector]],
  description                   = [[Produces Energy (2)]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostEnergy               = 70,
  buildCostMetal                = 70,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[arm_solar_ground.dds]],
  buildPic                      = [[ARMSOLAR.png]],
  buildTime                     = 70,
  category                      = [[SINK UNARMED STUPIDTARGET SOLAR]],
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Erzeugt Energie (2)]],
    helptext       = [[Solar collectors are the least cost-efficient of the energy structures, but they are also the most reliable and sturdy. When attacked, solars will curl up into armored form for 8 seconds, which reduces incoming damage to a quarter and offers excellent protection against raiders.]],
    helptext_de    = [[Solaranlagen sind von den Energiestrukturen die mit der geringsten Kosteneffizienz, aber sie sind auch die verlässlichsten und stabilsten unter ihnen. Sobald sie angegriffen werden ziehen sie sich in eine gepanzerte Form fur 8 Sekunden zurück, die als exzellenter Schutz gegen Raider fungiert.]],
    pylonrange = 100,
	aimposoffset   = [[0 16 0]],
	midposoffset   = [[0 0 0]],
	force_close    = 8, -- time in seconds of forced turnoff
	removewait     = 1,
  },

  damageModifier                = 0.25,
  energyMake                    = 2,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 5,
  footprintZ                    = 5,
  iconType                      = [[energy_med]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 500,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[arm_solar.s3o]],
  onoffable                     = true,
  script                        = [[armsolar.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = 0,
  yardMap                       = [[ooooooooooooooooooooooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[arm_solar_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ armsolar = unitDef })
