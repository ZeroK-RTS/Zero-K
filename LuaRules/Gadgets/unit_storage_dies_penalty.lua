-- $Id: unit_storage_dies_penalty.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file: unit_storage_dies_penalty.lua
--  brief: Gives realisitic penalties for destruction of economy buildings and storage
--  author: TheFatController
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Storage Dies Penalty",
    desc      = "Gives penalties for destruction of economy buildings and storage",
    author    = "TheFatController",
    date      = "June 23, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -5,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetUnitResources = Spring.GetUnitResources
local UseTeamResource = Spring.UseTeamResource
local GetTeamResources = Spring.GetTeamResources
local GetUnitDefID = Spring.GetUnitDefID

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

local function deadUnit(team, penalty)
  return { team = team, penalty = penalty}
end

local deadList = {}

function gadget:GameFrame(n)
  for i,v in pairs(deadList) do
    if (GetUnitDefID(i) == nil) then
      local eCur = GetTeamResources(v.team, "energy")
      UseTeamResource(v.team, "e", math.min(v.penalty, eCur))
      deadList[i] = nil
    end
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)

  local _, _, em = GetUnitResources(unitID)
  local eStore = UnitDefs[unitDefID].energyStorage
  local mStore = UnitDefs[unitDefID].metalStorage
  
  if (em > 0) then
    
    deadList[unitID] = deadUnit(unitTeam, em)
    
  end
  
  if (eStore > 0) then
    
     local eCur, eMax = GetTeamResources(unitTeam, "energy")
     
     local stored = (eStore / eMax)
     
     UseTeamResource(unitTeam, "e", (eCur * stored))
     
  end
  
  if (mStore > 0) then
    
     local mCur, mMax = GetTeamResources(unitTeam, "metal")
     
     local stored = (mStore / mMax)
     
     UseTeamResource(unitTeam, "m", (mCur * stored))
     
  end
  
end

--------------------------------------------------------------------------------
--  END SYNCED
--------------------------------------------------------------------------------
end
