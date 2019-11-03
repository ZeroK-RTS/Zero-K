local name = "commweapon_clusterbomb"
local weaponDef = {
	name                    = [[Cluster Bomb]],
	accuracy                = 200,
	avoidFeature            = false,
	avoidNeutral            = false,
	areaOfEffect            = 160,
	burst                   = 2,
	burstRate               = 0.033,
	commandFire             = true,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[3]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_H]],
		manualfire = 1,

		light_camera_height = 2500,
		light_color = [[0.22 0.19 0.05]],
		light_radios = 380,
		reaim_time = 1,
	},

	damage                  = {
		default = 300,
		subs    = 15,
	},

	explosionGenerator      = [[custom:MEDMISSILE_EXPLOSION]],
	fireStarter             = 180,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	interceptedByShieldType = 2,
	model                   = [[wep_b_canister.s3o]],
	projectiles             = 4,
	range                   = 360,
	reloadtime              = 30,
	smokeTrail              = true,
	soundHit                = [[explosion/ex_med6]],
	soundHitVolume          = 8,
	soundStart              = [[weapon/cannon/cannon_fire3]],
	soundStartVolume        = 2,
	soundTrigger            = true,
	sprayangle              = 2500,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 400,
}

return name, weaponDef
