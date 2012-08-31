function gadget:GetInfo()
  return {
    name    = "AoS",
    desc    = "AoS Mode",
    author  = "Sprung, modified by Rafal",
    date    = "25/8/2012",
    license = "PD",
    layer   = -10,
    enabled = true,
  }
end

local versionNumber = "v19"

if (Spring.GetModOptions().zkmode ~= "dota") then
  return
end

if (not gadgetHandler:IsSyncedCode()) then
  return
end

include("LuaRules/Configs/customcmds.h.lua")

local random = math.random

local HQ = {}

local basecoms = {}

local team1 = Spring.GetTeamList(0)[1]
local team2 = Spring.GetTeamList(1)[1]
local teams = { team1, team2 }

local rewardEnergyMult = 0.4

local blockedCmds = {
  [CMD.RECLAIM]   = true,
  [CMD.RESURRECT] = true,
  [CMD_AREA_MEX]  = true,
  [CMD_RAMP]  = true,
  [CMD_LEVEL] = true,
  [CMD_RAISE] = true,
}

local disabledCmdArray = { disabled = true }


-- creeps
local creep1 = "spiderassault"
local creep2 = "corstorm"

-- current creep count per wave
local creepcount = 2

-- turrets
local turret1 = "corpre"
local turret2 = "corllt"
local turret3 = "heavyturret"


local fountain   = 500  -- autoheal

local mapSizeX   = Game.mapSizeX
local mapSizeZ   = Game.mapSizeZ
local squareSize = Game.squareSize


local teamData = {
  [1] = {
    hqPosition      = { 1000, 1000 },
    djinnSpawnPoint = { 1200, 1200, facing = 0 },
    comRespawnPoint = { 400 , 400 , facing = 0 },

    creeperSpawnPoints = {
      { 1200, 1200, facing = 1 },
      { 1200, 1200, facing = 0 },
      { 1200, 1200, facing = 0 },
    },
    turretPositions = {
      -- lane turrets
      { 3470, 3652, turret1 },
      { 4867, 1317, turret1 },
      { 1487, 5302, turret1 },
      { 3452,  825, turret2 },
      { 2442, 2487, turret2 },
      {  900, 2920, turret2 },
      {  467, 1467, turret3 },
      { 1467,  587, turret3 },
      { 1638, 1408, turret3 },
      -- bases
      {  850, 1150, turret2 },
      { 1150,  850, turret2 },
    },
  },
  [2] = {
    hqPosition      = { mapSizeX - 1000, mapSizeZ - 1000 },
    djinnSpawnPoint = { mapSizeX - 1200, mapSizeZ - 1200, facing = 2 },
    comRespawnPoint = { mapSizeX - 400 , mapSizeZ - 400 , facing = 2 },

    creeperSpawnPoints = {
      { mapSizeX - 1200, mapSizeZ - 1200, facing = 2 },
      { mapSizeX - 1200, mapSizeZ - 1200, facing = 2 },
      { mapSizeX - 1200, mapSizeZ - 1200, facing = 3 },
    },
    turretPositions = {
      -- lane turrets
      { 4463, 4583, turret1 },
      { 6406, 2844, turret1 },
      { 3118, 6641, turret1 },
      { 7158, 4648, turret2 },
      { 5675, 5684, turret2 },
      { 4824, 7162, turret2 },
      { 6259, 7674, turret3 },
      { 7665, 6682, turret3 },
      { 6666, 6666, turret3 },
      -- bases
      { mapSizeX - 1150, mapSizeX -  850, turret2 },
      { mapSizeX -  850, mapSizeX - 1150, turret2 },
    },
  },
}

local creeperPathWaypoints = {
  [1] = { -- top right path
    { mapSizeX - 1600, 1600 },
  },
  [2] = { -- middle path
    { 0.5 * mapSizeX, 0.5 * mapSizeZ },
  },
  [3] = { -- bottom left path
    { 1600, mapSizeZ - 1600 },
  },
}


local function Point2Dto3D (coordsTable)
  if (type(coordsTable) == "table") then
    coordsTable[3] = coordsTable[2]
    coordsTable[2] = Spring.GetGroundHeight(coordsTable[1], coordsTable[3])
    coordsTable.facing = coordsTable.facing or 0
  end
end

