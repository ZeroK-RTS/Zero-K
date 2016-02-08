return {
	dyntrainer_strike = {
		name = "Strike Trainer",
		chassis = "strike",
		modules = {
			{"commweapon_lparticlebeam", "module_high_power_servos"},
			{"module_ablative_armor", "module_personal_cloak"},
			{"commweapon_lightninggun", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		--decorations = {"banner_overhead"},
		--images = {overhead = "184"}
	},
	dyntrainer_recon = {
		name = "Recon Trainer",
		chassis = "recon",
		modules = {
			{"commweapon_beamlaser", "module_ablative_armor"},
			{"module_high_power_servos", "commweapon_personal_shield"},
			{"commweapon_clusterbomb", "module_dmg_booster", "module_ablative_armor"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
			{"module_high_power_servos", "module_ablative_armor", "module_dmg_booster"},
		},
		--decorations = {"skin_recon_dark", "banner_overhead"},
		--images = {overhead = "184"}
	},
	dyntrainer_support = {
		name = "Engineer Trainer",
		chassis = "support",
		modules = {
			{"commweapon_lparticlebeam", "module_radarnet"},
			{"module_ablative_armor", "module_high_power_servos"},
			{"commweapon_hparticlebeam", "module_personal_cloak", "module_adv_nano"},
			{"module_dmg_booster", "module_adv_targeting", "module_adv_targeting"},
			{"module_adv_targeting", "module_adv_nano", "module_resurrect"},
		},
		--decorations = {"skin_support_hotrod"},
	},
	dyntrainer_assault = {
		name = "Guardian Trainer",
		chassis = "assault",
		modules = {
			{"commweapon_heavymachinegun", "module_adv_targeting"},
			{"module_high_power_servos", "module_ablative_armor"},
			{"commweapon_riotcannon", "commweapon_personal_shield", "module_heavy_armor"},
			{"module_dmg_booster", "module_dmg_booster", "module_heavy_armor"},
			{"conversion_disruptor","module_dmg_booster", "module_heavy_armor"},
		},
		--decorations = {"banner_overhead"},
		--images = {overhead = "166"}
	},
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
		decorations = {"skin_recon_dark", "banner_overhead"},
		images = {overhead = "184"}
	},
}