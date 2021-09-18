local TRACKED = {
	cloakskirm_bot_rocket = {},
	cloakarty_hammer_weapon = {},
	hoverarty_ata = {},
	striderarty_rocket = {},
	shieldassault_thud_weapon = {},
	shieldskirm_storm_rocket = {},
	vehassault_plasma = {},
	vehheavyarty_cortruck_rocket = {},
	tankarty_core_artillery = {},
	tankassault_cor_reap = {},
	tankheavyassault_cor_gol = {},
	tankheavyarty_plasma = {},
	spiderassault_thud_weapon = {},
	spiderskirm_adv_rocket = {},
	spidercrabe_arm_crabe_gauss = {},
	amphsupport_cannon = {},
	amphfloater_cannon = {},
	gunshipheavyskirm_emg = {},
	gunshipassault_vtol_salvo = {},
	bomberriot_napalm = {},
	bomberheavy_arm_pidr = {},
	bomberprec_bombsabot = {},
	jumpblackhole_black_hole = {
		area_dmg = {
			dps = 5600,
			radius = 70,
			duration = 13.3 * 30,
		},
	},
	jumparty_napalm_sprayer = {
		area_dmg = {
			dps = 20,
			radius = 64,
			duration = 16 * 30,
		},
	},
	shipskirm_rocket = {},
	shiparty_plasma = {},
	turretgauss_gauss = {},
	turretheavy_plasma = {},
	turretantiheavy_ata = {},
	turretheavylaser_laser = {},
	staticarty_plasma = {},
	staticheavyarty_plasma = {},
	tacnuke_weapon = {},
	napalmmissile_weapon = {},
	empmissile_emp_weapon = {},
	seismic_seismic_weapon = {},
}

local config = {}
for projName, customData in pairs(TRACKED) do
	local wDef = WeaponDefNames[projName]
	local wData = {
		wType = wDef.type,
		tracks = wDef.tracks,
		aoe = wDef.damageAreaOfEffect,
		dynamic = wDef.wobble ~= 0 or wDef.dance ~= 0 or wDef.tracks,
	}
	for key, data in pairs(customData) do
		wData[key] = data
	end
	config[wDef.id] = wData
end
return config
