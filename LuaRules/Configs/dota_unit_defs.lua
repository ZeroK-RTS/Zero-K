include("LuaRules/Configs/customcmds.h.lua")


local config = {
  hqDef = {
    unitName    = "pw_hq",
    terraHeight = 48,
  },

  turretDefs = {
    turret1 = {
		[0]={unitName = "corpre",},
		[1]={unitName = "corpre",},
		[2]={unitName = "corpre",},
		[3]={unitName = "corpre",},
		[4]={unitName = "corpre",},		
    },
    turret2 = {
		[0]={unitName = "dota_corllt",},
		[1]={unitName = "dota_corllt",},
		[2]={unitName = "dota_corllt_upd",},		
		[3]={unitName = "dota_corllt_upd",},		
		[4]={unitName = "dota_corllt_upd2",},						      
    },
    turret3 = {
		[0]={unitName = "dota_heavyturret",},
		[1]={unitName = "dota_heavyturret",},
		[2]={unitName = "dota_heavyturret_upd",},
		[3]={unitName = "dota_heavyturret_upd",},
		[4]={unitName = "dota_heavyturret_upd2",},
    },
  },

  creepDefs = {
    creep1 = {
      unitName = "spiderassault",
      reward=50,
    },
    creep2 = {
      unitName = "corstorm",
      reward=50,
    },
    creep3 = {
      unitName = "slowmort",
      reward=50,
    },
    warrior = {
      unitName = "armwar",
      cost=400,
      reward=50,
    },    
    bandit = {
      unitName = "corak",
      cost=250,
      reward=10,
    },     
    zeus = {
      unitName = "armzeus",
      cost=700,
      reward=50,
    },  
    aspis  = {
      unitName = "core_spectre",
      cost=1200,
      reward=60,
    },     
    thug  = {
      unitName = "corthud",
      cost=500,
      reward=40,
    },        
    vandal = {
      unitName = "corcrash",
      cost=200,
      reward=5,
    },    
    banshee = {
      unitName = "armkam",
      cost=700,
      reward=80,
    },  
    rogue = {
		unitName = "corstorm",
		cost=600,
		reward=140,
    },
    recluse = {
      unitName = "armsptk",
      cost=900,
      reward=200,
    },  
    hammer={
		unitName = "armham",
		cost=500,
		reward=100,
    },
    crabe = {
      unitName = "armcrabe",
      cost=1300,
      reward=220,
    },      
    
    brawler = {
      unitName = "armbrawl",
      cost=500,
      ones=true,
      reward=80,
    }, 
    outlaw = {
      unitName = "cormak",
      cost=100,
      ones=true,
      reward=30,
    }, 
    dante = {
      unitName = "dante",
      cost=2000,
      ones=true,
      reward=500,
    }, 
    
  },
}

local turretDefs = config.turretDefs
local creepDefs  = config.creepDefs

creepDefs["creep1"].setupFunction =
function (creepID)
  --Spring.SetUnitWeaponState(creepID, 0, "reloadTime", 1.5)
  --Spring.MoveCtrl.SetGroundMoveTypeData(creepID, "maxSpeed", 1.95)
end

creepDefs["creep2"].setupFunction =
function (creepID)
  local cmdDescID = Spring.FindUnitCmdDesc(creepID, CMD_UNIT_AI)
  if (cmdDescID) then
    Spring.GiveOrderToUnit(creepID, CMD_UNIT_AI, {0}, 0) -- disable Rogue autoskirm
    Spring.RemoveUnitCmdDesc(creepID, cmdDescID)
  end
end


return config
