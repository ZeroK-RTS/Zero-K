local TRACKED_WEAPONS = {
	amphfloater_cannon = {},
	amphsupport_cannon = {},
	bomberheavy_arm_pidr = {},
	bomberprec_bombsabot = {},
	bomberriot_napalm = {},
	cloakarty_hammer_weapon = {},
	cloakskirm_bot_rocket = {
		dynamic = true,
	},
	empmissile_emp_weapon = {},
	gunshipassault_vtol_salvo = {},
	gunshipheavyskirm_emg = {},
	hoverarty_ata = {},
	jumparty_napalm_sprayer = {},
	jumpblackhole_black_hole = {},
	napalmmissile_weapon = {},
	seismic_seismic_weapon = {},
	shieldassault_thud_weapon = {},
	shieldskirm_storm_rocket = {
		dynamic = true,
	},
	shiparty_plasma = {},
	shipskirm_rocket = {},
	spiderassault_thud_weapon = {},
	spidercrabe_arm_crabe_gauss = {},
	spiderskirm_adv_rocket = {},
	staticarty_plasma = {},
	staticheavyarty_plasma = {},
	striderarty_rocket = {},
	tacnuke_weapon = {
		dynamic = true,
	},
	tankarty_core_artillery = {},
	tankassault_cor_reap = {},
	tankheavyarty_plasma = {},
	tankheavyassault_cor_gol = {},
	turretantiheavy_ata = {},
	turretgauss_gauss = {},
	turretheavy_plasma = {},
	turretheavylaser_laser = {},
	vehassault_plasma = {},
	vehheavyarty_cortruck_rocket = {
		dynamic = true,
	},
}

local config = {}
for projName, customData in pairs(TRACKED_WEAPONS) do
	local wDef = WeaponDefNames[projName]
	local wData = {
		wType = wDef.type,
		tracks = wDef.tracks,
		maxVelocity = wDef.maxVelocity,
		aoe = math.max(20, (wDef.impactOnly and 0) or wDef.damageAreaOfEffect),
		dynamic = wDef.wobble ~= 0 or wDef.dance ~= 0 or wDef.tracks,
	}
	for key, data in pairs(customData) do
		wData[key] = data
	end
	config[wDef.id] = wData
end
return config