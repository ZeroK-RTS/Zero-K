local name = "commweapon_peashooter"
local weaponDef = {
	name                    = [[Laser Blaster]],
	areaOfEffect            = 8,
	beamWeapon              = true,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_RED]],
	},		  
	  
	damage                  = {
		default = 11,
		planes  = 11,
		subs    = 0.55,
	},
	
	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
	fireStarter             = 50,
	heightMod               = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	lineOfSight             = true,
	noSelfDamage            = true,
	range                   = 300,
	reloadtime              = 0.107,
	renderType              = 0,
	rgbColor                = [[1 0 0]],
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/laser/small_laser_fire2]],
	soundTrigger            = true,
	targetMoveError         = 0.15,
	thickness               = 2.55,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef
