local comms = {
  -- singleplayer
  comm_mission_tutorial1 = {
    chassis = "armcom3",
    name = "Tutorial Commander",
    modules = { "commweapon_beamlaser", "module_autorepair", "module_autorepair"},
  },  

  comm_campaign_ada = {
    chassis = "cremcom2",
    name = "Ada's Commander",
    description = "Relic Commander, Builds at 10 m/s",
    helptext = "A special piloted commander unit from before the Fall, functioning well despite its age. Piloted by Captain Ada Caedmon, formerly of the 13th Imperial Auxiliary Cohort.",
    modules = { "commweapon_beamlaser", "module_ablative_armor", "module_autorepair", "module_high_power_servos"},
    miscDefs = {
      customparams = {
        helptext_pl = "Specjalna zalogowa jednostka dowodzenia sprzed Upadku, sprawna mimo wieku. Pilotem jest Kapitan Ada Caedmon z dawnej 13 Imperialnej Kohorty Wsparcia.",
      },
    },
  },
  
  comm_campaign_promethean = {
    chassis = "commrecon2",
    name = "The Promethean",
    helptext = "Founder of the Free Machines and creator of the Firebrand virus, a calm, philosophical AI fighting for the freedom of robotkind. A burning spirit.",
    modules = { "commweapon_heatray", "module_ablative_armor", "module_ablative_armor", "weaponmod_plasma_containment", "module_autorepair" },
    decorations = {"skin_recon_red"},
    miscDefs = {
      customparams = {
        helptext_pl = "Zalozyciel Wolnych Maszyn i tworca wirusa Zarzewie; spokojna, filozoficzna sztuczna inteligencja walczaca za wolnosc robotow. Plonie zadza walki.",
      },
    },
  },
  
  comm_campaign_freemachine = {
    chassis = "corcom2",
    name = "Libertas Machina",
    helptext = "The Promethean's top lieutenant, a revolutionary commited to the cause of machine liberation. Loaded for bear and well armored; not to be taken lightly.",
    modules = { "commweapon_riotcannon", "module_ablative_armor", "module_ablative_armor", "module_adv_targeting", "module_autorepair" },
    miscDefs = {
      customparams = {
        helptext_pl = "Najbardziej zaufany porucznik Prometheana, rewolucjonista oddany sprawie wyzwolenia maszyn. Uzbrojony po zeby i dobrze opancerzony - nie mozna go lekcewazyc.",
      },
    },
  },
  
  comm_campaign_odin = {
    chassis = "commrecon2",
    name = "Odin",
    helptext = "The leader of the Valhallans, a warrior built and bred who lives for the glory of battle. An extremely ruthless foe.",
    modules = { "commweapon_lparticlebeam", "module_ablative_armor", "module_ablative_armor", "module_high_power_servos", "module_autorepair", "module_companion_drone"},
    miscDefs = {
      customparams = {
        helptext_pl = "Lider Valhallan, wojownik z krwi i kosci, ktory zyje dla chwaly bitwy. Nie ma skrupulow.",
      },
    },
  },

  comm_campaign_biovizier = {
    chassis = "commsupport2",
    name = "The Biovizier",
    helptext = "AI keeper of the Dynasty's genetic vaults and master geneticist. Cold and calculating.",
    modules = { "commweapon_gaussrifle", "module_ablative_armor", "weaponmod_railaccel", "module_autorepair", "module_autorepair" },
    decorations = { "skin_support_green" },
    miscDefs = {
      customparams = {
        helptext_pl = "Sztuczna inteligencja sprawujaca piecze nad kryptami przechowujacymi dane genetyczne Dynastii. Zimna i przebiegla.",
      },
    },
  },
  
  comm_campaign_isonade = {
    chassis = "benzcom2",	-- TODO get a properly organic model
    name = "Lord Isonade",
    helptext = "One of the ubermenschen nobles of the Dynasty, an ambitious warlord who seeks to establish himself as master of the galaxy. A horribly mutated beast.",
    modules = { "commweapon_sonicgun", "module_heavy_armor", "module_dmg_booster", "module_autorepair", "module_autorepair" },
    decorations = { "skin_bombard_steel" },
    miscDefs = {
      customparams = {
        helptext_pl = "Jeden z lordow-nadludzi Dynastii - ambitny wojownik, ktory ma zamiar przejac wladze nad galaktyka. Bestia zmutowana nie do poznania.",
      },
    },
  },

  comm_campaign_legion = {
    chassis = "corcom2",
    name = "Legate Fidus",
    helptext = "Commander of the Imperial Vanguard Legion, enforcers of the Emperor's will.  A loyal, steadfast soldier.",
    modules = { "commweapon_shotgun", "module_heavy_armor", "weaponmod_autoflechette", "module_adv_targeting", "module_autorepair"},
    --decorations = { "skin_battle_tiger" },
    miscDefs = {
      customparams = {
        helptext_pl = "Dowodca Imperialnego Legionu Strazniczego, ktory wykonuje wole Imperatora. Wierny i niezlomny zolnierz.",
      },
    },
  },  
    
  comm_campaign_praetorian = {
    chassis = "benzcom2",
    name = "Scipio Astra",
    helptext = "Prefect of the elite Praetorian Guard, the Empire's paladins. A fanatic adherent of the Emperor's cult, purging heretics with massive firepower.",
    modules = { "commweapon_assaultcannon", "module_heavy_armor", "weaponmod_high_caliber_barrel", "module_adv_targeting", "module_autorepair"},
    miscDefs = {
      customparams = {
        helptext_pl = "Prefekt Strazy Pretorianskiej, paladynow Imperium. Fanatyczna wyznawczyni kultu Imperatora, ktora oczyszcza heretykow ogromna sila ognia.",
      },
    },
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
--[[
for name,stats in pairs(comms) do
	table.insert(stats.modules, "module_econ")
end
--]]

local costAtLevel = {[0] = 0, 0,200,600,300,400}

local morphableCommDefs = {
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
