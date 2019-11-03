local name = "commweapon_multistunner"
local weaponDef = {
	name                    = [[Multi-Stunner]],
	areaOfEffect            = 144,
	avoidFeature            = false,
	beamTTL                 = 12,
	burst                   = 16,
	burstRate               = 0.166,
	commandFire             = true,

	customParams            = {
		is_unit_weapon = 1,
		muzzleEffectShot = [[custom:YELLOW_LIGHTNING_MUZZLE]],
		slot = [[3]],
		manualfire = 1,

		light_color = [[0.7 0.7 0.2]],
		light_radius = 320,
		reaim_time = 1,
	},

	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting       = 0,

	damage                  = {
		default = 550,
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
	paralyzeTime            = 8,
	range                   = 360,
	reloadtime              = 25,
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