do
  for i = 1, #teams do
    local td = teamData[i]
    Point2Dto3D(td.djinnSpawnPoint)
    Point2Dto3D(td.comRespawnPoint)

    for i = 1, #creeperPathWaypoints do
      Point2Dto3D(td.creeperSpawnPoints[i])
    end
  end
  for i = 1, #creeperPathWaypoints do
    local waypoints = creeperPathWaypoints[i]
    for j = 1, #waypoints do
      Point2Dto3D(waypoints[j])
    end
  end
end


local newUnits = {}

local swimmersData = {}


local function CreateUnitNearby(unitDef, spawnPoint, teamID)
  local x,z = spawnPoint[1] + random(-50, 50), spawnPoint[3] + random(-50, 50)
  local y = Spring.GetGroundHeight(x, z)
  local creep = Spring.CreateUnit(unitDef, x, y, z, spawnPoint.facing, teamID)
  return creep
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (UnitDefs[unitDefID].customParams.commtype) then
    if (not basecoms[unitTeam]) then
      basecoms[unitTeam] = UnitDefs[unitDefID].name
    end

    swimmersData[unitID] = {
      secondsInWater = 0,
      secondsOnLand  = 0,
    }

    for _, buildoptionID in ipairs(UnitDefs[unitDefID].buildOptions) do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, -buildoptionID)
      if (cmdDescID) then
        Spring.EditUnitCmdDesc(unitID, cmdDescID, disabledCmdArray)
      end
    end
  end

  Spring.SetUnitCloak(unitID, false)
  Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {0}, 0)

  newUnits[unitID] = true
end


function gadget:AllowFeatureCreation()
  return false
end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
  _,_,_,_,_,allyteam = Spring.GetTeamInfo(unitTeam)
  if (unitID == HQ[1]) then
    for _,aunitID in ipairs(Spring.GetAllUnits()) do
      if (Spring.GetUnitAllyTeam(aunitID) == 0) then Spring.DestroyUnit(aunitID, true, false) end
    end
    for _,allyteam in ipairs(Spring.GetAllyTeamList()) do
      if (allyteam ~= 1) then
        for _,teams in ipairs(Spring.GetTeamList(allyteam)) do
          Spring.KillTeam(teams)
        end
      end
    end
    Spring.GameOver({1})
  elseif (unitID == HQ[2]) then
    for _,aunitID in ipairs(Spring.GetAllUnits()) do
      if (Spring.GetUnitAllyTeam(aunitID) == 1) then Spring.DestroyUnit(aunitID, true, false) end
    end
    for _,allyteam in ipairs(Spring.GetAllyTeamList()) do
      if (allyteam ~= 0) then
        for _,teams in ipairs(Spring.GetTeamList(allyteam)) do
          Spring.KillTeam(teams)
        end
      end
    end
    Spring.GameOver({0})
  elseif (unitDefID == UnitDefNames["heavyturret"].id) then
    local hq = HQ[allyteam+1]
    _,_,_,eu = Spring.GetUnitResources(hq)
    Spring.SetUnitResourcing(hq, "uue", eu - 25) -- stop hq from using up the free E from turret
  elseif (UnitDefs[unitDefID].name == "amphtele") then
    if (attackerID and (not Spring.AreTeamsAllied(unitTeam, attackerTeam)) and attackerDefID and (UnitDefs[attackerDefID].customParams.commtype or UnitDefs[attackerDefID].name == "attackdrone")) then
      local reward = 100
      Spring.AddTeamResource(attackerTeam, "metal", reward)
      Spring.AddTeamResource(attackerTeam, "energy", reward * rewardEnergyMult) -- less E so ecell is still viable
    end

    -- respawn Djinn
    CreateUnitNearby("amphtele", teamData[allyteam+1].comRespawnPoint, unitTeam)
  elseif (UnitDefs[unitDefID].customParams.commtype) then
    swimmersData[unitID] = nil
    if (attackerID == nil and Spring.GetUnitHealth(unitID) > 0) then return end -- blocks respawn at morph (also blocks respawn at self-d. pwned.)

    if (attackerID and (not Spring.AreTeamsAllied(unitTeam, attackerTeam)) and attackerDefID and (UnitDefs[attackerDefID].customParams.commtype or UnitDefs[attackerDefID].name == "attackdrone")) then
      killer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(attackerTeam)))
      failer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(unitTeam)))
      Spring.Echo(killer .. " pwned " .. failer .. "!")

      local reward = 500 + 0.1 * UnitDefs[unitDefID].metalCost
      Spring.AddTeamResource(attackerTeam, "metal", reward)
      Spring.AddTeamResource(attackerTeam, "energy", reward * rewardEnergyMult) -- less E so ecell is still viable
    end

    CreateUnitNearby(basecoms[unitTeam], teamData[allyteam+1].comRespawnPoint, unitTeam)
  end
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
  if (UnitDefs[unitDefID].name == creep1 or UnitDefs[unitDefID].name == creep2) then
    if (attackerID and (not Spring.AreTeamsAllied(unitTeam, attackerTeam)) and attackerDefID and (UnitDefs[attackerDefID].customParams.commtype or UnitDefs[attackerDefID].name == "attackdrone")) then
      local realDamage = damage + math.min(0, Spring.GetUnitHealth(unitID)) -- negative health means overkill
      local reward = 50 * (realDamage / UnitDefs[unitDefID].health)
      Spring.AddTeamResource(attackerTeam, "metal", reward)
      Spring.AddTeamResource(attackerTeam, "energy", reward * rewardEnergyMult) -- less E so ecell is still viable
    end
  end
