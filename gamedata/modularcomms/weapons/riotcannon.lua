local name = "commweapon_riotcannon"
local weaponDef = {
	name                    = [[Riot Cannon]],
	areaOfEffect            = 144,
	avoidFeature            = true,
	avoidFriendly           = true,
	burnblow                = true,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire   = [[custom:RIOT_SHELL_L]],

		light_camera_height = 1500,
		reaim_time = 1,
	},

	damage                  = {
		default = 220.2,
		subs    = 12,
	},

	edgeEffectiveness       = 0.75,
	explosionGenerator      = [[custom:FLASH64]],
	fireStarter             = 150,
	impulseBoost            = 60,
	impulseFactor           = 0.5,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 300,
	reloadtime              = 49/30,
	soundHit                = [[weapon/cannon/generic_cannon]],
	soundStart              = [[weapon/cannon/outlaw_gun]],
	soundStartVolume        = 3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 750,
}

return name, weaponDef
