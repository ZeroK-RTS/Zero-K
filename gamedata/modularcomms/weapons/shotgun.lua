local name = "commweapon_shotgun"
local weaponDef = {
	name                    = [[Shotgun]],
	areaOfEffect            = 32,
	burst					= 3,
	burstRate				= 0.03,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_L]],
	},
	
	damage                  = {
		default = 32,
		planes  = 32,
		subs    = 1.6,
	},
	
	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
	fireStarter             = 50,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	projectiles				= 4,
	range                   = 300,
	reloadtime              = 2,
	rgbColor                = [[1 1 0]],
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/cannon/cannon_fire4]],
	soundStartVolume		= 0.6,
	soundTrigger            = true,
	sprayangle				= 1600,
	targetMoveError         = 0.15,
	thickness               = 2,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef
