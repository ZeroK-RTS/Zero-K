function gadget:GetInfo()
  return {
    name    = "AoS",
    desc    = "AoS Mode",
    author  = "Sprung, modified by Rafal",
    date    = "25/8/2012",
    license = "PD",
    layer   = 10, -- run after most gadgets
    enabled = true,
  }
end

local versionNumber = "v23"

if (Spring.GetModOptions().zkmode ~= "dota") then
  return
end

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local random = math.random

local HQ = {}

local team1 = Spring.GetTeamList(0)[1]
local team2 = Spring.GetTeamList(1)[1]
local teams = { team1, team2 }

local rewardEnergyMult = 0.5

local blockedCmds = {
  [CMD.RECLAIM]   = true,
  [CMD.RESURRECT] = true,
  [CMD_AREA_MEX]  = true,
  [CMD_RAMP]  = true,
  [CMD_LEVEL] = true,
  [CMD_RAISE] = true,
}

local disabledCmdArray = { disabled = true }

local terraunitDefID = UnitDefNames["terraunit"].id


-- creeps
local creep1 = "spiderassault"
local creep2 = "corstorm"
local creep3 = "slowmort"

local creepcount    = 2 -- current creep count per wave
local maxcreepcount = 7
local creepbalance  = 0

local wave = 0

-- turrets
local turret1 = "corpre"
local turret2 = "corllt"
local turret3 = "heavyturret"


local mapSizeX   = Game.mapSizeX
local mapSizeZ   = Game.mapSizeZ
local squareSize = Game.squareSize


local teamData = {
  [1] = {
    hqPosition      = { 1000, 1000 },
    djinnSpawnPoint = { 1200, 1100, facing = 0 },
    comRespawnPoint = { 630 , 630 , facing = 0 },

    healingAreas = {
      { 350, 350, radius = 500, healing = 200 },
    },
    creeperSpawnPoints = {
      { 1350, 1050, facing = 1 },
      { 1350, 1250, facing = 0 },
      { 1150, 1250, facing = 0 },
    },
    turretPositions = {
      -- lane turrets
      { 3470, 3652, turret1 },
      { 4890, 1340, turret1 },
      { 1555, 5315, turret1 },
      { 3528,  816, turret2 },
      { 2442, 2487, turret2 },
      {  900, 2920, turret2 },
      {  467, 1467, turret3 },
      { 1467,  587, turret3 },
      { 1573, 1443, turret3 },
      -- bases
      {  840, 1160, turret2 },
      { 1160,  840, turret2 },
    },
  },
  [2] = {
    hqPosition      = { mapSizeX - 1000, mapSizeZ - 1000 },
    djinnSpawnPoint = { mapSizeX - 1200, mapSizeZ - 1200, facing = 2 },
    comRespawnPoint = { mapSizeX - 630 , mapSizeZ - 630 , facing = 2 },

    healingAreas = {
      { mapSizeX - 350, mapSizeZ - 350, radius = 500, healing = 200 },
    },
    creeperSpawnPoints = {
      { mapSizeX - 1150, mapSizeZ - 1350, facing = 2 },
      { mapSizeX - 1350, mapSizeZ - 1350, facing = 2 },
      { mapSizeX - 1350, mapSizeZ - 1150, facing = 3 },
    },
    turretPositions = {
      -- lane turrets
      { 4463, 4583, turret1 },
      { 6403, 2790, turret1 },
      { 3125, 6655, turret1 },
      { 7150, 4640, turret2 },
      { 5675, 5684, turret2 },
      { 4824, 7170, turret2 },
      { 6524, 7664, turret3 },
      { 7665, 6682, turret3 },
      { 6666, 6666, turret3 },
      -- bases
      { mapSizeX - 1160, mapSizeX -  840, turret2 },
      { mapSizeX -  840, mapSizeX - 1160, turret2 },
    },
  },
}

local creeperPathWaypoints = {
  [1] = { -- top right path
    { 4890, 1000 },
    --{ 6592, 1600 },
    { 6750, 2790 },
  },
  [2] = { -- middle path
    { 3980, 4100 },
  },
  [3] = { -- bottom left path
    { 1150, 5315 },
    --{ 1600, 6592 },
    { 3125, 6950 },
  },
}


