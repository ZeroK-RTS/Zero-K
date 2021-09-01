local TRACKED = {
    cloakskirm_bot_rocket = true,
    cloakarty_hammer_weapon = true,
    hoverarty_ata = true,
    striderarty_rocket = true,
    shieldassault_thud_weapon = true,
    shieldskirm_storm_rocket = true,
    vehassault_plasma = true,
    vehheavyarty_cortruck_rocket = true,
    tankarty_core_artillery = true,
    tankassault_cor_reap = true,
    tankheavyassault_cor_gol = true,
    tankheavyarty_plasma = true,
    spiderassault_thud_weapon = true,
    spiderskirm_adv_rocket = true,
    spidercrabe_arm_crabe_gauss = true,
    amphsupport_cannon = true,
    amphfloater_cannon = true,
    gunshipheavyskirm_emg = true,
    gunshipassault_vtol_salvo = true,
    bomberriot_napalm = true,
    bomberheavy_arm_pidr = true,
    bomberprec_bombsabot = true,
    jumparty_napalm_sprayer = true,
    shipskirm_rocket = true,
    shiparty_plasma = true,
    turretgauss_gauss = true,
    turretheavy_plasma = true,
    turretantiheavy_ata = true,
    turretheavylaser_laser = true,
    staticarty_plasma = true,
    staticheavyarty_plasma = true,
    tacnuke_weapon = true,
    napalmmissile_weapon = true,
    empmissile_emp_weapon = true,
    seismic_seismic_weapon = true,
}

local config = {}
local dynamic, data
for projName, _ in pairs(TRACKED) do
  data = WeaponDefNames[projName]
  dynamic = data.wobble ~= 0 or data.dance ~= 0 or data.tracks or data.selfExplode
  config[data.id] = {
    aoe = data.damageAreaOfEffect,
    wType = data.type,
    trajectoryHeight = data.trajectoryHeight,
    dynamic = dynamic,
    range = data.range,
    selfExplode = data.selfExplode,
  }
end

return config
