local name = "commweapon_beamlaser"
local weaponDef = {
	name                    = [[Beam Laser]],
	areaOfEffect            = 12,
	beamTime                = 0.1,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_BLUE]],
		altforms = {
			green = {
				explosionGenerator = [[custom:flash1green]],
				customParams = { muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_GREEN]] },
				rgbColor = [[0 1 0]],
			},
			red = {
				explosionGenerator = [[custom:flash1red]],
				customParams = { muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_RED]] },
				rgbColor = [[1 0 0]],
			},
			yellow = {
				explosionGenerator = [[custom:flash1yellow]],
				customParams = { muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_YELLOW]] },
				rgbColor = [[1 1 0]],
			},
			white = {
				explosionGenerator = [[custom:flash1white]],
				customParams = { muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_WHITE]] },
				rgbColor = [[1 1 1]],
			},
		},

		stats_hide_damage = 1, -- continuous laser
		stats_hide_reload = 1,

		light_color = [[0.4 1.1 1.1]],
		light_radius = 120,
		reaim_time = 1,
	},

	damage                  = {
		default = 15,
		subs    = 0.8,
	},

	duration                = 0.1,
	edgeEffectiveness       = 0.99,
	explosionGenerator      = [[custom:flash1blue]],
	fireStarter             = 70,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	largeBeamLaser          = true,
	laserFlareSize          = 3,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 330,
	reloadtime              = 3/30,
	rgbColor                = [[0 1 1]],
	soundStart              = [[weapon/laser/pulse_laser3]],
	soundTrigger            = true,
	texture1                = [[largelaser]],
	texture2                = [[flare]],
	texture3                = [[flare]],
	texture4                = [[smallflare]],
	thickness               = 3,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[BeamLaser]],
	weaponVelocity          = 900,
}

return name, weaponDef
