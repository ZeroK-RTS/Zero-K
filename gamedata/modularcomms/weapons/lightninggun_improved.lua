local name = "commweapon_lightninggun_improved"
local weaponDef = {
	name                    = [[Heavy Lightning Gun]],
	areaOfEffect            = 8,
	beamTTL                 = 12,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		extra_damage_mult = [[0.266667]],
		slot = [[5]],
		muzzleEffectFire = [[custom:zeus_fire_fx]],
	},

	cylinderTargeting       = 0,

	damage                  = {
		default = 960,
	},

	explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
	fireStarter             = 110,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	intensity               = 12,
	interceptedByShieldType = 1,
	paralyzer               = true,
	paralyzeTime            = 3,
	range                   = 290,
	reloadtime              = 1 + 25/30,
	rgbColor                = [[0.65 0.65 1]],
	soundStart              = [[weapon/more_lightning_fast]],
	soundTrigger            = true,
    sprayAngle              = 1000,
	texture1                = [[lightning]],
	thickness               = 13,
	turret                  = true,
	weaponType              = [[LightningCannon]],
	weaponVelocity          = 400,
}

return name, weaponDef
