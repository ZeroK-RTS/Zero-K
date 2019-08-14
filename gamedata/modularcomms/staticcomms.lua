local commsCampaign = {
  -- singleplayer
  comm_mission_tutorial1 = {
    chassis = "cremcom3",
    name = "Tutorial Commander",
    modules = { "commweapon_beamlaser", "module_autorepair", "module_autorepair"},
  },

  comm_campaign_ada = {
    chassis = "cremcom2",
    name = "Ada's Commander",
    -- comm module list should be empty/nil to avoid funny stuff when merging with misson's module table
    --modules = { "commweapon_beamlaser", "module_ablative_armor", "module_autorepair", "module_high_power_servos"},
  },
  
  comm_campaign_promethean = {
    chassis = "commrecon2",
    name = "The Promethean",
    --modules = { "commweapon_heatray", "module_ablative_armor", "module_ablative_armor", "weaponmod_plasma_containment", "module_autorepair" },
    decorations = {"skin_recon_red"},
  },
  
  comm_campaign_freemachine = {
    chassis = "commstrike2",
    name = "Libertas Machina",
    --modules = { "commweapon_riotcannon", "module_ablative_armor", "module_ablative_armor", "module_adv_targeting", "module_autorepair" },
  },
  
  comm_campaign_odin = {
    chassis = "commrecon2",
    name = "Odin",
    --modules = { "commweapon_lparticlebeam", "module_ablative_armor", "module_ablative_armor", "module_high_power_servos", "module_autorepair", "module_companion_drone"},
  },

  comm_campaign_biovizier = {
    chassis = "commsupport2",
    name = "The Biovizier",
    --modules = { "commweapon_gaussrifle", "module_ablative_armor", "weaponmod_railaccel", "module_autorepair", "module_autorepair" },
    decorations = { "skin_support_green" },
  },
  
  comm_campaign_isonade = {
    chassis = "commstrike2",	-- TODO get a properly organic model
    name = "Lord Isonade",
    modules = { "commweapon_gaussrifle", "commweapon_gaussrifle", "module_heavy_armor", "module_dmg_booster", "module_autorepair", "module_autorepair" },
    decorations = { "skin_strike_chitin" },
  },

  comm_campaign_legion = {
    chassis = "commstrike2",
    name = "Legate Fidus",
    decorations = { "skin_strike_renegade" },

    --modules = { "commweapon_shotgun", "module_heavy_armor", "weaponmod_autoflechette", "module_adv_targeting", "module_autorepair"},
    --decorations = { "skin_battle_tiger" },
  },
    
  comm_campaign_praetorian = {
    chassis = "benzcom2",
    name = "Scipio Astra",
    --modules = { "commweapon_assaultcannon", "module_heavy_armor", "weaponmod_high_caliber_barrel", "module_adv_targeting", "module_autorepair"},
  },
}
  
local comms = {
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
    modules = { "commweapon_lightninggun", "module_high_power_servos",},
    cost = 250,
  },
  
  -- Hax
  comm_strike_pea = {
    chassis = "armcom1",
    name = "Peashooter Commander",
    modules = { "commweapon_peashooter"},
  },
  comm_strike_hmg = {
    chassis = "armcom1",
    name = "Heavy Machine Gun Commander",
    modules = { "commweapon_heavymachinegun"},
  },
  comm_strike_lpb = {
    chassis = "armcom1",
    name = "Light Particle Beam Commander",
    modules = { "commweapon_lparticlebeam"},
  },
  comm_battle_pea = {
    chassis = "corcom1",
    name = "Peashooter Commander",
    modules = { "commweapon_peashooter"},
  },
  comm_support_pea = {
    chassis = "commsupport1",
    name = "Peashooter Commander",
    modules = { "commweapon_peashooter"},
  },
  comm_recon_pea = {
    chassis = "commrecon1",
    name = "Peashooter Commander",
    modules = { "commweapon_peashooter"},
  },
  
  comm_guardian = {
    chassis = "armcom2",
    name = "Star Guardian",
    modules = { "commweapon_beamlaser", "module_ablative_armor", "module_high_power_servos", "weaponmod_high_frequency_beam"},
  },
  comm_thunder = {
    chassis = "armcom2",
    name = "Thunder Wizard",
    modules = { "commweapon_lightninggun", "module_ablative_armor", "module_high_power_servos", "weaponmod_stun_booster", "module_energy_cell"},
  },
  comm_riot = {
    chassis = "corcom2",
    name = "Crowd Controller",
    modules = { "commweapon_riotcannon", "commweapon_heatray"},
  },
  comm_flamer = {
    chassis = "corcom2",
    name = "The Fury",
    modules = { "commweapon_flamethrower", "module_dmg_booster", "module_ablative_armor", "module_ablative_armor", "module_high_power_servos"},
  },
  comm_recon = {
    chassis = "commrecon2",
    name = "Ghost Recon",
    modules = { "commweapon_lparticlebeam", "module_ablative_armor", "module_high_power_servos", "module_high_power_servos", "module_jammer" , "module_autorepair"},
  },
  comm_marine = {
    chassis = "commrecon2",
    name = "Space Marine",
    modules = { "commweapon_heavymachinegun", "module_heavy_armor", "module_high_power_servos", "module_dmg_booster", "module_adv_targeting"},
  },
  comm_marksman = {
    chassis = "commsupport2",
    name = "The Marksman",
    modules = { "commweapon_massdriver", "module_dmg_booster", "module_adv_targeting", "module_ablative_armor" , "module_high_power_servos"},
  },
  comm_hunter = {
    chassis = "commsupport2",
    name = "Bear Hunter",
    modules = { "commweapon_shotgun", "module_dmg_booster", "module_adv_targeting", "module_high_power_servos", "module_fieldradar"},
  },
  comm_rocketeer = {
    chassis = "benzcom2",
    name = "Rocket Surgeon",
    modules = { "commweapon_rocketlauncher", "module_dmg_booster", "module_adv_targeting", "module_ablative_armor"},
  },
  comm_hammer = {
    chassis = "benzcom2",
    name = "Hammer Slammer",
    modules = { "commweapon_assaultcannon", "module_dmg_booster", "conversion_partillery"},
  },
}

