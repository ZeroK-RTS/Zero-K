function gadget:GetInfo()
  return {
    name    = "DotA",
    desc    = "DotA Mode",
    author  = "Sprung, Rafal, KingRaptor",
    date    = "25/08/2012",
    license = "PD",
    layer   = 10, -- run after most gadgets
    enabled = true,
  }
end

local versionNumber = "v0.29"

if (Spring.GetModOptions().zkmode ~= "dota") then
  return
end


local mapConfig = include("LuaRules/Configs/dota_map_defs.lua")

if (not mapConfig) then
  --gadgetHandler:RemoveGadget() -- doesn't work before gadget:Initialize()
  return
end


if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")

local CMD_FIGHT     = CMD.FIGHT
local CMD_OPT_SHIFT = CMD.OPT_SHIFT
local squareSize      = Game.squareSize
local framesPerSecond = Game.gameSpeed
local random = math.random


local unitConfig = include("LuaRules/Configs/dota_unit_defs.lua")
local hqDef      = unitConfig.hqDef
local turretDefs = unitConfig.turretDefs
local creepDefs  = unitConfig.creepDefs
local mc                   = mapConfig
local teamData             = mapConfig.teamData
local creeperPathWaypoints = mapConfig.creeperPathWaypoints


local HQ = {}

local team1 = Spring.GetTeamList(0)[1]
local team2 = Spring.GetTeamList(1)[1]
local teams = { team1, team2 }

local rewardEnergyMult = 0.5

local blockedCmds = {
  [CMD.RECLAIM]   = true,
  [CMD.RESURRECT] = true,
--[CMD_AREA_MEX]  = true,
  [CMD_RAMP]  = true,
  [CMD_LEVEL] = true,
  [CMD_RAISE] = true,
}

local disabledCmdArray = { disabled = true }

local terraunitDefID = UnitDefNames["terraunit"].id

local creepcount    = mc.startingCreepCount -- current creep count per wave
local creepbalance  = 0
local creepWave     = 0


local protectedStructures = {}

do
  local defID = UnitDefNames[ hqDef.unitName ].id
  protectedStructures[defID] = true

  for _, turretDef in pairs(turretDefs) do
    defID = UnitDefNames[ turretDef.unitName ].id
    protectedStructures[defID] = true
  end
end


local comLevelAfterRespawn = {
  [0] = 0,
  [1] = 0,
  [2] = 0,
  [3] = 1,
  [4] = 2,
  [5] = 2,
}


local creeperOrderArrays = {}


