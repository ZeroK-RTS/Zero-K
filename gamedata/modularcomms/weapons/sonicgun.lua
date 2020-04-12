local name = "commweapon_sonicgun"
local weaponDef = {
	name                    = [[Sonic Blaster]],
	areaOfEffect            = 70,
	avoidFeature            = true,
	avoidFriendly           = true,
	burnblow                = true,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		lups_explodelife = 100,
		lups_explodespeed = 1,
		badtargetcategory = [[FIXEDWING]],
		onlyTargetCategory = [[FIXEDWING LAND SINK SWIM FLOAT SHIP SUB GUNSHIP HOVER]],
		reaim_time = 1,
	},

	damage                  = {
		default = 175,
		subs    = 175,
	},

	cegTag			= [[sonictrail]],
	explosionGenerator	= [[custom:sonic]],
	edgeEffectiveness       = 0.75,
	fireStarter             = 150,
	impulseBoost            = 60,
	impulseFactor           = 0.5,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 320,
	reloadtime              = 1.1,
	soundStart              = [[weapon/sonicgun]],
	soundHit                = [[weapon/unfa_blast_2]],
	soundStartVolume        = 12,
	soundHitVolume		= 10,
	texture1                = [[sonic_glow]],
	texture2                = [[null]],
	texture3                = [[null]],
	rgbColor 		= {0, 0.5, 1},
	thickness		= 20,
	corethickness		= 1,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 700,
	waterweapon		= true,
	duration		= 0.15,
}

return name, weaponDef
