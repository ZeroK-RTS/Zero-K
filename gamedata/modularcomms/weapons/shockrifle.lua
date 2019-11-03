local name = "commweapon_shockrifle"
local weaponDef = {
	name                    = [[Shock Rifle]],
	areaOfEffect            = 16,
	colormap                = [[0 0 0 0   0 0 0.2 0.2   0 0 0.5 0.5   0 0 0.7 0.7   0 0 1 1   0 0 1 1]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		light_radius = 0,
		reaim_time = 1,
	},

	damage                  = {
		default = 1500,
		subs    = 75,
	},

	explosionGenerator      = [[custom:spectre_hit]],
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 600,
	reloadtime              = 12,
	rgbColor                = [[1 0.2 0.2]],
	separation              = 0.5,
	size                    = 5,
	sizeDecay               = 0,
	soundHit                = [[weapon/laser/heavy_laser6]],
	soundStart              = [[weapon/gauss_fire]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 1000,
}

return name, weaponDef
