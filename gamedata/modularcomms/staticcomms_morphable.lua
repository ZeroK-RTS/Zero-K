return {
  comm_cai_riot = {
    name = "Riot Cop",
    chassis = "corcom",
    levels = {
      {"commweapon_riotcannon", cost = 100},
      {"module_ablative_armor", "module_dmg_booster", cost = 325},
      {"commweapon_heatray", "module_dmg_booster", cost = 250},
      {"module_heavy_armor", "module_high_power_servos", cost = 575},
      {"weaponmod_plasma_containment", "module_ablative_armor", cost = 675},
    },
  },
  comm_cai_range = {
    name = "Mauser",
    chassis = "benzcom",
    levels = {
      {"commweapon_rocketlauncher", cost = 100},
      {"module_ablative_armor", "module_adv_targeting", cost = 325},
      {"commweapon_assaultcannon", "weaponmod_standoff_rocket", cost = 550},
      {"conversion_partillery", "module_adv_targeting", cost = 400},
      {"weaponmod_high_caliber_barrel", "module_ablative_armor", cost = 625},
    },
  },
  comm_cai_assault = {
    name = "Zweihander",
    chassis = "armcom",
    levels = {
      {"commweapon_beamlaser", cost = 50},
      {"module_ablative_armor", "module_high_power_servos", cost = 325},
      {"commweapon_lightninggun", "module_dmg_booster", cost = 250},
      {"weaponmod_high_frequency_beam", "module_adv_targeting", cost = 575},
      {"weaponmod_stun_booster", "module_autorepair", cost = 475},
    },
  },
  comm_cai_specialist = {
    name = "Eagle Eye",
    chassis = "commsupport",
    levels = {
      {"commweapon_lparticlebeam", cost = 50},
      {"module_ablative_armor", "module_adv_nano", cost = 325},
      {"commweapon_slowbeam", "module_adv_targeting", cost = 200},
      {"conversion_shockrifle", "module_adv_targeting", cost = 600},
      {"conversion_disruptor", "module_autorepair", cost = 400},
    },
  },
  comm_cai_hispeed = {
    name = "Blade Runner",
    chassis = "commrecon",
    levels = {
      {"commweapon_heavymachinegun", cost = 100},
      {"module_high_power_servos", "module_high_power_servos", cost = 300},
      {"commweapon_shotgun", "module_ablative_armor", cost = 275},
      {"weaponmod_autoflechette", "module_high_power_servos", cost = 600},
      {"weaponmod_disruptor_ammo", "module_autorepair", cost = 500},
    },
  },
  comm_trainer_strike = {
    name = "Strike Trainer",
    chassis = "armcom",
    levels = {
      {"commweapon_beamlaser", cost = 50},
      {"module_high_power_servos", "module_high_power_servos", cost = 300},
      {"commweapon_lightninggun", "module_ablative_armor", cost = 275},
      {"module_autorepair", "module_high_power_servos", cost = 400},
      {"module_autorepair", "module_adv_targeting", cost = 400},
    },
  },
  comm_trainer_battle = {
    name = "Battle Trainer",
    chassis = "corcom",
    levels = {
      {"commweapon_riotcannon", cost = 100},
      {"module_ablative_armor", "module_dmg_booster", cost = 325},
      {"commweapon_heatray", "module_dmg_booster", cost = 250},
      {"module_heavy_armor", "module_high_power_servos", cost = 575},
      {"weaponmod_plasma_containment", cost = 500},
    },
  },
  comm_trainer_recon = {
    name = "Recon Trainer",
    chassis = "commrecon",
    levels = {
      {"commweapon_heavymachinegun", cost = 100},
      {"module_high_power_servos", "module_high_power_servos", cost = 300},
      {"commweapon_shotgun", "module_ablative_armor", cost = 275},
      {"module_dmg_booster", "module_high_power_servos", cost = 300},
      {"weaponmod_disruptor_ammo", "module_autorepair", cost = 500},
    },
  },
  comm_trainer_support = {
    name = "Support Trainer",
    chassis = "commsupport",
    levels = {
      {"commweapon_lparticlebeam", cost = 50},
      {"module_ablative_armor", "module_adv_nano", cost = 325},
      {"commweapon_slowbeam", "module_resurrect", cost = 325},
      {"module_high_power_servos", "module_adv_targeting", cost = 300},
      {"conversion_disruptor", "module_autorepair", cost = 400},
    },
  },
  comm_trainer_siege = {
    name = "Siege Trainer",
    chassis = "benzcom",
    levels = {
      {"commweapon_rocketlauncher", cost = 100},
      {"module_ablative_armor", "module_adv_targeting", cost = 325},
      {"commweapon_assaultcannon", "weaponmod_standoff_rocket", cost = 550},
      {"conversion_partillery", "module_adv_targeting", cost = 400},
      {"weaponmod_high_caliber_barrel", "module_ablative_armor", cost = 625},
    },
  },
}
