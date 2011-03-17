local name = "commweapon_shotgun"
local weaponDef = {
	name                    = [[Shotgun]],
	areaOfEffect            = 32,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:RAIDMUZZLE]],
		miscEffect = [[custom:LEVLRMUZZLE]],
		rangeperlevel = [[15]],
		damageperlevel = [[1.5]],
	},
	
	damage                  = {
		default = 30,
		planes  = 30,
		subs    = 1.5,
	},
	
	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
	fireStarter             = 50,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	projectiles				= 12,
	range                   = 280,
	reloadtime              = 2,
	rgbColor                = [[1 1 0]],
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/cannon/cannon_fire4]],
	soundStartVolume		= 0.8,
	soundTrigger            = false,
	sprayangle				= 1600,
	targetMoveError         = 0.15,
	thickness               = 2,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef
