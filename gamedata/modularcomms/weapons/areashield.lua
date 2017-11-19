local name = "commweapon_areashield"
local weaponDef = {
	name                    = [[Area Shield]],

	customParams            = {
		slot = [[2]],
	},

	damage                  = {
		default = 10,
	},

	exteriorShield          = true,
	shieldAlpha             = 0.2,
	shieldBadColor          = [[1 0.1 0.1 1]],
	shieldGoodColor         = [[0.1 0.1 1 1]],
	shieldInterceptType     = 3,
	shieldPower             = 3600,
	shieldPowerRegen        = 50,
	shieldPowerRegenEnergy  = 12,
	shieldRadius            = 350,
	shieldRepulser          = false,
	smartShield             = true,
	visibleShield           = false,
	visibleShieldRepulse    = false,
	weaponType              = [[Shield]],
}

return name, weaponDef
