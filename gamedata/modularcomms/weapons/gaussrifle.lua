local name = "commweapon_gaussrifle"
local weaponDef = {
	name                    = [[Gauss Rifle]],
	alphaDecay              = 0.12,
	areaOfEffect            = 16,
	avoidfeature            = false,
	bouncerebound           = 0.15,
	bounceslip              = 1,
	cegTag                  = [[gauss_tag_l]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:flashmuzzle1]],
		single_hit_multi = true,
		reaim_time = 1,
	},

	damage                  = {
		default = 140,
		subs    = 7,
	},

	explosionGenerator      = [[custom:gauss_hit_m]],
	groundbounce            = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	noExplode               = true,
	noSelfDamage            = true,
	numbounce               = 40,
	range                   = 420,
	reloadtime              = 2.5,
	rgbColor                = [[0.5 1 1]],
	separation              = 0.5,
	size                    = 0.8,
	sizeDecay               = -0.1,
	soundHit                = [[weapon/gauss_hit]],
	soundHitVolume          = 3,
	soundStart              = [[weapon/gauss_fire]],
	soundStartVolume        = 2.5,
	stages                  = 32,
	turret                  = true,
	waterbounce             = 1,
	weaponType              = [[Cannon]],
	weaponVelocity          = 2200,
}

return name, weaponDef
