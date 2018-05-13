local name = "commweapon_partillery_napalm"
local weaponDef = {
	name                    = [[Light Napalm Artillery]],
	accuracy                = 350,
	areaOfEffect            = 128,

	customParams            = {
		muzzleEffectFire = [[custom:thud_fire_fx]],
		burnchance = [[1]],
		setunitsonfire = [[1]],
		burntime = [[450]],
	},

	craterBoost             = 0,
	craterMult              = 0,

	damage                  = {
		default = 240,
		subs    = 12,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:napalm_koda]],
	fireStarter             = 100,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	myGravity               = 0.09,
	noSelfDamage            = true,
	range                   = 800,
	reloadtime              = 4,
	size                    = 4,
	soundHit                = [[weapon/burn_mixed]],
	soundStart              = [[weapon/cannon/cannon_fire1]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 300,
}

return name, weaponDef
