local name = "commweapon_assaultcannon"
local weaponDef = {
	name                    = [[Assault Cannon]],
	areaOfEffect            = 32,
	craterBoost             = 1,
	craterMult              = 3,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		--miscEffectFire = [[custom:RIOT_SHELL_L]],
		reaim_time = 1,
	},

	damage                  = {
		default = 360,
		subs    = 18,
	},

	explosionGenerator      = [[custom:INGEBORG]],
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	myGravity               = 0.25,
	range                   = 360,
	reloadtime              = 2,
	soundHit                = [[weapon/cannon/cannon_hit2]],
	soundStart              = [[weapon/cannon/medplasma_fire]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 300,
}

return name, weaponDef