local function AlignToSquareSize (coordsTable)
  if (type(coordsTable) == "table") then
    for i = 1, 2 do
      coordsTable[i] = math.floor((coordsTable[i] / squareSize) + 0.5) * squareSize
    end
  end
end


local function Point2Dto3D (coordsTable)
  if (type(coordsTable) == "table") then
    coordsTable[3] = coordsTable[2]
    coordsTable[2] = Spring.GetGroundHeight(coordsTable[1], coordsTable[3])
    coordsTable.facing = coordsTable.facing or 0
  end
end


local healingAreasData = {}

do
  for i = 1, #teams do
    local td = teamData[i]
    AlignToSquareSize(td.hqPosition)
    Point2Dto3D(td.djinnSpawnPoint)
    Point2Dto3D(td.comRespawnPoint)

    healingAreasData[i] = td.healingAreas

    for i = 1, #creeperPathWaypoints do
      Point2Dto3D(td.creeperSpawnPoints[i])
    end

    for i = 1, #td.turretPositions do
      AlignToSquareSize(td.turretPositions[i])
    end
  end
  for i = 1, #creeperPathWaypoints do
    local waypoints = creeperPathWaypoints[i]
    for j = 1, #waypoints do
      Point2Dto3D(waypoints[j])
    end
  end
end

_G.healingAreasData = healingAreasData -- make it visible from unsynced


local comsData = {}


local function CreateUnitNearby(unitDef, spawnPoint, teamID, addMarker)
  local x,z = spawnPoint[1] + random(-50, 50), spawnPoint[3] + random(-50, 50)
  local y = Spring.GetGroundHeight(x, z)
  local creep = Spring.CreateUnit(unitDef, x, y, z, spawnPoint.facing, teamID)

  if (addMarker) then
    SendToUnsynced("gamemode_dota_addmarker", x, y, z, teamID)
  end
  return creep
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (UnitDefs[unitDefID].customParams.commtype) then
    comsData[unitID] = {
      secondsInWater  = 0,
      secondsOnLand   = 0,
      lastDamageDefID = 0,
    }

    -- removes build options - handled in unitdefs_post
    --[[
    for _, buildoptionID in ipairs(UnitDefs[unitDefID].buildOptions) do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, -buildoptionID)
      if (cmdDescID) then
        Spring.EditUnitCmdDesc(unitID, cmdDescID, disabledCmdArray) -- disable buildoptions
      end
    end
    ]]--
  end

  Spring.SetUnitCloak(unitID, false)
  Spring.GiveOrderToUnit(unitID, CMD.CLOAK, {0}, 0)

  local cmdDescID = Spring.FindUnitCmdDesc(unitID, CMD_CLOAK_SHIELD)
  if (cmdDescID) then
    Spring.GiveOrderToUnit(unitID, CMD_CLOAK_SHIELD, {0}, 0)
    Spring.RemoveUnitCmdDesc(unitID, cmdDescID) -- block area cloak
  end

  for cmdID,_ in pairs(blockedCmds) do
    local cmdDescID = Spring.FindUnitCmdDesc(unitID, cmdID)
    if (cmdDescID) then
      Spring.EditUnitCmdDesc(unitID, cmdDescID, disabledCmdArray) -- disable terraform and some other commands
      --Spring.RemoveUnitCmdDesc(unitID, cmdDescID)
    end
  end
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

    if (allyteam == 0) then
      creepbalance = creepbalance - 1
    else
      creepbalance = creepbalance + 1
    end
  elseif (UnitDefs[unitDefID].name == "amphtele") then
    if (attackerID and (not Spring.AreTeamsAllied(unitTeam, attackerTeam)) and attackerDefID and (UnitDefs[attackerDefID].customParams.commtype or UnitDefs[attackerDefID].name == "attackdrone")) then
      local reward = 100
      Spring.AddTeamResource(attackerTeam, "metal", reward)
      Spring.AddTeamResource(attackerTeam, "energy", reward * rewardEnergyMult) -- less E so ecell is still viable
    end

    -- respawn Djinn
    CreateUnitNearby("amphtele", teamData[allyteam+1].comRespawnPoint, unitTeam, true)
  elseif (UnitDefs[unitDefID].customParams.commtype) then
    if (attackerID == nil and Spring.GetUnitHealth(unitID) > 0 and GG.wasMorphed[unitID]) then
      comsData[unitID] = nil
      return -- blocks respawn at morph
    end

    local failer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(unitTeam)))
    if (attackerID) then
      if (not Spring.AreTeamsAllied(unitTeam, attackerTeam) and attackerDefID) then
        local killer

        if (UnitDefs[attackerDefID].customParams.commtype or UnitDefs[attackerDefID].name == "attackdrone") then
          local reward = 500 + 0.1 * UnitDefs[unitDefID].metalCost
          Spring.AddTeamResource(attackerTeam, "metal" , reward)
          Spring.AddTeamResource(attackerTeam, "energy", reward * rewardEnergyMult) -- less E so ecell is still viable

          killer = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(attackerTeam)))
        else
          killer = "[" .. UnitDefs[attackerDefID].humanName .. "]"
        end

        Spring.Echo(killer .. " pwned " .. failer .. "!")
      end
    else
      local damageDefID = comsData[unitID].lastDamageDefID
      if (damageDefID == -1) then
        Spring.Echo(failer .. " has been killed by flying debris!")
      elseif (damageDefID == -2 or damageDefID == -3) then
        Spring.Echo(failer .. " has died after colliding with an obstacle!")
      elseif (damageDefID == -4) then
        Spring.Echo(failer .. " has burned to death!")
      elseif (damageDefID == -5) then
        Spring.Echo(failer .. " has drowned!")
      end
    end

    comsData[unitID] = nil

    -- respawn commander
    local comName = GG.startUnits[unitTeam] --UnitDefs[unitDefID].name
    local baseComName = comName:sub(1, -2)
    local comLevel = tonumber(comName:sub(-1))
    comLevel = tostring(math.max(comLevel - 2, 0)) -- respawned com will be 2 levels lower

    if (UnitDefNames[baseComName .. comLevel]) then
      comName = baseComName .. comLevel
    elseif (comLevel == "0" and UnitDefNames[baseComName .. "1"]) then
      comName = baseComName .. "1"
    end
    CreateUnitNearby(comName, teamData[allyteam+1].comRespawnPoint, unitTeam, true)
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
  elseif (comsData[unitID]) then
    comsData[unitID].lastDamageDefID = weaponDefID
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
end