end


function SetupTurret1(x, z, teamID)
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
end


function SetupTurret2(x, z, teamID)
  local turret = Spring.CreateUnit("corllt", x, Spring.GetGroundHeight(x, z), z, 0, teamID)
  Spring.SetUnitWeaponState(turret, 0, {
    range = 600,
    projectiles = 5,
    burst = 8,
    burstRate = 0.01,
    sprayAngle = 0.08,
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
end


function SetupTurret3(x, z, teamID)
  local height = Spring.GetGroundHeight(x, z) + 50
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
end


local TurretSetupFunctions = {
  [turret1] = SetupTurret1,
  [turret2] = SetupTurret2,
  [turret3] = SetupTurret3,
}


function gadget:GamePreload()
  for i = 1, #teams do
    local td = teamData[i]
    Point2Dto3D(td.hqPosition)
    local spawnPoint = td.hqPosition
    local hq = Spring.CreateUnit("pw_hq", spawnPoint[1], spawnPoint[2], spawnPoint[3], 0, teams[i])
    HQ[i] = hq

    Spring.SetUnitNoSelect(hq, true)
    Spring.SetUnitResourcing(hq, "uue", 75) -- use 75 E to offset t3 turrets
    Spring.SetUnitSensorRadius(hq, "seismic", 4000)

    for _,turretData in ipairs(td.turretPositions) do
      local turretType = turretData[3]
      TurretSetupFunctions[turretType] (turretData[1], turretData[2], teams[i])
    end
  end

  -- mark fountain
  Spring.LevelHeightMap(fountain - squareSize, fountain - squareSize, fountain, fountain, Spring.GetGroundHeight(fountain, fountain) + 120)
  Spring.LevelHeightMap(mapSizeX - fountain, mapSizeZ - fountain, mapSizeX - fountain + squareSize, mapSizeZ - fountain + squareSize, Spring.GetGroundHeight(mapSizeX - fountain, mapSizeZ - fountain) + 120)
end


function gadget:GameStart()
  -- djinns (cant spawn them at GamePreload because they are selectable and players could move them before game start...)
  for allyteam = 1, #teams do
    local teamList = Spring.GetTeamList(allyteam - 1)
    local spawnPoint = teamData[allyteam].djinnSpawnPoint

    for i = 1, #teamList do
      --Spring.SetTeamResource(teamList[i], "ms", 1000)
      --Spring.SetTeamResource(teamList[i], "es", 1000)

      CreateUnitNearby("amphtele", spawnPoint, teamList[i])
    end
  end
end


function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
  if (cmdID) then
    if (cmdID == CMD.INSERT and cmdParams and cmdParams[2]) then
      cmdID = cmdParams[2]
      cmdParams[1] = cmdParams[4]
    end
    if (((cmdID == CMD.CLOAK or cmdID == CMD_CLOAK_SHIELD) and cmdParams and (cmdParams[1] == 1)) or -- block cloak
      blockedCmds[cmdID] or cmdID < 0) then -- block reclaim, rez, build and terra
      return false
    end
  end
  return true
end


-- changing units' damage
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
  if (weaponID and WeaponDefs[weaponID] and WeaponDefs[weaponID].name:find("shockrifle")) then damage = damage * 0.6 end -- nerf Shock Rifle

  -- secret buffs to sprung for being awesome
  if (UnitDefs[unitDefID].name:find("c47367")) then damage = damage * 0.7 end
  if (attackerDefID and UnitDefs[attackerDefID].name:find("c47367")) then damage = damage * 1.3 end

  return damage
end


local CreepSetupFunctions = {
  [creep1] =
  function (creepID)
    --Spring.SetUnitWeaponState(creepID, 0, "reloadTime", 1.5)
    --Spring.MoveCtrl.SetGroundMoveTypeData(creepID, "maxSpeed", 1.95)
  end,

  [creep2] =
  function (creepID)

  end,
}


function gadget:GameFrame(n)
  for unitID,_ in pairs(newUnits) do -- must be done one frame after unit creation, not in UnitCreated
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_CLOAK_SHIELD)
    if (cmdDescID) then
      Spring.GiveOrderToUnit(unitID, CMD_CLOAK_SHIELD, {0}, 0)
      Spring.RemoveUnitCmdDesc(unitID, cmdDescID) -- block area cloak
    end

    for cmdID,_ in pairs(blockedCmds) do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmdID)
      if (cmdDescID) then
        Spring.EditUnitCmdDesc(unitID, cmdDescID, disabledCmdArray) -- block terraform and some other commands
        --Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
      end
    end
  end
  newUnits = {}

  if (n % 30 == 17) then
    -- healing areas
    everything = Spring.GetAllUnits()
    for i = 1, #everything do
      if (Spring.GetUnitDefID(everything[i]) ~= UnitDefNames["terraunit"].id) then
        local x,_,z = Spring.GetUnitBasePosition(everything[i])
        allyteam = select(6, Spring.GetTeamInfo(Spring.GetUnitTeam(everything[i])))
        if ((allyteam == 0 and x < fountain and z < fountain) or (allyteam == 1 and x > mapSizeX - fountain and z > mapSizeZ - fountain)) then
          local hp, maxHp = Spring.GetUnitHealth(everything[i])
          Spring.SetUnitHealth(everything[i], math.min(hp + 200, maxHp))
        end
      end
    end

    -- water damage
    local unitsToDamage = {}
    for unitID, data in pairs(swimmersData) do
      local _,height = Spring.GetUnitBasePosition(unitID)
      if (height < 0) then
        data.secondsInWater = data.secondsInWater + 1
        data.secondsOnLand = 0
        if (data.secondsInWater > 10) then
          unitsToDamage[unitID] = (data.secondsInWater - 10) * 2 -- can't call AddUnitDamage here directly
        end
      else
        data.secondsOnLand = data.secondsOnLand + 1
        if (data.secondsInWater > 0) then
          if (data.secondsOnLand < 20) then
            data.secondsInWater = data.secondsInWater - 1
          elseif (data.secondsOnLand == 20) then
            data.secondsInWater = 0
          end
        end
      end
    end
    for unitID, damage in pairs(unitsToDamage) do
      Spring.AddUnitDamage(unitID, damage, 0, -1, -5) -- deal water damage
    end
  end

  if (n % 1350 == 900) then
    if (n % (5*1350) == 900) then creepcount = math.min(creepcount + 1, 7) end

    -- prepare list of creeper types to spawn
    local creepsToSpawn = {}
    for i = 1, creepcount do
      creepsToSpawn[i] = creep1
    end
    creepsToSpawn[creepcount+1] = creep2

    for path = 1, #creeperPathWaypoints do
      local wayPoints = creeperPathWaypoints[path]

      for i = 1, #creepsToSpawn do
        creepDef = creepsToSpawn[i]

        for t = 1, 2 do
          local creepID = CreateUnitNearby(creepDef, teamData[t].creeperSpawnPoints[path], teams[t])
          CreepSetupFunctions[creepDef] (creepID)
          Spring.SetUnitNoSelect(creepID, true) -- creeps uncontrollable

          if (t == 1) then
            for w = 1, #wayPoints do
              Spring.GiveOrderToUnit(creepID, CMD.FIGHT, wayPoints[w], CMD.OPT_SHIFT)
            end
            Spring.GiveOrderToUnit(creepID, CMD.FIGHT, teamData[2].hqPosition, CMD.OPT_SHIFT)
          else
            for w = #wayPoints, 1, -1 do
              Spring.GiveOrderToUnit(creepID, CMD.FIGHT, wayPoints[w], CMD.OPT_SHIFT)
            end
            Spring.GiveOrderToUnit(creepID, CMD.FIGHT, teamData[1].hqPosition, CMD.OPT_SHIFT)
          end
        end
      end
    end
  end
end