unitDef = {
  unitname                      = [[energysingu]],
  name                          = [[Singularity Reactor]],
  description                   = [[Large Powerplant (+225) - HAZARDOUS]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildCostMetal                = 4000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[energysingu_aoplane.dds]],
  buildPic                      = [[energysingu.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 120 120]],
  collisionVolumeType           = [[ellipsoid]], 
  corpse                        = [[DEAD]],

  customParams                  = {
    description_de = [[Erzeugt Energie (225) - GEFÄHRLICH]],
    helptext       = [[The Singularity Reactor generates massive amount of energy using a controlled black hole - which is about as safe as it sounds. When the reactor is destroyed, the black hole implodes violently, dragging units inside. An entire continent on which this is built should be considered unsafe ground.]],
    helptext_de    = [[Dieser singuläre Reaktor erzeugt eine riesige Menge an Energie, wozu er ein kontrolliertes Schwarzes Loch nutzt - was genauso sicher ist, wie es sich anhört. Wird der Reaktor zerstört, wird eine riesige Menge an Energie frei, die sich in einer Explosion ungeheuren Ausmaßes, vergleichbar mit einer Atomexplosion, äußert. Ein ganzer Kontinent, auf dem der Reaktor gebaut wird, sollte von nun an als unsicherer Boden betrachtet werden.]],
    pylonrange = 150,
    aimposoffset   = [[0 12 0]],
    midposoffset   = [[0 12 0]],
    modelradius    = [[60]],
	removewait     = 1,
  },

  energyMake                    = 225,
  energyUse                     = 0,
  explodeAs                     = [[SINGULARITY]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[energysuperfus]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[fus.s3o]],
  onoffable                     = false,
  script                        = [[energysingu.lua]],
  selfDestructAs                = [[SINGULARITY]],
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooooooooooooooooooooooooooooooooooooooooooooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[fus_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4a.s3o]],
    },

  },

  weaponDefs = {
    SINGULARITY = {
      areaOfEffect       = 1280,
      craterMult         = 1,
      edgeEffectiveness  = 0,
      explosionGenerator = "custom:grav_danger_spikes",
      explosionSpeed     = 100000,
      impulseBoost       = 100,
      impulseFactor      = -10,
      name               = "Naked Singularity",
      soundHit           = "explosion/ex_ultra1",
      damage = {
        default = 9500,
      },
    },
  },
}

return lowerkeys({ energysingu = unitDef })
