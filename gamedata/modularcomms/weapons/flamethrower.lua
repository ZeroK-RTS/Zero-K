local name = "commweapon_flamethrower"
local weaponDef = {
	name                    = [[Flame Thrower]],
	areaOfEffect            = 64,
	avoidGround             = false,
	avoidFeature            = false,
	cegTag                  = [[flamer]],
	collideFeature          = false,
	collideGround           = false,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		flamethrower = [[1]],
		setunitsonfire = "1",
        burnchance = "0.4", -- Per-impact
		burntime = [[450]],

		light_camera_height = 2800,
		light_color = [[0.6 0.39 0.18]],
		light_radius = 260,
		light_fade_time = 10,
		light_beam_mult_frames = 5,
		light_beam_mult = 5,
		reaim_time = 1,
	},

	damage                  = {
		default = 11,
		subs    = 0.11,
	},

	explosionGenerator      = [[custom:SMOKE]],
	fallOffRate             = 1,
	fireStarter             = 100,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	noExplode               = true,
	noSelfDamage            = true,
	range                   = 270,
	reloadtime              = 5/30,
	rgbColor                = [[1 1 1]],
	soundStart              = [[weapon/flamethrower]],
	soundTrigger            = true,
    texture1				= [[flame]],
    thickness				= 0,
	tolerance               = 5000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 800,
}

return name, weaponDef
