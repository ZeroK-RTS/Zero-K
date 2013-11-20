local name = "commweapon_multistunner"
local weaponDef = {
	name                    = [[Multi-Stunner]],
	areaOfEffect            = 144,
	avoidFeature            = false,
	burst                   = 16,
	burstRate               = 0.1875,
	commandFire             = true,

	customParams            = {
		muzzleEffectFire = [[custom:YELLOW_LIGHTNING_MUZZLE]],
		slot = [[3]],
	},

	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting       = 0,

	damage                  = {
		default = 542.534722222222,
	},

	duration                = 8,
	edgeEffectiveness       = 0,
	explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
	fireStarter             = 0,
	impulseBoost            = 0,
	impulseFactor           = 0,
	intensity               = 10,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	paralyzer               = true,
	paralyzeTime            = 6,
	range                   = 360,
	reloadtime              = 12,
	rgbColor                = [[1 1 0.25]],
	soundStart              = [[weapon/lightning_fire]],
	soundTrigger            = false,
	sprayAngle              = 1920,
	texture1                = [[lightning]],
	thickness               = 10,
	turret                  = true,
	weaponType              = [[LightningCannon]],
	weaponVelocity          = 450,
}

return name, weaponDef
