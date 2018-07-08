local name = "commweapon_personal_shield"
local weaponDef = {
	name                    = [[Personal Shield]],

	customParams            = {
		slot = [[4]],
	},

	damage                  = {
		default = 10,
	},

	exteriorShield          = true,
	shieldAlpha             = 0.2,
	shieldBadColor          = [[1 0.1 0.1 1]],
	shieldGoodColor         = [[0.1 0.1 1 1]],
	shieldInterceptType     = 3,
	shieldPower             = 1250,
	shieldPowerRegen        = 16,
	shieldPowerRegenEnergy  = 0,
	shieldRadius            = 80,
	shieldRepulser          = false,
	shieldStartingPower     = 850,
	smartShield             = true,
	visibleShield           = false,
	visibleShieldRepulse    = false,
	weaponType              = [[Shield]],
}

return name, weaponDef
