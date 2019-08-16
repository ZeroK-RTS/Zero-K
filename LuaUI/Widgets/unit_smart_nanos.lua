--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_smart_nanos.lua
--  brief:   Enables auto reclaim & repair for idle turrets
--  author:  Owen Martindell
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Smart Nanos",
    desc      = "Enables auto reclaim & repair for idle turrets v1.5",
    author    = "TheFatController",
    date      = "22 April, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitDefID        = Spring.GetUnitDefID
local GetAllUnits         = Spring.GetAllUnits
local GetMyTeamID         = Spring.GetMyTeamID
local GetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local GiveOrderToUnit     = Spring.GiveOrderToUnit
local GetUnitHealth       = Spring.GetUnitHealth
local GetUnitsInCylinder  = Spring.GetUnitsInCylinder
local GetUnitPosition     = Spring.GetUnitPosition
local GetCommandQueue     = Spring.GetCommandQueue
local GetFeatureDefID     = Spring.GetFeatureDefID
local GetFeatureResources = Spring.GetFeatureResources
local AreTeamsAllied      = Spring.AreTeamsAllied
local GetFeaturePosition  = Spring.GetFeaturePosition
local GetGameSeconds      = Spring.GetGameSeconds
local GetSelectedUnits    = Spring.GetSelectedUnits
local GetUnitTeam         = Spring.GetUnitTeam
local GetTeamResources    = Spring.GetTeamResources

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UPDATE = 0.5     -- Response time for commands
local NANO_GROUPS = 8  -- Groups to split nanoturrets into
local UPDATE_TICK = 2.5  -- Seconds to check if last order is still the best

local noReclaimList = {}
noReclaimList["Dragon's Teeth"] = 0
noReclaimList["Shark's Teeth"] = 0
noReclaimList["Fortification Wall"] = 0
noReclaimList["Spike"] = 0
noReclaimList["Commander Wreckage"] = 25

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local timeCounter = 0
local order_counter = 0
local pointer = NANO_GROUPS
local nano_pointer = NANO_GROUPS

local stalling = false
local goodEnergy = false
local goodMetal = false

local teamUnits = {}
local buildUnits = {}
local nanoTurrets = {}
local allyUnits = {}
local orderQueue = {}

if (Game.modShortName == "BA") then local BA = true end

local myTeamID

local EMPTY_TABLE = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  myTeamID = GetMyTeamID()
  
   if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then
    Spring.Echo("Smart Nanos widget disabled for spectators")
    widgetHandler:RemoveWidget()
  end
    
  for _,unitID in ipairs(GetAllUnits()) do
    local unitTeam = GetUnitTeam(unitID)
    if (unitTeam == myTeamID) or AreTeamsAllied(unitTeam, myTeamID) then
      local unitDefID = GetUnitDefID(unitID)
      local _, _, _, _, buildProgress = GetUnitHealth(unitID)
      if (buildProgress < 1) then
        widget:UnitCreated(unitID, unitDefID, unitTeam)
      else
        widget:UnitFinished(unitID, unitDefID, unitTeam)
      end
    end
  end
  
  UPDATE = (UPDATE / NANO_GROUPS)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (unitTeam ~= myTeamID) then return end
  buildUnits[unitID] = true
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)

  if UnitDefs[unitDefID].customParams.commtype then myTeamID = GetMyTeamID() end
  
  if (unitTeam == myTeamID) then
  
    buildUnits[unitID] = nil
        
    teamUnits[unitID] = {}
    teamUnits[unitID].unitDefID = unitDefID
    teamUnits[unitID].damaged = false
      
    if (UnitDefs[unitDefID].isBuilder and not UnitDefs[unitDefID].canMove) then
      nanoTurrets[unitID] = {}
      nanoTurrets[unitID].unitDefID = unitDefID
      nanoTurrets[unitID].buildDistance = UnitDefs[nanoTurrets[unitID].unitDefID].buildDistance
      nanoTurrets[unitID].buildDistanceSqr = (UnitDefs[nanoTurrets[unitID].unitDefID].buildDistance *
                                              UnitDefs[nanoTurrets[unitID].unitDefID].buildDistance)
      nanoTurrets[unitID].damaged = false
      local posX,_,posZ = GetUnitPosition(unitID)
      nanoTurrets[unitID].posX = posX
      nanoTurrets[unitID].posZ = posZ
      nanoTurrets[unitID].timeCounter = GetGameSeconds()
      nanoTurrets[unitID].auto = false
      nanoTurrets[unitID].pointer = nano_pointer
      if (nano_pointer < NANO_GROUPS) then
        nano_pointer = nano_pointer + 1
      else
        nano_pointer = 1
      end
      teamUnits[unitID] = nil
    end
  elseif AreTeamsAllied(unitTeam, myTeamID) then
    allyUnits[unitID] = {}
    allyUnits[unitID].unitDefID = unitDefID
    allyUnits[unitID].damaged = false
  end
