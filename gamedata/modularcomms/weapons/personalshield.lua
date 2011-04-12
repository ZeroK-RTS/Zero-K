local name = "commweapon_personal_shield"
local weaponDef = {
	name                    = [[Personal Shield]],
	craterMult              = 0,
	  
	customParams			= {
		slot = [[4]],
	},
	
    damage                  = {
		default = 10,
    },

    exteriorShield          = true,
    impulseFactor           = 0,
    interceptedByShieldType = 1,
    isShield                = true,
    shieldAlpha             = 0.4,
    shieldBadColor          = [[1 0.1 0.1]],
    shieldGoodColor         = [[0.1 0.1 1]],
    shieldInterceptType     = 3,
    shieldPower             = 1000,
    shieldPowerRegen        = 12,
    shieldPowerRegenEnergy  = 0,
    shieldRadius            = 80,
    shieldRepulser          = false,
    shieldStartingPower     = 600,
    smartShield             = true,
    texture1                = [[wakelarge]],
    visibleShield           = true,
    visibleShieldHitFrames  = 4,
    visibleShieldRepulse    = true,
    weaponType              = [[Shield]],
}

return name, weaponDef
