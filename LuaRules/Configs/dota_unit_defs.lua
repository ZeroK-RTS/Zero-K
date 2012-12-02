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
		[0]={unitName = "dota_heavyturret_upd",},
		[1]={unitName = "dota_heavyturret",},
		[2]={unitName = "dota_heavyturret",},
		[3]={unitName = "dota_heavyturret",},
		[4]={unitName = "dota_heavyturret",},
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
    glave = {
      unitName = "armpw",
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
    tarantula = {
      unitName = "spideraa",
      cost=700,
      reward=30,
    },    
    banshee = {
      unitName = "armkam",
      cost=800,
      reward=80,
    },   
    crabe = {
      unitName = "armcrabe",
      cost=700,
      ones=true,
      reward=90,
    },      
    brawler = {
      unitName = "armbrawl",
      cost=600,
      ones=true,
      reward=80,
    }, 
    outlaw = {
      unitName = "cormak",
      cost=100,
      ones=true,
      reward=30,
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
