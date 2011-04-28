local name = "commweapon_lightninggun"
local weaponDef = {
	name                    = [[Lightning Gun]],
	areaOfEffect            = 8,
	craterBoost             = 0,
	craterMult              = 0,
	
	customParams            = {
		extra_damage_mult = [[0.4]],
		slot = [[5]],
		muzzleEffect = [[custom:zeusmuzzle]],
		miscEffect = [[custom:zeusgroundflash]],
	},
	
	cylinderTargetting      = 0,
	
	damage                  = {
		default        = 640,
		commanders     = 640,
		empresistant75 = 160,
		empresistant99 = 6.4,
	},
	
	duration                = 10,
	explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
	fireStarter             = 110,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	intensity               = 12,
	interceptedByShieldType = 1,
	lineOfSight             = true,
	paralyzer               = true,
	paralyzeTime            = 1,
	range                   = 280,
	reloadtime              = 2,
	rgbColor                = [[0.5 0.5 1]],
	soundStart              = [[weapon/more_lightning]],
	soundTrigger            = true,
	startsmoke              = [[1]],
	targetMoveError         = 0.3,
	texture1                = [[lightning]],
	thickness               = 10,
	turret                  = true,
	weaponType              = [[LightningCannon]],
	weaponVelocity          = 400,
}

return name, weaponDef
