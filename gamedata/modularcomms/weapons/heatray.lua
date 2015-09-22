local name = "commweapon_heatray"
local weaponDef = {
	name                    = [[Heat Ray]],
	accuracy                = 512,
	areaOfEffect            = 20,
	cegTag                  = [[HEATRAY_CEG]],
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		slot = [[5]],
	},		  

	damage                  = {
		default = 41,
		planes  = 41,
		subs    = 2.05,
	},

	duration                = 0.3,
	dynDamageExp            = 1,
	dynDamageInverted       = false,
	explosionGenerator      = [[custom:HEATRAY_HIT]],
	fallOffRate             = 1,
	fireStarter             = 150,
	heightMod               = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	lodDistance             = 10000,
	proximityPriority       = 4,
	range                   = 320,
	reloadtime              = 0.1,
	rgbColor                = [[1 0.1 0]],
	rgbColor2               = [[1 1 0.25]],
	soundStart              = [[Heatraysound]],
	thickness               = 3,
	tolerance               = 5000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 500,
}

return name, weaponDef
