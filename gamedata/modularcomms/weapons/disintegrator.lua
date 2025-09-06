local name = "commweapon_disintegrator"
local weaponDef = {
	name                    = [[Disintegrator]],
	areaOfEffect            = 48,
	avoidFeature            = false,
	avoidFriendly           = false,
	avoidGround             = false,
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
		noexplode_speed_damage = 1,
		stats_burst_damage  = 18000,
		stats_typical_damage  = 18000,
	},

	damage                  = {
		default    = 2000.1,
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
	soundHit                = [[dgun_hit]],
	soundHitVolume          = 8.5,
	soundStart              = [[weapon/laser/heavy_laser4]],
	soundStartVolume        = 8,
	turret                  = true,
	waterWeapon             = true,
	weaponType              = [[DGun]],
	weaponVelocity          = 300,
}

return name, weaponDef
