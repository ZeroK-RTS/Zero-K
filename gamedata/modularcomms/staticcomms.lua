local comms = {
  comm_mission_tutorial1 = {
    chassis = "armcom3",
	name = "Tutorial Commander",
	modules = { "commweapon_beamlaser", "module_autorepair", "module_autorepair"},
  },  

  -- Not Hax
  comm_riot_cai = {
    chassis = "corcom1",
	name = "Crowd Controller",
	modules = { "commweapon_riotcannon",  "module_adv_targeting",},
	cost = 250,
  },
   comm_econ_cai = {
    chassis = "commsupport1",
	name = "Base Builder",
	modules = { "commweapon_beamlaser",  "module_econ",},
	cost = 275,
  },
  comm_marksman_cai = {
    chassis = "commsupport1",
	name = "The Marksman",
    modules = { "commweapon_gaussrifle", "module_adv_targeting",},
	cost = 225,
  },
  comm_stun_cai = {
    chassis = "armcom1",
	name = "Exotic Assault",
    modules = { "commweapon_lightninggun", "module_autorepair",},
	cost = 375,
  },
  
  -- Hax
  comm_guardian = { 
	chassis = "armcom2", 
	name = "Star Guardian",
	modules = { "commweapon_beamlaser", "module_ablative_armor", "module_high_power_servos", "module_high_power_servos", "weaponmod_high_frequency_beam", "module_energy_cell"},
  },
  comm_riot = {
    chassis = "corcom2",
	name = "Crowd Controller",
    modules = { "commweapon_riotcannon", "commweapon_heatray"},
  },
  comm_recon = {
    chassis = "commrecon2",
	name = "Ghost Recon",
    modules = { "commweapon_heatray", "module_ablative_armor", "module_high_power_servos", "module_high_power_servos", "module_jammer" , "module_autorepair"},
  },
  comm_rocketeer = {
    chassis = "armcom2",
	name = "Rocket Surgeon",
    modules = { "commweapon_rocketlauncher", "module_dmg_booster", "module_adv_targeting", "module_ablative_armor" },
  },
  comm_marksman = {
    chassis = "commsupport2",
	name = "The Marksman",
    modules = { "commweapon_gaussrifle", "module_dmg_booster", "module_adv_targeting", "module_ablative_armor" , "module_high_power_servos"},
  },  
  comm_flamer = {
    chassis = "corcom2",
	name = "The Fury",
    modules = { "commweapon_flamethrower", "module_dmg_booster", "module_ablative_armor", "module_ablative_armor", "module_high_power_servos"},
  },
  comm_marine = {
    chassis = "commrecon2",
	name = "Space Marine",
    modules = { "commweapon_heavymachinegun", "module_heavy_armor", "module_high_power_servos", "module_dmg_booster", "module_adv_targeting"},
  },
  comm_hunter = {
    chassis = "commsupport2",
	name = "Bear Hunter",
    modules = { "commweapon_shotgun", "module_dmg_booster", "module_adv_targeting", "module_high_power_servos", "module_fieldradar"},
  },
}
--[[
for name,stats in pairs(comms) do
	table.insert(stats.modules, "module_econ")
end
--]]
return comms