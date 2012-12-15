local name = "commweapon_hpartillery_napalm"
local weaponDef = {
	name                    = [[Napalm Artillery]],
	accuracy                = 600,
	areaOfEffect            = 256,
	craterBoost             = 1,
	craterMult              = 2,

	customParams			= {
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		areadamage_preset = [[module_napalmgrenade]],
		burntime = [[60]],
		setunitsonfire = [[1]],
	},	  
	  
	damage                  = {
		default = 100,
		planes  = 100,
		subs    = 5,
	},
	
	edgeEffectiveness       = 0.5,
	explosionGenerator	= [[custom:napalm_firewalker]],
	fireStarter		= 120,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	minbarrelangle          = [[-10]],	
	myGravity               = 0.1,
	range                   = 800,
	reloadtime              = 8,
	rgbcolor				= [[1 0.5 0.2]],	
	size					= 8,	
	soundHit                = [[weapon/cannon/wolverine_hit]],
	soundStart              = [[weapon/cannon/wolverine_fire]],
	startsmoke              = [[1]],
	targetMoveError			= 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 320,
}

return name, weaponDef
