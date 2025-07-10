-- Nullweapon and Nulladvweapon are both technical junk that users should NOT see. Replace them with default weapons and force them to select a weapon. Beam laser is free IIRC.
local defaultWeapons = {
	[1] = "commweapon_beamlaser", -- strike
	[2] = "commweapon_beamlaser", -- recon
	[3] = "commweapon_beamlaser", -- support
	[4] = "commweapon_beamlaser", -- bombard
	[5] = "commweapon_beamlaser", -- knight?
	[6] = "commweapon_beamlaser", -- knight?
}

local needsExtraParameters = {
	["module_heavy_armor"] = true,
	["module_fireproofing"] = true,
	["module_high_power_servos_improved"] = true,
	["module_cloakregen"] = true,
}

local moduleTranslationOverrides = {
	["module_heavyprojector_second"] = "module_heavyprojector",
	["module_shotgunlaser_second"] = "module_shotgunlaser",
	["module_heavyordinance_second"] = "module_heavyordinance",
	["module_heavy_barrel2"] = "module_heavy_barrel",
	["nulladvweapon"] = "nullbasicweapon",
}

return defaultWeapons, needsExtraParameters, moduleTranslationOverrides
