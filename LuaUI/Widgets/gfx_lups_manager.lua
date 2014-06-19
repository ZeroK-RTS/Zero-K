-- $Id: gfx_lups_manager.lua 4440 2009-04-19 15:36:53Z licho $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "LupsManager",
    desc      = "",
    author    = "jK",
    date      = "Feb, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = true,
    handler   = true,
  }
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function MergeTable(table1,table2)
  local result = {}
  for i,v in pairs(table2) do 
    if (type(v)=='table') then
      result[i] = MergeTable(v,{})
    else
      result[i] = v
    end
  end
  for i,v in pairs(table1) do 
    if (result[i]==nil) then
      if (type(v)=='table') then
        if (type(result[i])~='table') then result[i] = {} end
        result[i] = MergeTable(v,result[i])
      else
        result[i] = v
      end
    end
  end
  return result
end

include("Configs/lupsFXs.lua")
include("Configs/lupsUnitFXs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function blendColor(c1,c2,mix)
  if (mix>1) then mix=1 end
  local mixInv = 1-mix
  return {
    c1[1]*mixInv + c2[1]*mix,
    c1[2]*mixInv + c2[2]*mix,
    c1[3]*mixInv + c2[3]*mix,
    (c1[4] or 1)*mixInv + (c2[4] or 1)*mix
  }
end


local function blend(a,b,mix)
  if (mix>1) then mix=1 end
  return a*(1-mix) + b*mix
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitEffects = {}
local registeredUnits = {}	-- all finished units - prevents partial unbuild then rebuild from being treated as two UnitFinished events

local function AddFX(unitname,fx)
  local ud = UnitDefNames[unitname]
  --// Seasonal lups stuff

  if ud then
    UnitEffects[ud.id] = fx
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

for i,f in pairs(effectUnitDefs) do
  AddFX(i,f)
end

local currentTime = os.date('*t')
if (currentTime.month==12) then
  for i,f in pairs(effectUnitDefsXmas) do
    AddFX(i,f)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- for i,f in pairs(effectUnitDefs) do
--   Spring.Echo("   ",i,f)
-- end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// cormex overdrive FX
local cormexDefID 
local cormexes    = {}
local cormexFX    = cormexGlow

if (UnitDefNames["cormex"]) then
  cormexDefID = UnitDefNames["cormex"].id  
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs
local min = math.min
local max = math.max
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  -- Lua Particle System
local LupsAddFX
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ClearFxs(unitID)
  if (particleIDs[unitID]) then
    for i=1,#particleIDs[unitID] do
      local fxID = particleIDs[unitID][i]
      Lups.RemoveParticles(fxID)
    end
    particleIDs[unitID] = nil
  end
end


local function ClearFx(unitID, fxIDtoDel)
  if (particleIDs[unitID]) then
  local newTable = {}
    for i=1,#particleIDs[unitID] do
      local fxID = particleIDs[unitID][i]
      if fxID == fxIDtoDel then 
        Lups.RemoveParticles(fxID)
      else 
        newTable[#newTable+1] = fxID
      end
    end

    if #newTable == 0 then 
      particleIDs[unitID] = nil
    else 
      particleIDs[unitID] = newTable
    end
  end
end


local function AddFxs(unitID,fxID)
  if (not particleIDs[unitID]) then
    particleIDs[unitID] = {}
  end

  local unitFXs = particleIDs[unitID]
  unitFXs[#unitFXs+1] = fxID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitFinished(_,unitID,unitDefID)
  if registeredUnits[unitID] then
    return
  end
  registeredUnits[unitID] = true

  if (unitDefID == cormexDefID) then
    cormexes[unitID] = 0
    cormexFX.unit    = unitID
    particleIDs[unitID] = {}
    AddFxs( unitID, LupsAddFX("StaticParticles",cormexFX) )
  end

  local effects = UnitEffects[unitDefID]
  if (effects) then
    for i=1,#effects do
      local fx = effects[i]
      if (not fx.options) then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "LUPS DEBUG GRRR", UnitDefs[unitDefID].name, fx and fx.class)
        return
      end

      if (fx.class=="GroundFlash") then
        fx.options.pos = { Spring.GetUnitPosition(unitID) }
      end
      if (fx.options.heightFactor) then
		local pos = fx.options.pos or {0, 0, 0}
        fx.options.pos = { pos[1], Spring.GetUnitHeight(unitID)*fx.options.heightFactor, pos[3] }
      end
	  if (fx.options.radiusFactor) then
		fx.options.size = Spring.GetUnitRadius(unitID)*fx.options.radiusFactor
	  end
      fx.options.unit = unitID
      AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
      fx.options.unit = nil
    end
  end
end


local function UnitDestroyed(_,unitID,unitDefID)
  registeredUnits[unitID] = nil
  if (unitDefID == cormexDefID) then
    cormexes[unitID] = nil
  end

  ClearFxs(unitID)
end


local function UnitEnteredLos(_,unitID)
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then 
    return 
  end
  
  --[[
  if registeredUnits[unitID] then
    return
  end
  registeredUnits[unitID] = true
  ]]

  if (unitDefID == cormexDefID) then
    cormexes[unitID] = 1
    cormexFX.unit    = unitID
    particleIDs[unitID] = {}
    AddFxs( unitID, LupsAddFX("StaticParticles",cormexFX) )
  end

  local unitDefID = spGetUnitDefID(unitID)
  local effects   = UnitEffects[unitDefID]
  if (effects) then
    for i=1,#effects do
      local fx = effects[i]
      if (fx.class=="GroundFlash") then
        fx.options.pos = { Spring.GetUnitPosition(unitID) }
      end
    fx.options.unit = unitID
    AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
    fx.options.unit = nil
    end
  end
end


local function UnitLeftLos(_,unitID)
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then return end

  --registeredUnits[unitID] = nil
  if (unitDefID == cormexDefID) then
    cormexes[unitID] = nil
  end

  ClearFxs(unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local color1 = {0,0,0}
local color2 = {1,0.5,0}

local function GameFrame(_,n)
  if (((n+48)%60)<1 and (next(cormexes))) then
    --//Update Overdrive Fx
    for unitID,strength in pairs(cormexes) do
      local cur_strength = spGetUnitRulesParam(unitID,"overdrive") or 1
      local diff         = abs(cur_strength - strength)
      if (diff>0.1) then
        -- limit the maximum change per update (else the fx would jump like hell)
        cur_strength = (strength) + ((cur_strength>strength and 1) or -1)*0.3

        local a = min(1,max(0,(cur_strength-1)*0.35));
        ClearFxs(unitID)
        cormexFX.unit     = unitID
        cormexFX.colormap = {blendColor(cormexFX.color1,cormexFX.color2, a)}

        cormexFX.size     = blend(cormexFX.size1,cormexFX.size2, a)
        AddFxs( unitID, LupsAddFX("StaticParticles",cormexFX) )
        cormexes[unitID]  = cur_strength
      end
    end
    cormexFX.colormap = {cormexFX.color1}
    cormexFX.size   = cormexFX.size1
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Player status changed (switched team/ally or become a spectator)

local function PlayerChanged(_,playerID)
  if (playerID == Spring.GetMyPlayerID()) then
    --// clear all FXs
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	local fxID = unitFxIDs[i]    
        Lups.RemoveParticles(fxID)
      end
    end
    particleIDs = {}

    widgetHandler:UpdateWidgetCallIn("Update",widget)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GameFrame()
  if (Spring.GetGameFrame() > 0) then
    Spring.SendLuaRulesMsg("lups running","allies")
    widgetHandler:RemoveWidgetCallIn("GameFrame",widget)
  end
end


local function CheckForExistingUnits()
  --// initialize effects for existing units
  local allUnits = Spring.GetAllUnits();
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local unitDefID = Spring.GetUnitDefID(unitID)
    UnitFinished(nil,unitID,unitDefID)
  end

  widgetHandler:RemoveWidgetCallIn("Update",widget)
end


function widget:Update()
  Lups = WG['Lups']
  local LupsWidget = widgetHandler.knownWidgets['Lups'] or {}

  --// Lups running?
  if (not initialized) then
    if (Lups and LupsWidget.active) then
      if (tryloading==-1) then
        Spring.Echo("LuaParticleSystem (Lups) activated.")
      end
      initialized=true
      return
    else
      if (tryloading==1) then
        Spring.Echo("Lups not found! Trying to activate it.")
        widgetHandler:EnableWidget("Lups")
        tryloading=-1
        return
      else
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "LuaParticleSystem (Lups) couldn't be loaded!")
        widgetHandler:RemoveWidgetCallIn("Update",self)
        return
      end
    end
  end

  if (Spring.GetGameFrame()<1) then
    --// send errorlog if me (jK) is in the game
    local allPlayers = Spring.GetPlayerList()
    for i=1,#allPlayers do
      local playerName = Spring.GetPlayerInfo(allPlayers[i])
      if (playerName == "[LCC]jK") then
        local errorLog = Lups.GetErrorLog(1)
        if (errorLog~="") then
          local cmds = {
            "say ------------------------------------------------------",
            "say LUPS: jK is here! Sending error log (so he can fix your problems):",
          }
         --// the str length is limited with "say ...", so we split it
          for line in errorLog:gmatch("[^\r\n]+") do
            cmds[#cmds+1] = "say " .. line
          end
          cmds[#cmds+1] = "say ------------------------------------------------------"
          Spring.SendCommands(cmds)
        end
        break
      end
    end
  end

  LupsAddFX = Lups.AddParticles

  widget.UnitFinished   = UnitFinished
  widget.UnitDestroyed  = UnitDestroyed
  widget.UnitEnteredLos = UnitEnteredLos
  widget.UnitLeftLos    = UnitLeftLos
  widget.GameFrame      = GameFrame
  widget.PlayerChanged  = PlayerChanged
  widgetHandler:UpdateWidgetCallIn("UnitFinished",widget)
  widgetHandler:UpdateWidgetCallIn("UnitDestroyed",widget)
  widgetHandler:UpdateWidgetCallIn("UnitEnteredLos",widget)
  widgetHandler:UpdateWidgetCallIn("UnitLeftLos",widget)
  widgetHandler:UpdateWidgetCallIn("GameFrame",widget)
  widgetHandler:UpdateWidgetCallIn("PlayerChanged",widget)

  widget.Update = CheckForExistingUnits
  widgetHandler:UpdateWidgetCallIn("Update",widget)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
  if (initialized) then
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	local fxID = unitFxIDs[i]
      end
    end
    particleIDs = {}
  end

  Spring.SendLuaRulesMsg("lups shutdown","allies")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