for name, data in pairs(commsCampaign) do
  data.miscDefs = data.miscDefs or {}
  data.miscDefs.customparams = data.miscDefs.customparams or {}
  data.miscDefs.customparams.statsname = name;
  data.miscDefs.reclaimable = false
  data.miscDefs.canSelfDestruct = false
  comms[name] = data
end

--------------------------------------------------------------------------------------
-- Dynamic Commander Clone Generation
--------------------------------------------------------------------------------------
local powerAtLevel = {2000, 3000, 4000, 5000, 6000}

local function MakeClones(levelLimits, moduleNames, fullChassisName, unitName, power, modules, moduleType)
	if moduleType > #levelLimits then
		comms[unitName] = {
			chassis = fullChassisName,
			name = fullChassisName,
			modules = modules,
			power = power,
		}
		return
	end
	
	for copies = 0, levelLimits[moduleType] do
		local newModules = Spring.Utilities.CopyTable(modules)
		for m = 1, copies do
			newModules[#newModules + 1] = moduleNames[moduleType]
		end
		MakeClones(levelLimits, moduleNames, fullChassisName, unitName .. copies, power, newModules, moduleType + 1)
	end
end

local function MakeCommanderChassisClones(chassis, levelLimits, moduleNames)
	for level = 1, #levelLimits do
		local fullChassisName = chassis .. level
		local modules = {}
		MakeClones(levelLimits[level], moduleNames, fullChassisName, fullChassisName .. "_", powerAtLevel[level], modules, 1)
	end
end

--------------------------------------------------------------------------------------
-- Must match dynamic_comm_defs.lua around line 800 (top of the chassis defs)
--------------------------------------------------------------------------------------
MakeCommanderChassisClones("dynrecon",
	{{0}, {1}, {1}, {1}, {1}},
	{"module_personal_shield"}
)

MakeCommanderChassisClones("dynsupport",
	{{0, 0, 0}, {1, 0, 1}, {1, 1, 1}, {1, 1, 1}, {1, 1, 1}},
	{"module_personal_shield", "module_areashield", "module_resurrect"}
)

MakeCommanderChassisClones("dynassault",
	{{0, 0}, {1, 0}, {1, 1}, {1, 1}, {1, 1}},
	{"module_personal_shield", "module_areashield"}
)

MakeCommanderChassisClones("dynstrike",
	{{0, 0}, {1, 0}, {1, 1}, {1, 1}, {1, 1}},
	{"module_personal_shield", "module_areashield"}
)

-- All modules may be available at any level, depending on campaign layout.
MakeCommanderChassisClones("dynknight",
	{{1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 1, 1}},
	{"module_personal_shield", "module_areashield", "module_resurrect", "module_jumpjet"}
)

--[[
for name,stats in pairs(comms) do
	table.insert(stats.modules, "module_econ")
end
--]]

local costAtLevel = {[0] = 0, 0,200,600,300,400}

local morphableCommDefs = VFS.Include("gamedata/modularcomms/staticcomms_morphable.lua")

for templateName, data in pairs(morphableCommDefs) do
  local modules = {}
  local cost = 0
  for i=0,#data.levels do
    local levelInfo = data.levels[i] or {}
    for moduleNum=1,#levelInfo do
      modules[#modules+1] = levelInfo[moduleNum]
    end
    cost = cost + (levelInfo.cost or 0) + costAtLevel[i]
    
    local name = templateName .. "_" .. i
    local humanName = data.name .. " level " .. i
    comms[name] = {
      chassis = data.chassis .. i,
      name = humanName,
      cost = cost,
      modules = Spring.Utilities.CopyTable(modules),
    }
    if i<5 then
      comms[name].morphto = templateName .. "_" .. (i+1)
    end
  end
end

return comms
