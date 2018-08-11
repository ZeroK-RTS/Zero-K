-- $Id: cmd_unit_mover.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    cmd_unit_mover.lua
--  brief:   Allows combat engineers to use repeat when building mobile units (use 2 or more build spots)
--  author:  Owen Martindell
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Unit Mover",
    desc      = "Allows combat engineers to use repeat when building mobile units (use 2 or more build spots)",
    author    = "TheFatController",
    date      = "Mar 20, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------

local GetCommandQueue = Spring.GetCommandQueue
local GetPlayerInfo = Spring.GetPlayerInfo
local GetUnitPosition = Spring.GetUnitPosition
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID

--------------------------------------------------------------------------------

local countDown = -1
local DELAY = 0.2
local moveUnits = {}
local myID = 0

local function checkSpec()
  local _, _, spec = GetPlayerInfo(myID)
  if spec then
    widgetHandler:RemoveWidget()
  end
end

function widget:Initialize()
 myID = Spring.GetMyPlayerID()
 checkSpec()
end

function widget:Update(deltaTime)
 if (countDown == -1) then
   return
 else
   countDown = countDown + deltaTime
 end

 if (countDown > DELAY) then
   for unitID,_ in pairs(moveUnits) do
     local cQueue = GetCommandQueue(unitID, 1)
     if (table.getn(cQueue) == 0) then
       local x, y, z = GetUnitPosition(unitID)
       if (math.random(1,2) == 1) then
         x = x + math.random(50,100)
       else
         x = x - math.random(50,100)
       end
       if (math.random(1,2) == 1) then
         z = z + math.random(50,100)
       else
         z = z - math.random(50,100)
       end
       GiveOrderToUnit(unitID, CMD.FIGHT,  { x, y, z},  0)
     end
   end
   moveUnits = {}
   countDown = -1
 end
end

function widget:UnitFromFactory(unitID, unitDefID, unitTeam, factID, factDefID, userOrders)                          
  for uID,_ in pairs(moveUnits) do
    if (uID == unitID) then
      table.remove(moveUnits,uID)
      break
    end
  end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
 if (unitTeam ~= GetMyTeamID()) then
   return
 end
   
 local ud = UnitDefs[unitDefID]
 if (ud and (not ud.customParams.commtype) and not ud.isImmobile) then
   checkSpec()
   moveUnits[unitID] = true
   countDown = 0
 end
end

--------------------------------------------------------------------------------
