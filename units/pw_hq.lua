unitDef = {
  unitname                      = [[pw_hq]],
  name                          = [[Command Center]],
  description                   = [[PlanetWars Field HQ]],
  acceleration                  = 0,
  activateWhenBuilt             = true,
  brakeRate                     = 0,
  buildAngle                    = 4096,
  buildCostEnergy               = 10000,
  buildCostMetal                = 10000,
  builder                       = false,
  buildPic						= [[pw_hq.png]],
  buildTime                     = 10000,
  canSelfDestruct		= false,
  category                      = [[FLOAT UNARMED]],
  --corpse                        = [[DEAD]],

  customParams                  = {
  	helptext = [[This building is integral to strategic control of the planet. If the winning team loses their Command Center, their influence gains are halved.]]
  	dontcount = [[1]],
	soundselect = "building_select1",
  },

  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 8,
  footprintZ                    = 8,
  levelGround                   = true,
  iconType                      = [[mahlazer]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  mass                          = 750,
  maxDamage                     = 15000,
  maxSlope                      = 18,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  noAutoFire                    = false,
  objectName                    = [[pw_hq.s3o]],
  power				= 100,
  reclaimable			= false,
  script                	= [[nullscript.lua]],
  seismicSignature              = 4,
  selfDestructAs                = [[ATOMIC_BLAST]],
  selfDestructCountdown		= 120,
  side                          = [[ARM]],
  sightDistance                 = 0,
  waterline			= 30,
  turnRate                      = 0,
  useBuildingGroundDecal        = false,
  workerTime                    = 0,
  --yardMap                       = [[oooooooooooooooooooo]],

  featureDefs                   = {
  },

}

return lowerkeys({ pw_hq = unitDef })
