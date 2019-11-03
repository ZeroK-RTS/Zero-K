local name = "commweapon_riotcannon_napalm"
local weaponDef = {
	name                    = [[Napalm Riot Cannon]],
	areaOfEffect            = 170,
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
		burntime         = 420,
		burnchance       = 1,
		setunitsonfire   = [[1]],

		light_camera_height = 1500,
		reaim_time = 1,
	},

	damage                  = {
		default = 165,
		subs    = 9,
	},

	edgeEffectiveness       = 0.75,
	explosionGenerator      = [[custom:napalm_phoenix]],
	fireStarter             = 150,
	impulseBoost            = 60,
	impulseFactor           = 0.5,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 300,
	reloadtime              = 49/30,
	rgbcolor                = [[1 0.3 0.1]],
	soundhit                = [[weapon/burn_mixed]],
	soundStart              = [[weapon/cannon/outlaw_gun]],
	soundStartVolume        = 3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 750,
}

return name, weaponDef
