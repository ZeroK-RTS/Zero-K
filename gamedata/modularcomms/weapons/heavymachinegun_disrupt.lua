local name = "commweapon_heavymachinegun_disrupt"
local weaponDef = {
	name                    = [[Disruptor Heavy Machine Gun]],
	accuracy                = 1024,
	alphaDecay              = 0.7,
	areaOfEffect            = 96,
	burnblow                = true,
	craterBoost             = 0.15,
	craterMult              = 0.3,

	customParams            = {
		slot = [[5]],
		muzzleEffectShot = [[custom:WARMUZZLE]],
		miscEffectShot = [[custom:DEVA_SHELLS]],
		timeslow_damagefactor = 2,

		light_color = [[1.3 0.5 1.6]],
		light_radius = 180,
	},

	damage                  = {
		default = 15,
		subs    = 0.825,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_PURPLE]],
	firestarter             = 70,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	intensity               = 0.7,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 285,
	reloadtime              = 5/30,
	rgbColor                = [[0.9 0.1 0.9]],
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
