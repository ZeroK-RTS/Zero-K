local name = "commweapon_napalmgrenade"
local weaponDef = {
	name                    = [[Hellfire Grenade]],
	accuracy                = 256,
	areaOfEffect            = 256,
	--cegTag                  = [[torpedo_trail]],
	commandFire             = true,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[3]],
		setunitsonfire = "1",
		burntime = [[90]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		manualfire = 1,

		area_damage = 1,
		area_damage_radius = 128,
		area_damage_dps = 40,
		area_damage_duration = 45,

		light_camera_height = 3500,
		light_color = [[0.75 0.4 0.15]],
		light_radios = 520,
		reaim_time = 1,
	},

	damage                  = {
		default = 200,
		subs    = 10,
	},

	explosionGenerator      = [[custom:napalm_hellfire]],
	firestarter             = 180,
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 2,
	model                   = [[wep_b_fabby.s3o]],
    noSelfDamage            = false,
	range                   = 450,
	reloadtime              = 25,
	smokeTrail              = true,
	soundHit                = [[weapon/cannon/wolverine_hit]],
	soundHitVolume          = 8,
	soundStart              = [[weapon/cannon/cannon_fire3]],
	--startVelocity           = 350,
	--trajectoryHeight        = 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 350,
}

return name, weaponDef
