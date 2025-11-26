local ret = {
	
	
	
	
	dynhub_strike = {
		name = "Strike Support",
		notStarter = true,
		chassis = "strike",
		modules = {
			{"commweapon_shotgun", "module_adv_targeting"},
			{"conversion_disruptor", "module_personal_cloak"},
			{"commweapon_heavymachinegun", "conversion_disruptor", "module_high_power_servos"},
			{"module_high_power_servos", "module_adv_targeting", "module_adv_targeting"},
			{"module_high_power_servos", "module_high_power_servos", "module_adv_targeting"},
		},
	},
	dynhub_recon = {
		name = "Recon Support",
		notStarter = true,
		chassis = "recon",
		modules = {
			{"commweapon_shotgun", "module_radarnet"},
			{"module_ablative_armor", "module_personal_cloak"},
			{"commweapon_disruptorbomb", "conversion_disruptor", "module_high_power_servos"},
			{"module_high_power_servos", "module_high_power_servos", "module_adv_targeting"},
			{"module_high_power_servos", "module_high_power_servos", "module_adv_targeting"},
		},
	},
	dynhub_support = {
		name = "Engineer Support",
		notStarter = true,
		chassis = "support",
		modules = {
			{"commweapon_lightninggun", "module_adv_targeting"},
			{"module_resurrect", "module_personal_cloak"},
			{"commweapon_multistunner", "module_adv_nano", "weaponmod_stun_booster"},
			{"module_adv_nano", "module_adv_nano", "module_adv_targeting"},
			{"module_adv_nano", "module_adv_nano", "module_adv_targeting"},
		},
	},
	dynhub_assault = {
		name = "Guardian Support",
		notStarter = true,
		chassis = "assault",
		modules = {
			{"commweapon_riotcannon", "module_adv_targeting"},
			{"module_adv_targeting", "weaponmod_napalm_warhead"},
			{"commweapon_hpartillery", "module_adv_targeting", "module_dmg_booster"},
			{"module_adv_targeting", "module_adv_targeting", "module_dmg_booster"},
			{"module_adv_targeting", "module_adv_targeting", "module_dmg_booster"},
		},
	},
	dynfancy_recon = {
		name = "Recon Trainer",
		chassis = "recon",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
			{"module_high_power_servos", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		decorations = {"skin_recon_dark"},
	},
	dynfancy_recon2 = {
		name = "Recon Trainer",
		chassis = "recon",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
			{"module_high_power_servos", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		decorations = {"skin_recon_leopard", "banner_overhead"},
		images = {overhead = "184"}
	},
	
	
	dynfancy_support = {
		name = "Engineer Trainer",
		chassis = "support",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
		},
		decorations = {"skin_support_zebra", "banner_overhead"},
		images = {overhead = "184"}
	},
	dynfancy_support2 = {
		name = "Engineer Trainer",
		chassis = "support",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
		},
		decorations = {"skin_support_hotrod"},
	},
	dynfancy_support3 = {
		name = "Engineer Trainer",
		chassis = "support",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
		},
		decorations = {"skin_support_green"},
	},
	dynfancy_support4 = {
		name = "Engineer Trainer",
		chassis = "support",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
		},
		decorations = {"skin_support_dark", "banner_overhead"},
		images = {overhead = "175"}
	},
	dynfancy_guardian = {
		name = "Guardian Trainer",
		chassis = "assault",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
		},
		decorations = {"skin_assault_steel"},
	},
	dynfancy_strike = {
		name = "Strike Trainer",
		chassis = "strike",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
			{"module_high_power_servos", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		decorations = {"banner_overhead","skin_strike_renegade"},
		images = {overhead = "184"}
	},
	dynfancy_strike_lobster = {
		name = "Strike Trainer",
		chassis = "strike",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
			{"module_high_power_servos", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		decorations = {"banner_overhead","skin_strike_chitin"},
		images = {overhead = "184"}
	},
}

local chassisAllDefs=VFS.Include("gamedata/modularcomms/chassises_all_defs.lua")

for i = 1, #chassisAllDefs do
	local chassisDef = chassisAllDefs[i].dyncomms_predefined
	for key, value in pairs(chassisDef) do
		if not value.notSelectable then
			ret[key]=value
		end
	end
end



return ret
