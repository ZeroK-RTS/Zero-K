--
local basicChassis = { "recon", "strike", "assault", "support", "knight" }

local generated = {
	[1] = { name = "nullmodule", },
	[2] = { name = "nullbasicweapon", requireChassis = { [1] = "knight", }, },
	[3] = { name = "nulladvweapon", },
	[4] = { name = "nulldualbasicweapon", },
	[5] = { name = "commweapon_beamlaser", },
	[6] = { name = "commweapon_flamethrower", requireChassis = { [1] = "recon", [2] = "assault", [3] = "knight", }, },
	[7] = { name = "commweapon_heatray", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[8] = { name = "commweapon_heavymachinegun", requireChassis = { [1] = "recon", [2] = "assault", [3] = "strike", [4] = "knight", }, },
	[9] = { name = "commweapon_lightninggun", requireChassis = { [1] = "recon", [2] = "support", [3] = "strike", [4] = "knight", }, },
	[10] = { name = "commweapon_lparticlebeam", requireChassis = { [1] = "support", [2] = "recon", [3] = "strike", [4] = "knight", }, },
	[11] = { name = "commweapon_missilelauncher", requireChassis = { [1] = "support", [2] = "strike", [3] = "knight", }, },
	[12] = { name = "commweapon_riotcannon", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[13] = { name = "commweapon_rocketlauncher", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[14] = { name = "commweapon_shotgun", requireChassis = { [1] = "recon", [2] = "support", [3] = "strike", [4] = "knight", }, },
	[15] = { name = "commweapon_hparticlebeam", requireChassis = { [1] = "support", [2] = "knight", }, },
	[16] = { name = "commweapon_shockrifle", requireChassis = { [1] = "support", [2] = "knight", }, },
	[17] = { name = "commweapon_clusterbomb", requireChassis = { [1] = "recon", [2] = "assault", [3] = "knight", }, },
	[18] = { name = "commweapon_concussion", requireChassis = { [1] = "recon", [2] = "knight", }, },
	[19] = { name = "commweapon_disintegrator", requireChassis = { [1] = "assault", [2] = "strike", [3] = "knight", }, },
	[20] = { name = "commweapon_disruptorbomb", requireChassis = { [1] = "recon", [2] = "support", [3] = "strike", [4] = "knight", }, },
	[21] = { name = "commweapon_multistunner", requireChassis = { [1] = "support", [2] = "recon", [3] = "strike", [4] = "knight", }, },
	[22] = { name = "commweapon_napalmgrenade", requireChassis = { [1] = "assault", [2] = "recon", [3] = "knight", }, },
	[23] = { name = "commweapon_slamrocket", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[24] = { name = "econ", },
	[25] = { name = "commweapon_personal_shield", },
	[26] = { name = "commweapon_areashield", requireChassis = { [1] = "assault", [2] = "support", [3] = "knight", }, },
	[27] = { name = "weaponmod_napalm_warhead", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[28] = { name = "conversion_disruptor", requireChassis = { [1] = "strike", [2] = "recon", [3] = "support", [4] = "knight", }, },
	[29] = { name = "weaponmod_stun_booster", requireChassis = { [1] = "support", [2] = "strike", [3] = "recon", [4] = "knight", }, },
	[30] = { name = "module_jammer", },
	[31] = { name = "module_radarnet", },
	[32] = { name = "module_personal_cloak", },
	[33] = { name = "module_cloak_field", requireChassis = { [1] = "support", [2] = "strike", [3] = "knight", }, },
	[34] = { name = "module_resurrect", requireChassis = { [1] = "support", [2] = "knight", }, },
	[35] = { name = "module_jumpjet", requireChassis = { [1] = "knight", }, },
	[36] = { name = "module_companion_drone", },
	[37] = { name = "module_battle_drone", requireChassis = { [1] = "assault", [2] = "support", [3] = "knight", }, },
	[38] = { name = "module_autorepair", requireChassis = { [1] = "strike", [2] = "knight", }, },
	[39] = { name = "module_autorepair", requireChassis = { [1] = "assault", [2] = "recon", [3] = "support", }, },
	[40] = { name = "module_ablative_armor", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[41] = { name = "module_heavy_armor", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[42] = { name = "module_ablative_armor", requireChassis = { [1] = "strike", [2] = "recon", [3] = "support", }, },
	[43] = { name = "module_heavy_armor", requireChassis = { [1] = "strike", [2] = "recon", [3] = "support", }, },
	[44] = { name = "module_dmg_booster", },
	[45] = { name = "module_high_power_servos", requireChassis = { [1] = "recon", [2] = "knight", }, },
	[46] = { name = "module_high_power_servos", requireChassis = { [1] = "strike", [2] = "assault", [3] = "support", }, },
	[47] = { name = "module_adv_targeting", },
	[48] = { name = "module_adv_nano", requireChassis = { [1] = "support", }, },
	[49] = { name = "module_adv_nano", requireChassis = { [1] = "strike", [2] = "assault", [3] = "knight", }, },
	[50] = { name = "module_adv_nano", requireChassis = { [1] = "recon", }, },
	[51] = { name = "banner_overhead", },
	[52] = { name = "commweapon_beamlaser_adv", },
	[53] = { name = "commweapon_flamethrower_adv", requireChassis = { [1] = "recon", [2] = "assault", [3] = "knight", }, },
	[54] = { name = "commweapon_heatray_adv", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[55] = { name = "commweapon_heavymachinegun_adv", requireChassis = { [1] = "recon", [2] = "assault", [3] = "strike", [4] = "knight", }, },
	[56] = { name = "commweapon_lightninggun_adv", requireChassis = { [1] = "recon", [2] = "support", [3] = "strike", [4] = "knight", }, },
	[57] = { name = "commweapon_lparticlebeam_adv", requireChassis = { [1] = "support", [2] = "recon", [3] = "strike", [4] = "knight", }, },
	[58] = { name = "commweapon_missilelauncher_adv", requireChassis = { [1] = "support", [2] = "strike", [3] = "knight", }, },
	[59] = { name = "commweapon_riotcannon_adv", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[60] = { name = "commweapon_rocketlauncher_adv", requireChassis = { [1] = "assault", [2] = "knight", }, },
	[61] = { name = "commweapon_shotgun_adv", requireChassis = { [1] = "recon", [2] = "support", [3] = "strike", [4] = "knight", }, },
}

for k, v in pairs(generated) do
	if v.requireChassis == nil then
		v.requireChassis = Spring.Utilities.CopyTable(basicChassis)
	end
	if v.name:find("_adv$") then
		for pos, chassis in pairs(v.requireChassis) do
			if chassis == "knight" then
				table.remove(v.requireChassis, pos)
				break
			end
		end
	end
end

return generated
