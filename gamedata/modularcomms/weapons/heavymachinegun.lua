local name = "commweapon_heavymachinegun"
local weaponDef = {
	name                    = [[Heavy Machine Gun]],
	accuracy                = 1024,
	alphaDecay              = 0.7,
	areaOfEffect            = 96,
	burnblow                = true,
	craterBoost             = 0.15,
	craterMult              = 0.3,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectShot = [[custom:WARMUZZLE]],
		miscEffectShot = [[custom:DEVA_SHELLS]],
		altforms = {
			lime = {
				explosionGenerator = [[custom:BEAMWEAPON_HIT_GREEN]],
				rgbColor = [[0.2 1 0]],
			},
		},

		light_color = [[0.8 0.76 0.38]],
		light_radius = 180,
		reaim_time = 1,
	},

	damage                  = {
		default = 30,
		subs    = 1.5,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:EMG_HIT_HE]],
	firestarter             = 70,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	intensity               = 0.7,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 285,
	reloadtime              = 5/30,
	rgbColor                = [[1 0.95 0.4]],
	separation              = 1.5,
	soundHit                = [[weapon/cannon/emg_hit]],
	soundStart              = [[weapon/sd_emgv7]],
	soundStartVolume        = 7,
	stages                  = 10,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 550,
}

return name, weaponDef
