unitDef = {
  unitname              = [[chicken_dodo]],
  name                  = [[Dodo]],
  description           = [[Chicken Bomb]],
  acceleration          = 6,
  activateWhenBuilt     = true,
  brakeRate             = 0.205,
  buildCostEnergy       = 0,
  buildCostMetal        = 0,
  builder               = false,
  buildPic              = [[chicken_dodo.png]],
  buildTime             = 170,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  category              = [[LAND SINK]],

  customParams          = {
  },

  explodeAs             = [[DODO_DEATH]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[chickendodo]],
  idleAutoHeal          = 20,
  idleTime              = 300,
  kamikaze              = true,
  kamikazeDistance      = 80,
  leaveTracks           = true,
  maxDamage             = 200,
  maxSlope              = 36,
  maxVelocity           = 7,
  minCloakDistance      = 75,
  movementClass         = [[AKBOT2]],
  movestate             = 2,
  noAutoFire            = false,
  noChaseCategory       = [[SHIP SWIM FLOAT FIXEDWING SATELLITE GUNSHIP]],
  objectName            = [[chicken_dodo.s3o]],
  onoffable             = true,
  power                 = 170,
  selfDestructAs        = [[DODO_DEATH]],
  selfDestructCountdown = 0,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:green_goo]],
      [[custom:dirt]],
    },

  },
  sightDistance         = 256,
  sonarDistance         = 256,
  trackOffset           = 1,
  trackStrength         = 6,
  trackStretch          = 1,
  trackType             = [[ChickenTrack]],
  trackWidth            = 10,
  turnRate              = 2000,
  upright               = false,
  waterline             = 4,
  workerTime            = 0,

	weaponDefs = {
		DODO_DEATH = {
			name = "Extinction",
			areaofeffect = 300,
			craterboost =  1,
			cratermult = 3.5,
			edgeeffectiveness = 0.4,
			impulseboost = 0,
			impulsefactor = 0.4,
			explosiongenerator = [[custom:large_green_goo]],
			soundhit = [[explosion/mini_nuke]],

			damage = {
				default = 500,
				chicken = 50,
			},
		},
	},
}

return lowerkeys({ chicken_dodo = unitDef })
