unitDef = {
  unitname                      = [[staticcon]],
  name                          = [[Caretaker]],
  description                   = [[Static Constructor, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 1.5,
  buildCostMetal                = 180,
  buildDistance                 = 500,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[staticcon_aoplane.dds]],
  buildPic                      = [[staticcon.png]],
  canGuard                      = true,
  canMove                       = false,
  canPatrol                     = true,
  cantBeTransported             = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[48 48 48]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {

    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -4 0]],
    modelradius    = [[24]],
	default_spacing = 1,
  },

  explodeAs                     = [[NANOBOOM2]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[staticbuilder]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 500,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  minCloakDistance              = 150,
  movementClass                 = [[KBOT2]],
  objectName                    = [[armsenan.s3o]],
  script                        = [[staticcon.lua]],
  selfDestructAs                = [[NANOBOOM2]],
  showNanoSpray                 = false,
  sightDistance                 = 380,
  turnRate                      = 1,
  upright                       = true,
  useBuildingGroundDecal        = true,
  workerTime                    = 10,

  featureDefs                   = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

  },

	weaponDefs = {
		NANOBOOM2 = {
			name = "Nano Explosion",
			areaofeffect = 128,
			craterboost = 1,
			cratermult = 3.5,
			edgeeffectiveness = 0.75,
			explosiongenerator = [[custom:FLASH1]],
			impulseboost = 0,
			impulsefactor = 0.4,
			soundhit = [[explosion/ex_small1]],

			damage = {
				default = 500,
			},
		},
	},
}

return lowerkeys({ staticcon = unitDef })
