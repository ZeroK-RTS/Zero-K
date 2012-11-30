include("LuaRules/Configs/customcmds.h.lua")


local config = {
  hqDef = {
    unitName    = "pw_hq",
    terraHeight = 48,
  },

  turretDefs = {
    turret1 = {
      unitName = "corpre",
    },
    turret2 = {
      unitName = "corllt",
    },
    turret3 = {
      unitName = "heavyturret",
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
      cost=700,
      reward=40,
    },        
    tarantula = {
      unitName = "spideraa",
      cost=600,
      reward=30,
    },    
    banshee = {
      unitName = "armkam",
      cost=1500,
      reward=80,
    },   
    crabe = {
      unitName = "armcrabe",
      cost=1300,
      ones=true,
      reward=90,
    },      
    brawler = {
      unitName = "armbrawl",
      cost=1500,
      ones=true,
      reward=80,
    }, 
    outlaw = {
      unitName = "cormak",
      cost=300,
      ones=true,
      reward=30,
    }, 
    
  },
}

local turretDefs = config.turretDefs
local creepDefs  = config.creepDefs


turretDefs["turret1"].spawnFunction =
function (x, z, teamID)
  local turret = Spring.CreateUnit("corpre", x, Spring.GetGroundHeight(x, z), z, 0, teamID)
  Spring.SetUnitWeaponState(turret, 0, {
    range = 600,
    reloadTime = 0.03,
  } )
  local cost = 500
  Spring.SetUnitCosts(turret, {
    buildTime = cost,
    metalCost = cost,
    energyCost = cost,
  } )
  Spring.SetUnitSensorRadius(turret, "los", 600)
  Spring.SetUnitMaxHealth(turret, 3000)
  Spring.SetUnitHealth(turret, 3000)
  Spring.SetUnitNoSelect(turret, true)
  return turret
end

turretDefs["turret2"].spawnFunction =
function (x, z, teamID)
  local turret = Spring.CreateUnit("corllt", x, Spring.GetGroundHeight(x, z), z, 0, teamID)
  Spring.SetUnitWeaponState(turret, 0, {
    range = 600,
    projectiles = 5,
    burst = 8,
    burstRate = 0.01,
    sprayAngle = 0.1,
  } )
  local cost = 1000
  Spring.SetUnitCosts(turret, {
    buildTime = cost,
    metalCost = cost,
    energyCost = cost,
  } )
  Spring.SetUnitSensorRadius(turret, "los", 1000)
  Spring.SetUnitMaxHealth(turret, 4500)
  Spring.SetUnitHealth(turret, 4500)
  Spring.SetUnitNoSelect(turret, true)
  return turret
end

turretDefs["turret3"].spawnFunction =
function (x, z, teamID)
  local squareSize = Game.squareSize
  local height = Spring.GetGroundHeight(x, z) + 30
  Spring.LevelHeightMap(x - squareSize, z - squareSize, x + squareSize, z + squareSize, height)

  local turret = Spring.CreateUnit("heavyturret", x, height, z, 0, teamID)
  Spring.SetUnitResourcing(turret, "ume", 25) -- needs 25 E to fire like anni/ddm
  Spring.SetUnitWeaponState(turret, 0, {
    range = 750,
    reloadTime = 8,
  } )
  local cost = 1500
  Spring.SetUnitCosts(turret, {
    buildTime = cost,
    metalCost = cost,
    energyCost = cost,
  } )
  Spring.SetUnitSensorRadius(turret, "los", 1250)
  Spring.SetUnitMaxHealth(turret, 6000)
  Spring.SetUnitHealth(turret, 6000)
  Spring.SetUnitNoSelect(turret, true)
  return turret
end


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
