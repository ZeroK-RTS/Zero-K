local name = "commweapon_lightninggun"
local weaponDef = {
	name                    = [[Lightning Gun]],
	accuracy                = 500,
	beamTTL                 = 1,
	burst                   = 11,
	burstRate               = 0.033,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		extra_damage = 50,
		slot = [[5]],
		muzzleEffectFire = [[custom:zeus_fire_fx]],

		light_camera_height = 1600,
		light_color = [[0.2 0.6 1.2]],
		light_radius = 200,
		reaim_time = 1,
	},

	cylinderTargeting       = 0,

	damage                  = {
		default = 20,
	},

	explosionGenerator      = [[custom:lightningplosion_continuous]],
	fireStarter             = 110,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	intensity               = 24,
	interceptedByShieldType = 1,
	paralyzeTime            = 1,
	range                   = 300,
	reloadtime              = 1 + 25/30,
	rgbColor                = [[0 0.25 1]],
	soundStart              = [[weapon/more_lightning_fast]],
	soundTrigger            = true,
	thickness               = 3.5,
	turret                  = true,
	weaponType              = [[LightningCannon]],
}

return name, weaponDef
