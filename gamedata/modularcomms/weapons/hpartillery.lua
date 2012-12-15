local name = "commweapon_hpartillery"
local weaponDef = {
	name                    = [[Plasma Artillery]],
	accuracy                = 600,
	areaOfEffect            = 96,
	craterBoost             = 1,
	craterMult              = 2,

	customParams			= {
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_H]],
	},	  
	  
	damage                  = {
		default = 800,
		planes  = 800,
		subs    = 40,
	},
	
	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:PLASMA_HIT_96]],	
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	minbarrelangle          = [[-10]],	
	myGravity               = 0.1,
	range                   = 800,
	reloadtime              = 8,
	soundHit                = [[weapon/cannon/arty_hit]],
	soundStart              = [[weapon/cannon/pillager_fire]],
	startsmoke              = [[1]],
	targetMoveError			= 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 320,
}

return name, weaponDef
