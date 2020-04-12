local name = "commweapon_massdriver"
local weaponDef = {
	name                    = [[Mass Driver]],
	alphaDecay              = 0.12,
	areaOfEffect            = 32,
	avoidfeature            = false,
	--cegTag                  = [[gauss_tag_l]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		miscEffectFire   = [[custom:RIOT_SHELL_L]],
		reaim_time = 1,
	},

	damage                  = {
		default = 270,
		subs    = 13.5,
	},

	explosionGenerator      = [[custom:plasma_hit_32]],
	impactOnly              = false,
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 420,
	reloadtime              = 3,
	rgbColor                = [[1 0.7 0.2]],
	separation              = 1,
	size                    = 2,
	sizeDecay               = 0,
	soundHit                = [[weapon/flak_hit]],
	soundStart              = [[weapon/flak_fire2]],
	stages                  = 32,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 1600,
}

return name, weaponDef
