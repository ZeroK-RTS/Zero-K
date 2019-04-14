-- $Id: cmd_no_duplicate_orders.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    cmd_no_duplicate_orders.lua
--  brief:   Blocks duplicate Attack and Repair/Build orders
--  author:  Owen Martindell
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "NoDuplicateOrders",
    desc      = "Blocks duplicate Attack and Repair/Build orders 1.1",
    author    = "TheFatController",
    date      = "16 April, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetSelectedUnits = Spring.GetSelectedUnits
local GetCommandQueue  = Spring.GetCommandQueue
local GetUnitPosition  = Spring.GetUnitPosition
local GiveOrderToUnit  = Spring.GiveOrderToUnit
local GetUnitHealth    = Spring.GetUnitHealth

local buildList = {}

function widget:Initialize()
  if (Spring.GetSpectatingState() or Spring.IsReplay()) and (not Spring.IsCheatingEnabled()) then 
	widgetHandler:RemoveWidget() 
  end
  local myTeam = Spring.GetMyTeamID()
  local units = Spring.GetTeamUnits(myTeam)
  for i=1,#units do
    local unitID = units[i]
    local buildProgress = select(5, GetUnitHealth(unitID))
    if (buildProgress < 1) then widget:UnitCreated(unitID) end    
  end
end

local function toLocString(posX,posY,posZ)
  return (posX .. "_" .. posZ)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  local locString = toLocString(GetUnitPosition(unitID))
  buildList[locString] = unitID
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
  local locString = toLocString(GetUnitPosition(unitID))
  buildList[locString] = nil
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  local locString = toLocString(GetUnitPosition(unitID))
  buildList[locString] = nil
end

function widget:CommandNotify(id, params, options)
  if (options.coded == 16) then
    if (id == CMD.REPAIR) then
      local selUnits = GetSelectedUnits()
      local blockUnits = {}
      for _,unitID in ipairs(selUnits) do
        local cmdID, _, _, cmdParam1, _, cmdParam3 = Spring.GetUnitCurrentCommand(unitID)
        if cmdID then
          if (cmdID < 0) and (params[1] == buildList[toLocString(cmdParam1, 0, cmdParam3)]) then
            blockUnits[unitID] = true
          elseif (cmdID == CMD.REPAIR) and (params[1] == cmdParam1) then
            blockUnits[unitID] = true
          end
        end
      end
      if next(blockUnits) then
        for _,unitID in ipairs(selUnits) do
          if not blockUnits[unitID] then
            GiveOrderToUnit(unitID, id, params, options)
          else
            local cQueue = GetCommandQueue(unitID, -1)
            for _,v in ipairs(cQueue) do
              if (v.tag ~= cQueue[1].tag) then
                GiveOrderToUnit(unitID,v.id,v.params, CMD.OPT_SHIFT)
              end
            end
          end
        end
        return true
      else
        return false
      end
    end
    if (id == CMD.ATTACK) then
      local selUnits = GetSelectedUnits()
      local blockUnits = {}
      for i=1, #selUnits do
        local unitID = selUnits[i]
        local cmdID, _, _, cmdParam = Spring.GetUnitCurrentCommand(unitID)
        if cmdID and (params[1] == cmdParam) then
          blockUnits[unitID] = true
        end
      end -- for
      if next(blockUnits) then
        for i=1, #selUnits do
          local unitID = selUnits[i]
          if not blockUnits[unitID] then
            GiveOrderToUnit(unitID, id, params, options)
          else
            local cQueue = GetCommandQueue(unitID, -1)
            for j=1, #cQueue do
              local v = cQueue[j]
              if (v.tag ~= cQueue[1].tag) then
                GiveOrderToUnit(unitID,v.id,v.params, CMD.OPT_SHIFT)
              end
            end -- for
          end -- if ... else
        end -- for
        return true
      else -- if
        return false
      end  
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
