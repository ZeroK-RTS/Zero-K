local name = "commweapon_heatray"
local weaponDef = {
	name                    = [[Heat Ray]],
	accuracy                = 512,
	areaOfEffect            = 20,
	beamWeapon              = true,
	cegTag                  = [[HEATRAY_CEG]],
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	customParams			= {
		slot = [[4]],
		rangeperlevel = [[15]],
		damageperlevel = [[1]],
	},		  
	  
	damage                  = {
		default = 25,
		planes  = 25,
		subs    = 12.5,
	},
	
	duration                = 0.3,
	dynDamageExp            = 1,
	dynDamageInverted       = false,
	explosionGenerator      = [[custom:HEATRAY_HIT]],
	fallOffRate             = 1,
	fireStarter             = 90,
	heightMod               = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	lineOfSight             = true,
	lodDistance             = 10000,
	noSelfDamage            = true,
	proximityPriority       = 4,
	range                   = 310,
	reloadtime              = 0.1,
	renderType              = 0,
	rgbColor                = [[1 0.1 0]],
	rgbColor2               = [[1 1 0.25]],
	soundStart              = [[weapon/heatray_fire]],
	targetMoveError         = 0.25,
	thickness               = 3,
	tolerance               = 5000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 500,
}

return name, weaponDef