do
  local healingAreasData = {}
  local debugCircles     = {}
  local debugLines       = {}


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

  local function AddDebugCircle (coordsTable, circleRadius, circleColor)
    debugCircles[#debugCircles + 1] = {
      [1]    = coordsTable[1],
      [2]    = coordsTable[3],
      radius = circleRadius,
      color  = circleColor,
    }
  end


  for t = 1, #teams do
    local td = teamData[t]

    AlignToSquareSize(td.hqPosition)
    Point2Dto3D(td.hqPosition)
    td.hqPosition[2] = td.hqPosition[2] + hqDef.terraHeight

    Point2Dto3D(td.djinnSpawnPoint)
    Point2Dto3D(td.comRespawnPoint)
    AddDebugCircle(td.djinnSpawnPoint, 50, "djinnSpawn")
    AddDebugCircle(td.comRespawnPoint, 50, "comRespawn")

    healingAreasData[t] = td.healingAreas

    for i = 1, #creeperPathWaypoints do
      Point2Dto3D(td.creeperSpawnPoints[i])
      AddDebugCircle(td.creeperSpawnPoints[i], 50, "creeperSpawn")
    end

    for i = 1, #td.turretPositions do
      AlignToSquareSize(td.turretPositions[i])
    end
  end

  for i = 1, #creeperPathWaypoints do
    local waypoints = creeperPathWaypoints[i]

    local team1Orders = {}
    local team2Orders = {}

    local points = {}
    points[1]              = teamData[1].creeperSpawnPoints[i]
    points[#waypoints + 2] = teamData[2].creeperSpawnPoints[i]

    local n = #waypoints + 1
    for w = 1, #waypoints do
      Point2Dto3D(waypoints[w])

      team1Orders[w]   = { CMD_FIGHT, waypoints[w], CMD_OPT_SHIFT }
      team2Orders[n-w] = team1Orders[w]

      AddDebugCircle(waypoints[w], 20, "creeperPath")
      points[w+1] = waypoints[w]
    end

    table.insert(team1Orders, { CMD_FIGHT, teamData[2].hqPosition, CMD_OPT_SHIFT } )
    table.insert(team2Orders, { CMD_FIGHT, teamData[1].hqPosition, CMD_OPT_SHIFT } )

    creeperOrderArrays[i] = { team1Orders, team2Orders }

    debugLines[#debugLines + 1] = {
      color  = "creeperPath",
      points = points,
    }
  end


  -- make these tables visible from unsynced
  _G.healingAreasData = healingAreasData
  _G.debugCircles     = debugCircles
  _G.debugLines       = debugLines
end


local comsData = {}


local function RandomVector2D(maxLength, minLength)
  local x, z, sqLength
  local sqMaxLength = maxLength * maxLength

  if (minLength)  then
    minLength = math.min(minLength, maxLength - 0.999)
    local sqMinLength = minLength * minLength

    repeat
      x = random(-maxLength, maxLength)
      z = random(-maxLength, maxLength)
      sqLength = x*x + z*z
    until (sqMinLength <= sqLength and sqLength <= sqMaxLength)
  else
    repeat
      x = random(-maxLength, maxLength)
      z = random(-maxLength, maxLength)
      sqLength = x*x + z*z
    until (sqLength <= sqMaxLength)
  end

  return x, z
end


local function CreateUnitNearby(unitDef, spawnPoint, teamID, markerType)
  local vx, vz = RandomVector2D(50)
  local x, z = spawnPoint[1] + vx, spawnPoint[3] + vz
  local y = Spring.GetGroundHeight(x, z)
  local unitID = Spring.CreateUnit(unitDef, x, y, z, spawnPoint.facing, teamID)

  if (markerType) then
    SendToUnsynced("gamemode_dota_addmarker", x, y, z, teamID, markerType)
  end
  return unitID
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  if (UnitDefs[unitDefID].customParams.commtype) then
    comsData[unitID] = {
      originalTeam    = unitTeam,
      secondsInWater  = 0,
      secondsOnLand   = 0,
      lastDamageDefID = 0,
    }

    local weapons = UnitDefs[unitDefID].weapons
    for w = 1, #weapons do
      local weaponDefID = weapons[w].weaponDef

      if (WeaponDefs[weaponDefID] and WeaponDefs[weaponDefID].name:find("shockrifle")) then -- nerf Shock Rifle
        local originalRange           = Spring.GetUnitWeaponState(unitID, w - 1, "range")
        local originalProjectileSpeed = Spring.GetUnitWeaponState(unitID, w - 1, "projectileSpeed")

        Spring.SetUnitWeaponState(unitID, w - 1, {
          range           = 0.8 * originalRange,
          projectileSpeed = 0.8 * originalProjectileSpeed,
        })
      end
    end



    --[[ -- build options removal is now handled in unitdefs_post
    for _, buildoptionID in ipairs(UnitDefs[unitDefID].buildOptions) do
      local cmdDescID = Spring.FindUnitCmdDesc(unitID, -buildoptionID)
      if (cmdDescID) then
        Spring.EditUnitCmdDesc(unitID, cmdDescID, disabledCmdArray) -- disable buildoptions
      end
    end
    --]]
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
  if (Spring.IsGameOver()) then return end

  _,_,_,_,_,allyteam = Spring.GetTeamInfo(unitTeam)
  if (unitID == HQ[1] or unitID == HQ[2]) then
    local winnerAllyTeam = (unitID == HQ[2]) and 0 or 1

    for _,allyteam in ipairs(Spring.GetAllyTeamList()) do
      if (allyteam ~= winnerAllyTeam) then
        GG.DestroyAlliance(allyteam)
      end
    end

    Spring.GameOver({winnerAllyTeam})
  elseif (UnitDefs[unitDefID].name == turretDefs["turret3"].unitName) then
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
    CreateUnitNearby("amphtele", teamData[allyteam+1].comRespawnPoint, unitTeam, "comRespawn")
  elseif (UnitDefs[unitDefID].customParams.commtype) then
    if (GG.wasMorphedTo[unitID]) then
      local newUnitID = GG.wasMorphedTo[unitID]
      comsData[newUnitID] = comsData[unitID]
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

      if (Spring.GetUnitHealth(unitID) > 0) then -- was self-ded
        damageDefID = -6
      end

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

    -- respawn commander
    local comName    = UnitDefs[unitDefID].name -- the com type that died
    local comNameNew = GG.startUnits[ comsData[unitID].originalTeam ] -- new com type selected by user
    local baseComName    = comName   :sub(1, -2)
    local baseComNameNew = comNameNew:sub(1, -2)

    if (baseComNameNew == baseComName) then
      local comLevel = tonumber(comName:sub(-1))
      comLevel = tostring(comLevelAfterRespawn[comLevel])
      --comLevel = tostring(math.max(comLevel - 2, 0)) -- respawned com will be 2 levels lower

      if (UnitDefNames[baseComName .. comLevel]) then
        comName = baseComName .. comLevel
      elseif (comLevel == "0" and UnitDefNames[baseComName .. "1"]) then
        comName = baseComName .. "1"
      end
    else
      comName = comNameNew
    end

    local newUnitID = CreateUnitNearby(comName, teamData[allyteam+1].comRespawnPoint, unitTeam, "comRespawn")

    comsData[newUnitID].originalTeam = comsData[unitID].originalTeam
    comsData[unitID] = nil
  end
end


function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
  if (creepDefs[ UnitDefs[unitDefID].name ]) then
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


function gadget:GamePreload()
  local function hqHeightMapFunc(centerX, centerZ, terraHeight)
    local centerHeight = Spring.GetGroundHeight(centerX, centerZ)
    local wantedHeight
    local size = 144

    for z = -size, size, squareSize do
      for x = -size, size, squareSize do
        wantedHeight = centerHeight + math.min((size - math.max(math.abs(x), math.abs(z))) * (terraHeight / 64), terraHeight)
        if (wantedHeight > Spring.GetGroundHeight(centerX + x, centerZ + z)) then
          Spring.SetHeightMap(centerX + x, centerZ + z, wantedHeight)
        end
      end
    end
  end

  for i = 1, #teams do
    local td = teamData[i]

    local spawnPoint = td.hqPosition
    Spring.SetHeightMapFunc(hqHeightMapFunc, spawnPoint[1], spawnPoint[3], hqDef.terraHeight)
    local hq = Spring.CreateUnit(hqDef.unitName, spawnPoint[1], spawnPoint[2], spawnPoint[3], 0, teams[i])
    HQ[i] = hq

    Spring.SetUnitNoSelect(hq, true)
    Spring.SetUnitResourcing(hq, "uue", 75) -- use 75 E to offset t3 turrets
    Spring.SetUnitSensorRadius(hq, "seismic", 4000)

    for _, turretData in ipairs(td.turretPositions) do
      local turretName = turretData[3]
      local turretDef  = turretDefs[turretName]

      if (turretDef.spawnFunction) then
        turretDef.spawnFunction (turretData[1], turretData[2], teams[i])
      end
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
  if (cmdID == CMD.INSERT and cmdParams[2]) then
    cmdID = cmdParams[2]

    local t = {}
    for i = 4, #cmdParams do
      t[i-3] = cmdParams[i]
    end
    cmdParams = t
  end

  if (((cmdID == CMD.CLOAK or cmdID == CMD_CLOAK_SHIELD) and cmdParams[1] == 1) or -- block cloak
    blockedCmds[cmdID] or cmdID < 0) then -- block reclaim, rez, build and terra
    return false
  end

  if ((cmdID == CMD.ATTACK or cmdID == CMD.MANUALFIRE) and #cmdParams == 1) then -- block attack orders on friendly HQs and turrets
    local targetID    = cmdParams[1]
    local targetDefID = Spring.GetUnitDefID(targetID)
    local targetTeam  = Spring.GetUnitTeam(targetID)

    if (targetDefID and protectedStructures[targetDefID] and Spring.AreTeamsAllied(unitTeam, targetTeam)) then
      return false
    end
  end

  return true
end


function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, attackerID, attackerDefID, attackerTeam)
  if (protectedStructures[unitDefID] and attackerTeam and Spring.AreTeamsAllied(unitTeam, attackerTeam)) then
    -- block friendly damage to HQs and turrets
    -- blocks self-d and normal unit explosion damage only when the explosion is very close so that the damage is dealt the same frame
    return 0
  end

  -- changing units' damage
  if (weaponDefID and WeaponDefs[weaponDefID] and WeaponDefs[weaponDefID].name:find("shockrifle")) then damage = damage * 0.6 end -- nerf Shock Rifle

  -- used to be secret buffs to sprung for being "awesome"
  -- suck on this you cheating scum!!1
  if (UnitDefs[unitDefID].name:find("c47367")) then damage = damage * 1.3 end
  if (attackerDefID and UnitDefs[attackerDefID].name:find("c47367")) then damage = damage * 0.7 end

  return damage
end


function gadget:GameFrame(n)
  if (Spring.IsGameOver()) then return end

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
        if (data.secondsInWater > 5) then
          unitsToDamage[unitID] = (data.secondsInWater - 5) * 3 -- can't call AddUnitDamage here directly
        end
      else
        data.secondsOnLand = data.secondsOnLand + 1
        if (data.secondsInWater > 0) then
          if (data.secondsOnLand < 15) then
            data.secondsInWater = data.secondsInWater - 1
          elseif (data.secondsOnLand == 15) then
            data.secondsInWater = 0
          end
        end
      end
    end
    for unitID, damage in pairs(unitsToDamage) do
      Spring.AddUnitDamage(unitID, damage, 0, -1, -5) -- deal water damage
    end
  end

  if (n >= mc.creepSpawnDelay and (n - mc.creepSpawnDelay) % mc.creepSpawnPeriod == 0) then
    creepWave = creepWave + 1

    if (creepWave > 1 and creepWave % 5 == 1) then
      creepcount = math.min(creepcount + 1, mc.maxCreepCount)
    end

    -- prepare list of creeper types to spawn
    local teamCreepCounts = {
      [1] = {
        { "creep1", math.max(0, creepcount + creepbalance) },
        { "creep2", 1 },
      },
      [2] = {
        { "creep1", math.max(0, creepcount - creepbalance) },
        { "creep2", 1 },
      },
    }
    if (creepWave % 5 == 4) then
      table.insert(teamCreepCounts[1], { "creep3", 1 } )
      table.insert(teamCreepCounts[2], { "creep3", 1 } )
    end

    for path = 1, #creeperPathWaypoints do
      local creeperOrderArray = creeperOrderArrays[path]

      for t = 1, 2 do
        local orderArray     = creeperOrderArray[t]
        local teamCreepCount = teamCreepCounts[t]

        for c = 1, #teamCreepCount do
          local creepName  = teamCreepCount[c][1]
          local creepDef   = creepDefs[creepName]
          local creepCount = teamCreepCount[c][2]
          local creepGroup = {}

          -- spawn and setup creeps
          for i = 1, creepCount do
            local creepID = CreateUnitNearby(creepDef.unitName, teamData[t].creeperSpawnPoints[path], teams[t])

            if (creepDef.setupFunction) then
              creepDef.setupFunction (creepID)
            end
            Spring.SetUnitNoSelect(creepID, true) -- creeps uncontrollable

            creepGroup[#creepGroup + 1] = creepID
          end

          Spring.GiveOrderArrayToUnitArray(creepGroup, orderArray) -- make creeps move through waypoints
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

local glDrawGroundCircle    = gl.DrawGroundCircle
local Util_DrawGroundCircle = gl.Utilities.DrawGroundCircle


local lastMarkerFrames = {}

local drawDebugInfo = false

local allyHealingAreaColor  = { 0.0, 0.0, 1.0, 0.2 }
local enemyHealingAreaColor = { 1.0, 0.0, 0.0, 0.2 }

local debugColors = {
  ["comRespawn"]   = { 0.2, 0.2, 1.0, 1.0 },
  ["djinnSpawn"]   = { 0.0, 0.8, 0.8, 1.0 },
  ["creeperSpawn"] = { 0.9, 0.2, 0.0, 1.0 },
  ["creeperPath"]  = { 0.9, 0.2, 0.0, 0.7 },
}


local debugLines = {}

for l, debugLine in sipairs(SYNCED.debugLines) do -- need to recreate SYNCED.debugLines table because gl.Shape apparently doesn't like synced tables
  local points = {}

  for p, point in sipairs(debugLine.points) do
    points[p] = {
      v = {
        point[1],
        point[2] + 5,
        point[3],
      },
    }
  end

  debugLines[l] = {
    color  = debugLine.color,
    points = points,
  }
end


local function AddMarker(action, x, y, z, teamID, markerType)
  if (Spring.GetLocalTeamID() == teamID and not Spring.GetSpectatingState()) then
    local frame = Spring.GetGameFrame()

    if (not lastMarkerFrames[markerType] or lastMarkerFrames[markerType] + 30 <= frame) then
      Spring.MarkerAddPoint(x, y, z)
      Spring.MarkerErasePosition(x, y, z)
      lastMarkerFrames[markerType] = frame
    end
  end
end


local function ToggleDebugInfo (cmd, line, words, playerID)
  drawDebugInfo = not drawDebugInfo
end


function gadget:Initialize()
  gadgetHandler:AddSyncAction("gamemode_dota_addmarker", AddMarker)

  gadgetHandler:AddChatAction("dota_debug", ToggleDebugInfo, "toggles DOTA gadget debug info drawing")
  --Script.AddActionFallback("dota_debug" .. ' ', "toggles DOTA gadget debug info drawing") -- synced only
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("gamemode_dota_addmarker")

  gadgetHandler:RemoveChatAction("dota_debug")
  --Script.RemoveActionFallback("dota_debug") -- synced only
end


function gadget:DrawWorldPreUnit()
  local _,fullView = Spring.GetSpectatingState()

  --gl.Texture("bitmaps/PD/repair.tga")

  --for allyteam = 1, #SYNCED.healingAreasData do
  --local healingAreas = SYNCED.healingAreasData[allyteam]
  for allyteam, healingAreas in sipairs(SYNCED.healingAreasData) do
    if (fullView or Spring.GetMyAllyTeamID() + 1 == allyteam) then
      gl.Color(allyHealingAreaColor)
    else
      gl.Color(enemyHealingAreaColor)
    end

    --for i = 1, #healingAreas do
    --local healingArea = healingAreas[i]
    for _, healingArea in sipairs(healingAreas) do
      Util_DrawGroundCircle(healingArea[1], healingArea[2], healingArea.radius)
    end
  end

  --gl.Texture(false)

  if (drawDebugInfo) then
    gl.LineWidth(3.0)

    for _, debugCircle in sipairs(SYNCED.debugCircles) do
      gl.Color(debugColors[debugCircle.color])

      glDrawGroundCircle(debugCircle[1], 0, debugCircle[2], debugCircle.radius, 24)
      --Util_DrawGroundCircle(debugCircle[1], debugCircle[2], debugCircle.radius)
    end

    for _, debugLine in ipairs(debugLines) do
      gl.Color(debugColors[debugLine.color])
      gl.Shape(GL.LINE_STRIP, debugLine.points)
    end

    gl.LineWidth(1.0)
  end

  gl.Color(1,1,1,1)
end

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
end