local name = "commweapon_partillery"
local weaponDef = {
	name                    = [[Plasma Artillery]],
	accuracy                = 600,
	areaOfEffect            = 96,
	craterBoost             = 1,
	craterMult              = 2,

	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:RAIDMUZZLE]],
		miscEffect = [[custom:LEVLRMUZZLE]],
		rangeperlevel = [[45]],
		damageperlevel = [[30]],
	},	  
	  
	damage                  = {
		default = 600,
		planes  = 600,
		subs    = 35,
	},
	
	edgeEffectiveness       = 0.5,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	minbarrelangle          = [[-10]],
	myGravity               = 0.1,
	noSelfDamage            = true,
	range                   = 900,
	reloadtime              = 7,
	renderType              = 4,
	soundHit                = [[weapon/cannon/arty_hit]],
	soundStart              = [[weapon/cannon/pillager_fire]],
	startsmoke              = [[1]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 330,
}

return name, weaponDef