function SetupTurret3(x, z, teamID)
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
end


local TurretSetupFunctions = {
  [turret1] = SetupTurret1,
  [turret2] = SetupTurret2,
  [turret3] = SetupTurret3,
}


function gadget:GamePreload()
  local function hqHeightMapFunc(centerX, centerZ)
    local centerHeight = Spring.GetGroundHeight(centerX, centerZ)
    local wantedHeight
    local size = 144

    for z = -size, size, squareSize do
      for x = -size, size, squareSize do
        wantedHeight = centerHeight + math.min((size - math.max(math.abs(x), math.abs(z))) * (48/64), 48)
        if (wantedHeight > Spring.GetGroundHeight(centerX + x, centerZ + z)) then
          Spring.SetHeightMap(centerX + x, centerZ + z, wantedHeight)
        end
      end
    end
  end

  for i = 1, #teams do
    local td = teamData[i]

    local spawnPoint = td.hqPosition
    Spring.SetHeightMapFunc(hqHeightMapFunc, spawnPoint[1], spawnPoint[2])
    Point2Dto3D(td.hqPosition)
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
    if (((cmdID == CMD.CLOAK or cmdID == CMD_CLOAK_SHIELD) and cmdParams and cmdParams[1] == 1) or -- block cloak
      blockedCmds[cmdID] or cmdID < 0) then -- block reclaim, rez, build and terra
      return false
    end
  end
  return true
end


-- changing units' damage
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
  if (weaponID and WeaponDefs[weaponID] and WeaponDefs[weaponID].name:find("shockrifle")) then damage = damage * 0.6 end -- nerf Shock Rifle

  -- used to be secret buffs to sprung for being "awesome"
  -- suck on this you cheating scum!!1
  if (UnitDefs[unitDefID].name:find("c47367")) then damage = damage * 1.3 end
  if (attackerDefID and UnitDefs[attackerDefID].name:find("c47367")) then damage = damage * 0.7 end

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
    local cmdDescID = Spring.FindUnitCmdDesc(creepID, CMD_UNIT_AI)
    if (cmdDescID) then
      Spring.GiveOrderToUnit(creepID, CMD_UNIT_AI, {0}, 0) -- disable Rogue autoskirm
      Spring.RemoveUnitCmdDesc(creepID, cmdDescID)
    end
  end,
  
  [creep3] = function() end
}


