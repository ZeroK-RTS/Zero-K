local name = "commweapon_areashield"
local weaponDef = {
    name                    = [[Area Shield]],
    craterMult              = 0,

	customParams			= {
		slot = [[2]],
	},
	
    damage                  = {
      default = 10,
    },

    exteriorShield          = true,
    impulseFactor           = 0,
    interceptedByShieldType = 1,
    shieldAlpha             = 0.2,
    shieldBadColor          = [[1 0.1 0.1]],
    shieldGoodColor         = [[0.1 0.1 1]],
    shieldInterceptType     = 3,
    shieldPower             = 3600,
    shieldPowerRegen        = 60,
    shieldPowerRegenEnergy  = 12,
    shieldRadius            = 350,
    shieldRepulser          = false,
    smartShield             = true,
    texture1                = [[shield3mist]],
    visibleShield           = true,
    visibleShieldHitFrames  = 4,
    visibleShieldRepulse    = true,
    weaponType              = [[Shield]],
}

return name, weaponDef
