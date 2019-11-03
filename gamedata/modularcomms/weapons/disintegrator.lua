local name = "commweapon_disintegrator"
local weaponDef = {
	name                    = [[Disintegrator]],
	areaOfEffect            = 48,
	avoidFeature            = false,
	avoidFriendly           = false,
	avoidNeutral            = false,
	commandfire             = true,
	craterBoost             = 1,
	craterMult              = 6,

	customParams            = {
		is_unit_weapon = 1,
		muzzleEffectShot = [[custom:ataalaser]],
		slot = [[3]],
		manualfire = 1,
		reaim_time = 1,
	},

	damage                  = {
		default    = 2000,
	},

	explosionGenerator      = [[custom:DGUNTRACE]],
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 0,
	leadLimit               = 80,
	noExplode               = true,
	noSelfDamage            = true,
	range                   = 200,
	reloadtime              = 30,
	size                    = 6,
	soundHit                = [[explosion/ex_med6]],
	soundStart              = [[weapon/laser/heavy_laser4]],
	soundTrigger            = true,
	turret                  = true,
	waterWeapon             = true,
	weaponType              = [[DGun]],
	weaponVelocity          = 300,
}

return name, weaponDef