function gadget:GameFrame(n)
  if (n % 30 == 17) then
    -- healing areas
    for allyteam = 0, 1 do
      local healingAreas = teamData[allyteam+1].healingAreas
      for i = 1, #healingAreas do
        local healingArea = healingAreas[i]
        local units = Spring.GetUnitsInCylinder(healingArea[1], healingArea[2], healingArea.radius)

        for i = 1, #units do
          local unitID = units[i]
          if (Spring.GetUnitAllyTeam(unitID) == allyteam and Spring.GetUnitDefID(unitID) ~= terraunitDefID) then
            local hp, maxHp = Spring.GetUnitHealth(unitID)
            Spring.SetUnitHealth(unitID, math.min(hp + healingArea.healing, maxHp))
          end
        end
      end
    end

    -- water damage
    local unitsToDamage = {}
    for unitID, data in pairs(comsData) do
      local _,height = Spring.GetUnitBasePosition(unitID)
      if (height < 0) then
        data.secondsInWater = data.secondsInWater + 1
        data.secondsOnLand = 0
        if (data.secondsInWater > 10) then
          unitsToDamage[unitID] = (data.secondsInWater - 10) * 3 -- can't call AddUnitDamage here directly
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
    if (n % (5*1350) == 900) then creepcount = math.min(creepcount + 1, maxcreepcount) end

    local teamCreepCounts = {
      [1] = math.max(0, creepcount + creepbalance),
      [2] = math.max(0, creepcount - creepbalance),
    }

    -- prepare list of creeper types to spawn
    --local creepsToSpawn = {}
    --for i = 1, creepcount do
    --  creepsToSpawn[i] = creep1
    --end
    --creepsToSpawn[creepcount+1] = creep2

    wave = wave + 1
    for path = 1, #creeperPathWaypoints do
      local wayPoints = creeperPathWaypoints[path]

      for t = 1, 2 do
        local teamCreepCount = teamCreepCounts[t]

        --for i = 1, #creepsToSpawn do
          --local creepDef = creepsToSpawn[i]
        
        -- creep selection and setup
        -- FIXME: find a less hardcodey way to pick creeps
        for i = 1, teamCreepCount + ((wave%5 == 4 and 2) or 1) do
          local creepDef = creep1
          if (i == teamCreepCount + 2) then creepDef = creep3
          elseif (i > teamCreepCount) then creepDef = creep2
          end

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

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------

local Util_DrawGroundCircle = gl.Utilities.DrawGroundCircle

local allyHealingAreaColor  = { 0.0, 0.0, 1.0, 0.2 }
local enemyHealingAreaColor = { 1.0, 0.0, 0.0, 0.2 }


local function AddMarker(action, x, y, z, teamID)
  if (Spring.GetLocalTeamID() == teamID and not Spring.GetSpectatingState()) then
    Spring.MarkerAddPoint(x, y, z)
    Spring.MarkerErasePosition(x, y, z)
  end
end


function gadget:Initialize()
  gadgetHandler:AddSyncAction("gamemode_dota_addmarker", AddMarker)
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("gamemode_dota_addmarker")
end


function gadget:DrawWorldPreUnit()
  local _,fullView = Spring.GetSpectatingState()

  --for allyteam = 1, #SYNCED.healingAreasData do
  --local healingAreas = SYNCED.healingAreasData[allyteam]
  for allyteam, healingAreas in sipairs(SYNCED.healingAreasData) do
    if (fullView or Spring.GetMyAllyTeamID() + 1 == allyteam) then
      gl.Color(allyHealingAreaColor)
    else
      gl.Color(enemyHealingAreaColor)
    end
    --gl.Texture("bitmaps/PD/repair.tga")
    
    --for i = 1, #healingAreas do
    --local healingArea = healingAreas[i]
    for _, healingArea in sipairs(healingAreas) do
      Util_DrawGroundCircle(healingArea[1], healingArea[2], healingArea.radius)  
    end
    gl.Texture(false)
    gl.Color(1,1,1,1)
  end
end

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
end