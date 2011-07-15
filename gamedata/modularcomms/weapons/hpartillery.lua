local name = "commweapon_hpartillery"
local weaponDef = {
	name                    = [[Plasma Artillery]],
	accuracy                = 600,
	areaOfEffect            = 72,
	craterBoost             = 1,
	craterMult              = 2,

	customParams			= {
		muzzleEffect = [[custom:RAIDMUZZLE]],
		miscEffect = [[custom:LEVLRMUZZLE]],
	},	  
	  
	damage                  = {
		default = 750,
		planes  = 750,
		subs    = 37.5,
	},
	
	edgeEffectiveness       = 0.5,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	minbarrelangle          = [[-10]],
    movingAccuracy          = 800,	
	myGravity               = 0.1,
	range                   = 850,
	reloadtime              = 8,
	soundHit                = [[weapon/cannon/arty_hit]],
	soundStart              = [[weapon/cannon/pillager_fire]],
	startsmoke              = [[1]],
	targetMoveError			= 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 330,
}

return name, weaponDef
