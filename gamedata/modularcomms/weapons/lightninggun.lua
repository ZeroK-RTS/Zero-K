local name = "commweapon_lightninggun"
local weaponDef = {
	name                    = [[Lightning Gun]],
	areaOfEffect            = 8,
	beamTTL                 = 12,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		extra_damage_mult = 2.5,
		slot = [[5]],
		muzzleEffectFire = [[custom:zeus_fire_fx]],

		light_camera_height = 1600,
		light_color = [[0.85 0.85 1.2]],
		light_radius = 200,
		reaim_time = 1,
	},

	cylinderTargeting       = 0,

	damage                  = {
		default = 220,
	},

	explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
	fireStarter             = 110,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	intensity               = 12,
	interceptedByShieldType = 1,
	paralyzeTime            = 1,
	range                   = 300,
	reloadtime              = 1 + 25/30,
	rgbColor                = [[0.5 0.5 1]],
	soundStart              = [[weapon/more_lightning_fast]],
	soundTrigger            = true,
	sprayAngle              = 500,
	texture1                = [[lightning]],
	thickness               = 10,
	turret                  = true,
	weaponType              = [[LightningCannon]],
	weaponVelocity          = 400,
}

return name, weaponDef