end

function widget:CommandNotify(id, params, options)
--[[
  local CMD_UPGRADEMEX = math.huge
  
  if BA and (id == 31244) then
    if (#params == 1) then
      local unitDefID = GetUnitDefID(params[1])
      if (unitDefID ~= nil) and (UnitDefs[unitDefID].customParams.ismex) then
        CMD_UPGRADEMEX = 31244
      end
    end
  end
]]--
  
  local selUnits = GetSelectedUnits()
    
  for _,unitID in ipairs(selUnits) do
    if nanoTurrets[unitID] then
      nanoTurrets[unitID].auto = false
      orderQueue[unitID] = nil
    end
  end
    
  --if (id == CMD.RECLAIM) or (id == CMD_UPGRADEMEX) then
  if (id == CMD.RECLAIM) then
    targetUnit = params[1]
    teamUnits[targetUnit] = nil
    for unitID,unitDefs in pairs(nanoTurrets) do
      local cmdID, _, _, cmdParam = Spring.GetUnitCurrentCommand(unitID)
        if (cmdID == CMD.REPAIR) and (cmdParam == targetUnit) then
          if options.shift then
            GiveOrderToUnit(unitID,CMD.STOP, EMPTY_TABLE, 0)
          else
            GiveOrderToUnit(unitID,CMD.RECLAIM,{targetUnit}, 0)
          end
        end
    end
  end
  
  if (id == CMD.REPAIR) then
    targetUnit = params[1]
    if (not teamUnits[targetUnit]) and (not allyUnits[targetUnit]) and (not nanoTurrets[targetUnit])
        and (not buildUnits[targetUnit]) and (GetUnitTeam(targetUnit) == myTeamID) then
      widget:UnitFinished(targetUnit, GetUnitDefID(targetUnit), myTeamID)
    end
    for unitID,unitDefs in pairs(nanoTurrets) do
      local cmdID, _, _, cmdParam = Spring.GetUnitCurrentCommand(unitID)
        if (cmdID == CMD.RECLAIM) and (cmdParam == targetUnit) then
          GiveOrderToUnit(unitID,CMD.REPAIR,{targetUnit}, 0)
        end
    end
  end
end

local function getDistance(x1,z1,x2,z2)
  local dx,dz = x1-x2,z1-z2
  return (dx*dx)+(dz*dz)
end

local function processOrderQueue()
  local newQueue = {}
  for unitID,orders in pairs(orderQueue) do
    if nanoTurrets[unitID] and nanoTurrets[unitID].auto then
      local key = table.concat(orders,"-")
      local map = newQueue[key]
      if not map then
        map = {}
        newQueue[key] = map
      end
      map[unitID] = orders
    else
      orderQueue[unitID] = nil
    end
  end
  for _,unitMap in pairs(newQueue) do
    local anyID = next(unitMap)
    local type, id, params = unitMap[anyID][1], unitMap[anyID][2], unitMap[anyID][3]
    if (type == 1) then
      Spring.GiveOrderToUnitMap(unitMap, CMD.INSERT, {0, id, CMD.OPT_SHIFT, params}, CMD.OPT_ALT)
    else
      Spring.GiveOrderToUnitMap(unitMap, id, {params}, CMD.OPT_SHIFT)
    end
  end
  orderQueue = {}
end

function widget:Update(deltaTime)

  if (next(nanoTurrets) == nil) then return false end

  if (timeCounter > UPDATE) then
    timeCounter = 0
    
    if (GetMyTeamID() ~= myTeamID) then
      Spring.Echo("Smart Nanos widget disabled for team change")
      widgetHandler:RemoveWidget()
      return false
    end
        
    local eCur, eMax = GetTeamResources(myTeamID, "energy")
    local mCur, mMax, _, mInc = GetTeamResources(myTeamID, "metal")
    local ePercent = (eCur / eMax)
    
    if (ePercent < 0.3) and (eCur < 500) then
      stalling = true
      goodEnergy = false
    elseif (ePercent > 0.5) or (eCur >= 500) then
      stalling = false
      if (ePercent > 0.9) and ((eMax - eCur) < 250) then
        goodEnergy = true
      else
        goodEnergy = false
      end
    end
    
    if ((mMax - mCur) < mInc) then goodMetal = true else goodMetal = false end
    
    if next(orderQueue) then
      if (order_counter == NANO_GROUPS) then
        processOrderQueue()
        order_counter = 1
      else
        order_counter = order_counter + 1
      end
    end
    
    if (pointer == NANO_GROUPS) then
      for unitID,_ in pairs(teamUnits) do
        local curH, maxH = GetUnitHealth(unitID)
        if curH and maxH then
          teamUnits[unitID].rHealth = curH
          if (curH < maxH) then
            teamUnits[unitID].damaged = true
          else
            teamUnits[unitID].damaged = false
          end
        else
          teamUnits[unitID] = nil
        end
      end
      for unitID,_ in pairs(allyUnits) do
        local curH, maxH = GetUnitHealth(unitID)
        if curH and maxH then
          allyUnits[unitID].rHealth = curH
          if (curH < maxH) then
            allyUnits[unitID].damaged = true
          else
            allyUnits[unitID].damaged = false
          end
        else
          allyUnits[unitID] = nil
        end
      end
      pointer = 1
    else
      pointer = (pointer + 1)
    end
    
    for unitID,unitDefs in pairs(nanoTurrets) do
      if (unitDefs.pointer == pointer) then
        local curH, maxH = GetUnitHealth(unitID)
        if (curH < maxH) then
          nanoTurrets[unitID].damaged = true
        else
          nanoTurrets[unitID].damaged = false
        end
        
        local cmdID, _, _, cmdParam = Spring.GetUnitCurrentCommand(unitID)
		local cQueueCount = GetCommandQueue(unitID, 0)
     
        local commandMe = false
      
        local prevCommand = nil
        local prevUnit = nil
      
        if (cQueueCount == 0) then
			commandMe = true
			nanoTurrets[unitID].auto = false
		else
	      
	        if (cmdID == CMD.PATROL) and (cQueueCount <= 4) then
	          commandMe = true
	          nanoTurrets[unitID].auto = false
	        end
	        
	        if nanoTurrets[unitID].auto then
	          if (cmdID == CMD.RECLAIM) then
	            prevCommand = CMD.RECLAIM
	            prevUnit = cmdParam
	            if prevUnit < Game.maxUnits then
                local targetDefID = GetUnitDefID(prevUnit)
                if (targetDefID ~= nil) and UnitDefs[targetDefID].canMove then
                  local uX, _, uZ = GetUnitPosition(prevUnit)
                  if (getDistance(unitDefs.posX, unitDefs.posZ, uX, uZ) > unitDefs.buildDistanceSqr) then
                    commandMe = true
                  end
                end
	            end
	          end
	          if (cmdID == CMD.REPAIR) then
	            prevCommand = CMD.REPAIR
	            prevUnit = cmdParam
              local targetDefID = GetUnitDefID(prevUnit)
              if (targetDefID ~= nil) and UnitDefs[targetDefID].canMove then
                local uX, _, uZ = GetUnitPosition(prevUnit)
                if (getDistance(unitDefs.posX, unitDefs.posZ, uX, uZ) > unitDefs.buildDistanceSqr) then
                  commandMe = true
                end
  	          end
  	        end
	        
	          if ((unitDefs.timeCounter + UPDATE_TICK) < GetGameSeconds()) then
	            commandMe = true
	          end
	        end
        end
                    
        if (commandMe) then
          unitDefs.timeCounter = GetGameSeconds()
          
          local ordered = false
                  
          local nearUnits = GetUnitsInCylinder(unitDefs.posX,unitDefs.posZ,unitDefs.buildDistance)
          local nearFeatures = Spring.GetFeaturesInRectangle(unitDefs.posX - (unitDefs.buildDistance+75), unitDefs.posZ - (unitDefs.buildDistance+75),
                                                           unitDefs.posX + (unitDefs.buildDistance+75), unitDefs.posZ + (unitDefs.buildDistance+75))
                                                           
          if (nearUnits ~= nil) and (nearFeatures ~= nil) then
          
            for _,nearUnitID in pairs(nearUnits) do
              if nanoTurrets[nearUnitID] and nanoTurrets[nearUnitID].damaged and (unitID ~= nearUnitID) then
                if (prevCommand ~= CMD.REPAIR) or (prevUnit ~= bestUnit) then
                  orderQueue[unitID] = {1, CMD.REPAIR, nearUnitID}
                end
                ordered = true
                break
              end
            end
              
            if (not ordered) then
              local bestUnit = nil
              local bestStat = math.huge
              local nextUnit = nil
              for _,nearUnitID in pairs(nearUnits) do
                if (teamUnits[nearUnitID] and teamUnits[nearUnitID].damaged) then
                  if (nextUnit == nil) then nextUnit = nearUnitID end
                    if (#UnitDefs[GetUnitDefID(nearUnitID)].weapons > 0) then
                      if (teamUnits[nearUnitID].rHealth < bestStat) then
                      bestUnit = nearUnitID
                      bestStat = teamUnits[nearUnitID].rHealth
                    end
                  end
                end
              end
              
			  --[[
              local nearEnemyID = GetUnitNearestEnemy(unitID,unitDefs.buildDistance)
              if nearEnemyID and (not bestUnit) then
                if (prevCommand ~= CMD.RECLAIM) or (prevUnit ~= nearEnemyID) then
                  orderQueue[unitID] = {1, CMD.RECLAIM, nearEnemyID}
                end
                ordered = true
              end
			  ]]--
            
              if (bestUnit ~= nil) and (not ordered) then
                if (prevCommand ~= CMD.REPAIR) or (prevUnit ~= bestUnit) then
                  orderQueue[unitID] = {1, CMD.REPAIR, bestUnit}
                end
                ordered = true
              elseif (nextUnit ~= nil) and (not ordered) then
                if (prevCommand ~= CMD.REPAIR) or (prevUnit ~= nextUnit) then
                  orderQueue[unitID] = {1, CMD.REPAIR, nextUnit}
                end
                ordered = true
              end
            end

            if (not ordered) or ((not goodEnergy) and (not goodMetal)) then
              local bestFeature = nil
              local metal = false
              for _,featureID in ipairs(nearFeatures) do
                local fX, _, fZ = GetFeaturePosition(featureID)
                local fd = GetFeatureDefID(featureID)
                local radiusSqr = (FeatureDefs[fd].radius * FeatureDefs[fd].radius)
                if (getDistance(unitDefs.posX, unitDefs.posZ, fX, fZ) < (unitDefs.buildDistanceSqr + radiusSqr)) then
                  if (FeatureDefs[fd].reclaimable) and (not noReclaimList[FeatureDefs[fd].tooltip]) then
                    local fm,_,fe  = GetFeatureResources(featureID)
                    if (fm > 0) and (fe > 0) then
                      bestFeature = featureID
                      metal = true
                    elseif (fm > 0) and (not stalling) and (not goodMetal) then
                      bestFeature = featureID
                      metal = true
                    elseif (fe > 0) and (not goodEnergy) and (not metal) then
                      bestFeature = featureID
                    end
                  end
                end
              end
        
              if not metal then
                local bestUnit = nil
                local bestStat = math.huge
                for _,nearUnitID in pairs(nearUnits) do
                  if (allyUnits[nearUnitID] and allyUnits[nearUnitID].damaged) then
                    if (#UnitDefs[GetUnitDefID(nearUnitID)].weapons > 0) then
                      if (allyUnits[nearUnitID].rHealth < bestStat) then
                        bestUnit = nearUnitID
                        bestStat = allyUnits[nearUnitID].rHealth
                      end
                    end
                  end
                end
               
                if (bestUnit ~= nil) then
                  if (prevCommand ~= CMD.REPAIR) or (prevUnit ~= bestUnit) then
                    orderQueue[unitID] = {1, CMD.REPAIR, bestUnit}
                  end
                  ordered = true
                end
              end
          
              if bestFeature and (not ordered) then
                if (prevCommand ~= CMD.RECLAIM) or (prevUnit ~= (bestFeature + Game.maxUnits)) then
                  orderQueue[unitID] = {1, CMD.RECLAIM, (bestFeature + Game.maxUnits)}
                end
                ordered = true
              end
            end
          end
          
          if (nanoTurrets[unitID].auto) and (not ordered) and (cQueueCount > 0) and
             ((cmdID == CMD.REPAIR) or (cmdID == CMD.RECLAIM)) then
            orderQueue[unitID] = {0, cmdID, cmdParam}
          elseif ordered then
            nanoTurrets[unitID].auto = true
          end
        end
      end
    end
  else
    timeCounter = timeCounter + deltaTime
  end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
  widget:UnitFinished(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  buildUnits[unitID] = nil
  nanoTurrets[unitID] = nil
  teamUnits[unitID] = nil
  allyUnits[unitID] = nil
  orderQueue[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, unitTeam)
  buildUnits[unitID] = nil
  nanoTurrets[unitID] = nil
  teamUnits[unitID] = nil
  allyUnits[unitID] = nil
  orderQueue[unitID] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
