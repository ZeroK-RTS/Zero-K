local name = "commweapon_heavymachinegun"
local weaponDef = { 
	name                    = [[Pulse Autocannon]],
	accuracy                = 2300,
	alphaDecay              = 0.7,
	areaOfEffect            = 96,
	burnblow                = true,
	craterBoost             = 0.15,
	craterMult              = 0.3,

	customParams			= {
		slot = [[4]],
		badTargetCategory  = [[FIXEDWING]],
		onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
	},
	
	damage                  = {
		default = 35,
		planes  = 35,
		subs    = 1.75,
	},
	
	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:EMG_HIT_HE]],
	firestarter             = 70,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	intensity               = 0.7,
	interceptedByShieldType = 1,
	lineOfSight             = true,
	noSelfDamage            = true,
	range                   = 270,
	reloadtime              = 0.2,
	renderType              = 4,
	rgbColor                = [[1 0.95 0.4]],
	separation              = 1.5,
	soundHit                = [[weapon/cannon/emg_hit]],
	soundStart              = [[weapon/heavy_emg]],
	soundStartVolume        = 7,
	stages                  = 10,
	targetMoveError         = 0.3,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 550,
}

return name, weaponDef
