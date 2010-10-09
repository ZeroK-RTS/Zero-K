-- $Id: unit_carrier_drones.lua 3291 2008-11-25 00:36:20Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_carrier_drones.lua
--  brief:   Spawns drones for aircraft carriers
--  author:  
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "CarrierDrones",
    desc      = "Spawns drones for aircraft carriers",
    author    = "TheFatConroller",
    date      = "12.01.2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- SYNCED CODE
if (not gadgetHandler:IsSyncedCode()) then
  return
end


--Speed-ups

local GetUnitPosition   = Spring.GetUnitPosition
local CreateUnit        = Spring.CreateUnit
local AddUnitDamage     = Spring.AddUnitDamage
local GiveOrderToUnit   = Spring.GiveOrderToUnit
local GetCommandQueue   = Spring.GetCommandQueue
local SetUnitPosition   = Spring.SetUnitPosition
local SetUnitNoSelect   = Spring.SetUnitNoSelect
local random            = math.random

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local carrierList = {}
local droneList = {}
--local CORE = UnitDefNames['corcarry'].id
local ARM = UnitDefNames['armcarry'].id
local RELOAD_TIME = 15
local MAX_DRONES = 8

local armWeaponID = WeaponDefNames['armcarry_carriertargeting'].id
--local corWeaponID = WeaponDefNames['corcarry_carriertargeting'].id

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function carrier(unitAllyID, droneCount, reload, drone)
  return {unitAllyID = unitAllyID, droneCount = droneCount, reload = reload, drone = drone}
end

local function NewDrone(unitID, droneName)
  
  local x, y, z = GetUnitPosition(unitID)
  local angle = math.rad(random(1,360))
  local xS = (x + (math.sin(angle) * 20))
  local zS = (z + (math.cos(angle) * 20))
  local droneID = CreateUnit(droneName,x,y,z,1,carrierList[unitID].unitAllyID)
  carrierList[unitID].reload = RELOAD_TIME
  carrierList[unitID].droneCount = (carrierList[unitID].droneCount + 1)
  
  SetUnitPosition(droneID, xS, zS, true)
  GiveOrderToUnit(droneID, CMD.MOVE_STATE, { 2 }, {})
  GiveOrderToUnit(droneID, CMD.IDLEMODE, { 0 }, {})
  GiveOrderToUnit(droneID, CMD.AUTOREPAIRLEVEL, { 3 }, {})
  GiveOrderToUnit(droneID, CMD.FIGHT,  {(x + (random(0,600) - 300)), 60, (z + (random(0,600) - 300))}, {""})
  GiveOrderToUnit(droneID, CMD.GUARD, {unitID} , {"shift"})
    
  SetUnitNoSelect(droneID,true)
  
  droneList[droneID] = unitID
  
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (carrierList[unitID] ~= nil) then
    for droneID,carrier in pairs(droneList) do
      if (carrier == unitID) then
        droneList[droneID] = nil
        AddUnitDamage(droneID,3000)
      end
    end
    carrierList[unitID] = nil
  elseif (droneList[unitID] ~= nil) then
    for i,_ in pairs(carrierList) do
      if (droneList[unitID] == i) then
        carrierList[i].droneCount = (carrierList[i].droneCount - 1)
        droneList[unitID] = nil
        return
      end
    end
  end
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  if (unitDefID == ARM) then
    carrierList[unitID] = carrier(unitTeam, 0, RELOAD_TIME, "carrydrone", 0)
  end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
  if (droneList[unitID] ~= nil) then 
    return false
  else
    if (carrierList[unitID] ~= nil) then
      gadget:UnitDestroyed(unitID, unitDefID, oldTeam)
      gadget:UnitFinished(unitID, unitDefID, newTeam)
    end    
    return true
  end
end

function gadget:Explosion(weaponID, px, py, pz, ownerID)
  if ((weaponID == armWeaponID) or (weaponID == corWeaponID)) then
    if (carrierList[ownerID] ~= nil) then
      for droneID,carrier in pairs(droneList) do
        if (carrier == ownerID) then
          local cQueue = GetCommandQueue(droneID)
          local scrambled = false
	        for _, elem in ipairs(cQueue) do
		        if (elem.id == CMD.FIGHT) then
			        scrambled = true
			        break
		        end
	        end
	        if not scrambled then
            droneList[droneID] = nil
            GiveOrderToUnit(droneID, CMD.FIGHT, {(px + (random(0,200) - 100)), (py+120), (pz + (random(0,200) - 100))} , {""})
            GiveOrderToUnit(droneID, CMD.GUARD, {ownerID} , {"shift"})
            droneList[droneID] = ownerID
          end
        end   
      end
    end    
  end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (droneList[unitID] ~= nil) then
    return false
  else
    return true
  end
end

function gadget:GameFrame(n)
  if (((n+1) % 32) < 0.1) then
    for i,_ in pairs(carrierList) do
      if (carrierList[i].reload > 0) then
        carrierList[i].reload = (carrierList[i].reload - 1)
      elseif (carrierList[i].droneCount < MAX_DRONES) then
        NewDrone(i,carrierList[i].drone)   
        if (carrierList[i].droneCount < MAX_DRONES) then 
          NewDrone(i,carrierList[i].drone)   
        end
      end
    end
  end
end

function gadget:Initialize()
	Script.SetWatchWeapon(armWeaponID, true)
	--Script.SetWatchWeapon(corWeaponID, true)
end
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
