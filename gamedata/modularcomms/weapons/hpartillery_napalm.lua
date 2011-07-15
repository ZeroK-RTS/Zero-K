local name = "commweapon_hpartillery_napalm"
local weaponDef = {
	name                    = [[Napalm Artillery]],
	accuracy                = 600,
	areaOfEffect            = 256,
	craterBoost             = 1,
	craterMult              = 2,

	customParams			= {
		muzzleEffect = [[custom:RAIDMUZZLE]],
		miscEffect = [[custom:LEVLRMUZZLE]],
		areadamage_preset = [[module_napalmgrenade]],
		burntime = [[180]],
	},	  
	  
	damage                  = {
		default = 75,
		planes  = 75,
		subs    = 3.75,
	},
	
	edgeEffectiveness       = 0.5,
	explosionGenerator		= [[custom:firewalkernapalm]],
	fireStarter				= 120,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	minbarrelangle          = [[-10]],
    movingAccuracy          = 800,	
	myGravity               = 0.1,
	range                   = 850,
	reloadtime              = 8,
	rgbcolor				= [[1 0.5 0.2]],	
	size					= 8,	
	soundHit                = [[weapon/cannon/wolverine_hit]],
	soundStart              = [[weapon/cannon/wolverine_fire]],
	startsmoke              = [[1]],
	targetMoveError			= 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 330,
}

return name, weaponDef
