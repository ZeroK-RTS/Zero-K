local name = "commweapon_concussion"
local weaponDef = {
	name                    = [[Concussion Shell]],
	alphaDecay              = 0.12,
	areaOfEffect            = 192,
	--cegTag                  = [[gauss_tag_m]],
	commandfire             = true,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[3]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		manualfire = 1,

		light_color = [[1.5 1.13 0.6]],
		light_radius = 450,
		reaim_time = 1,
	},

	damage                  = {
		default = 750,
		subs    = 37.5,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:100rlexplode]],
	impulseBoost            = 250,
	impulseFactor           = 0.5,
	interceptedByShieldType = 1,
	range                   = 450,
	reloadtime              = 25,
	rgbColor                = [[1 0.6 0]],
	separation              = 0.5,
	size                    = 0.8,
	sizeDecay               = -0.1,
	soundHit                = [[weapon/cannon/earthshaker]],
	soundStart              = [[weapon/gauss_fire]],
	stages                  = 32,
	turret                  = true,
	waterbounce             = 1,
	weaponType              = [[Cannon]],
	weaponVelocity          = 1000,
}

return name, weaponDef
