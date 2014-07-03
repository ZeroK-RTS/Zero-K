-- $Id: unit_stealth.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  THIS ISN'T THE ORIGINAL! (it contains a bugfix by jK)
--
--  file:    unit_stealth.lua
--  brief:   adds active unit stealth capability
--  author:  Dave Rodgers (bugfixed by jK)
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "UnitStealth",
    desc      = "Adds active unit stealth capability",
    author    = "trepan (bugfixed by jK)",
    date      = "May 02, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  FIXME: (TODO)
--  - don't allow state changes during pauses (tied to the above)
--
--------------------------------------------------------------------------------

include("LuaRules/Configs/customcmds.h.lua")


--------------------------------------------------------------------------------
--  COMMON
--------------------------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then
	return
end
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------

--
--  speed-ups
--

local SetUnitStealth    = Spring.SetUnitStealth
local UseUnitResource   = Spring.UseUnitResource
local SetUnitRulesParam = Spring.SetUnitRulesParam


--------------------------------------------------------------------------------

local stealthDefs = {}

local stealthUnits = {} -- make it global in Initialize()

local wantingUnits = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ValidateStealthDefs(mds)
  local newDefs = {}
  for udName,stealthData in pairs(mds) do
    local ud = UnitDefNames[udName]
    if (not ud) then
      Spring.Log(gadget:GetInfo().name, LOG.WARNING, 'Bad stealth unit type: ' .. udName)
    else
      local newData = {}
      newData.draw   = stealthData.draw
      newData.init   = stealthData.init
      newData.energy = stealthData.energy or 0
      newData.delay  = stealthData.delay or 30
	  newData.tieToCloak = stealthData.tieToCloak
      newDefs[ud.id] = newData
--[[
      print('Stealth ' .. udName)
      print('  init   = ' .. tostring(newData.init))
      print('  delay  = ' .. tostring(newData.delay))
      print('  energy = ' .. tostring(newData.energy))
--]]
    end
  end
  return newDefs
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function AddStealthUnit(unitID, stealthDef)

  local stealthData = {
    id      = unitID,
    def     = stealthDef,
    draw    = stealthDef.draw,
    active  = stealthDef.init,
    energy  = stealthDef.energy / 32,
	tieToCloak = stealthDef.tieToCloak
  }
  stealthUnits[unitID] = stealthData
  if (stealthDef.init) then
    wantingUnits[unitID] = stealthData
    SetUnitRulesParam(unitID, "stealth", 2)
  else
    SetUnitRulesParam(unitID, "stealth", 0)
  end
end

--------------------------------------------------------------------------------

function gadget:Initialize()
  -- get the stealthDefs
  stealthDefs = include("LuaRules/Configs/stealth_defs.lua")
  if (not stealthDefs) then
    gadgetHandler:RemoveGadget()
    return
  end

  stealthDefs = ValidateStealthDefs(stealthDefs)
  -- add the Stealth command to existing units
  for _,unitID in ipairs(Spring.GetAllUnits()) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local stealthDef = stealthDefs[unitDefID]
    if (stealthDef) then
      AddStealthUnit(unitID, stealthDef)
    end
  end
end

--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
  local stealthDef = stealthDefs[unitDefID]
  if (not stealthDef) then
    return
  end
  AddStealthUnit(unitID, stealthDef)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  stealthUnits[unitID] = nil
  wantingUnits[unitID] = nil
end

function gadget:UnitTaken(unitID, unitDefID, unitTeam)
  local stealthUnit = stealthUnits[unitID]
  if (stealthUnit) then
    local stealthDef = stealthUnit.def
    if (stealthDef.init) then
      wantingUnits[unitID] = stealthData
      SetUnitRulesParam(unitID, "stealth", 2)
    else
      wantingUnits[unitID] = nil
      SetUnitRulesParam(unitID, "stealth", 0)
    end
  end
end

--------------------------------------------------------------------------------

function gadget:GameFrame()
  for unitID, stealthData in pairs(wantingUnits) do
    if (stealthData.delay) then
      stealthData.delay = stealthData.delay - 1
      if (stealthData.delay <= 0) then
        stealthData.delay = nil
      end
    else
      local newState
      if (Spring.GetUnitIsStunned(unitID) or (Spring.GetUnitRulesParam(unitID, "disarmed") == 1)) then
        newState = false
      else
        newState = UseUnitResource(unitID, 'e', stealthData.energy)
      end
      if (stealthData.active ~= newState) then
        stealthData.active = newState
        SetUnitStealth(unitID, stealthData.active)
        if (newState) then
          SetUnitRulesParam(unitID, "stealth", 2)
        else
          SetUnitRulesParam(unitID, "stealth", 1)
          stealthData.delay = stealthData.def.delay
        end
      end
    end
  end
end


--------------------------------------------------------------------------------

function SetStealth(unitID, state)
  local stealthData = stealthUnits[unitID]
  if (not stealthData) then
    return false
  end

  if (state) then
    wantingUnits[unitID] = stealthData
    SetUnitRulesParam(unitID, "stealth", 2)
  else
    wantingUnits[unitID] = nil
    SetUnitRulesParam(unitID, "stealth", 0)
  end

  stealthData.active = state
  SetUnitStealth(unitID, state)
end

function gadget:UnitCloaked(unitID, unitDefID, teamID)
  local stealthData = stealthUnits[unitID]
  if (not stealthData) then
    return false
  end
  SetStealth(unitID, true)  
end

function gadget:UnitDecloaked(unitID, unitDefID, teamID)
  local stealthData = stealthUnits[unitID]
  if (not stealthData) then
    return false
  end
  SetStealth(unitID, false)  
end