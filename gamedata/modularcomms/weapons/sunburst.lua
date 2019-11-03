local name = "commweapon_sunburst"
local weaponDef = {
	name                    = [[Sunburst Cannon]],
	areaOfEffect            = 32,
	avoidFriendly           = true,
	commandfire             = true,
	craterBoost             = 1,
	craterMult              = 6,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[3]],
		muzzleEffectFire = [[custom:staticheavyarty_FLARE]],
		manualfire = 1,

		light_color = [[1.3 1.3 2.3]],
		light_radius = 180,
		reaim_time = 1,
	},

	damage                  = {
		default = 2400,
	},

	explosionGenerator      = [[custom:blue_explosion]],
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	interceptedByShieldType = 1,
	myGravity               = 0.01,
	noExplode               = false,
	noSelfDamage            = true,
	range                   = 450,
	reloadtime              = 12,
	rgbColor                = [[0.5 0.5 1]],
	separation              = 0.5,
	size                    = 10,
	sizeDecay               = 0.05,
	soundHit                = [[weapon/laser/heavy_laser6]],
	soundStart              = [[weapon/laser/heavy_laser4]],
	soundTrigger            = true,
	tolerance               = 10000,
	stages                  = 20,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 600,
}

return name, weaponDef
