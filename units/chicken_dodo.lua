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
  category              = [[SWIM]],

  customParams          = {
    description_fr = [[Chicken kamikaze]],
	description_de = [[Chicken Bombe]],
    helptext       = [[The Dodo's body contains a volatile mixture of organic explosives. At the slightest provocation, it explodes spectacularly, with the resulting shockwave throwing nearby units into the air. Beware as its flying limbs and spikes will do residual damage.]],
    helptext_fr    = [[Le corps du Dodo renferme un m?lange hautement volatile d'explosifs organiques. Au moindre choc il explose spectaculairement en produisant une onde de choc repoussant avec force les unit?s ? proximit?. Attention en explosant il ?parpille divers restes solides provoquant des dommages supl?mentaires.]],
	helptext_de    = [[Dodos Körper besteht aus einer impulsiven Mixtur von organichen Sprengstoffen. Die kleinste Penetration und Dodo explodiert spektakulär mit einer Schockwelle, die nahegelegene Einheiten zurück schleudert. Hüte dich vor den fliegenden Gliedmaßen, die bleibende Schäden hinterlassen können.]],
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
  movementClass         = [[BHOVER3]],
  movestate             = 2,
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB]],
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
