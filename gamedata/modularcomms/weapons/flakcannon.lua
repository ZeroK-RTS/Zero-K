local name = "commweapon_flakcannon"
local weaponDef = {
	name                    = [[Flak Cannon]],
	accuracy                = 100,
	areaOfEffect            = 64,
	burnblow                = true,
	canattackground         = false,
	cegTag                  = [[flak_trail]],
	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting      = 1,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire   = [[custom:RIOT_SHELL_L]],
		onlyTargetCategory = [[FIXEDWING GUNSHIP]],

		light_radius = 0,
		reaim_time = 1,
	},

	damage                  = {
		default = 12,
		planes  = 120,
		subs    = 6,
	},

	edgeEffectiveness       = 0.85,
	explosionGenerator      = [[custom:FLAK_HIT_16]],
	impulseBoost            = 0,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 860,
	reloadtime              = 0.8,
	size                    = 0.01,
	soundHit                = [[weapon/flak_hit]],
	soundStart              = [[weapon/flak_fire]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 2000,
}

return name, weaponDef
