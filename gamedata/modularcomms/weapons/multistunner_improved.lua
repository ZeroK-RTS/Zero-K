local name = "commweapon_multistunner_improved"
local weaponDef = {
	name                    = [[Heavy Multi-Stunner]],
	areaOfEffect            = 144,
	avoidFeature            = false,
	burst                   = 16,
	burstRate               = 0.1875,
	commandFire             = true,

	customParams            = {
		muzzleEffectShot = [[custom:YELLOW_LIGHTNING_MUZZLE]],
		slot = [[3]],
		manualfire = 1,
	},

	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting       = 0,

	damage                  = {
		default = 750,
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
	paralyzeTime            = 9,
	range                   = 360,
	reloadtime              = 12,
	rgbColor                = [[1 1 0.1]],
	soundStart              = [[weapon/lightning_fire]],
	soundTrigger            = false,
	sprayAngle              = 1920,
	texture1                = [[lightning]],
	thickness               = 15,
	turret                  = true,
	weaponType              = [[LightningCannon]],
	weaponVelocity          = 450,
}

return name, weaponDef
