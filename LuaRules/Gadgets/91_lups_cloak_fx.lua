-- $Id: lups_manager.lua 3171 2008-11-06 09:06:29Z det $
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


function gadget:GetInfo()
  return {
    name      = "LupsSyncedManager_91",
    desc      = "",
    author    = "jK",
    date      = "Apr, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = (Game.version:find('91.0') == 1),
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  __           _  _  _
-- (_  \ / |\ | /  |_ | \
-- __)  |  | \| \_ |_ |_/
-- 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

  local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
  function gadget:UnitDamaged(unitID,unitDefID,teamID)
    if (spGetUnitIsCloaked(unitID)) then
      SendToUnsynced("lups_unit_cloakeddamaged", unitID, unitDefID, teamID)
    end
  end

  function gadget:UnitDestroyed(unitID,unitDefID)
    SendToUnsynced("lups_unit_destroyed", unitID, unitDefID)
  end


  function gadget:UnitCloaked(unitID,unitDefID,teamID)
    SendToUnsynced("lups_unit_cloaked", unitID,unitDefID,teamID)
  end
  function gadget:UnitDecloaked(unitID,unitDefID,teamID)
    SendToUnsynced("lups_unit_decloaked", unitID,unitDefID,teamID)
  end

  function gadget:UnitGiven(unitID, unitDefID, teamID, oldTeamID)
    if (spGetUnitIsCloaked(unitID)) then
    	SendToUnsynced("lups_unit_cloaked", unitID,unitDefID,teamID)
    end
  end

  function gadget:PlayerChanged(playerID)
    SendToUnsynced("lups_player_changed", playerID)
  end

else

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           __           _  _  _
-- | | |\ | (_  \ / |\ | /  |_ | \
-- |_| | \| __)  |  | \| \_ |_ |_/
-- 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- speed ups + some table functions
--

--local tinsert = table.insert
local tinsert = function(tab, insert)
  tab[#tab+1] = insert
end

local type  = type
local pairs = pairs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  --// Lua Particle System
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« some basic functions »»
--

local supportedFxs = {}
local function fxSupported(fxclass)
  if (supportedFxs[fxclass]~=nil) then
    return supportedFxs[fxclass]
  else
    supportedFxs[fxclass] = Lups.HasParticleClass(fxclass)
    return supportedFxs[fxclass]
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« cloaked unit handling »»
--

local CloakedHitEffect = { class='UnitJitter',options={ life=50, pos={0,0,0}, enemyHit=true, repeatEffect=false} }
local CloakEffect      = {
  { class='UnitCloaker',options={ life=50 } },
  { class='UnitJitter',options={ delay=24, life=math.huge } },
  { class='Sound',options={ file="sounds/cloak.wav",volume=0.9 } },
}
local EnemyCloakEffect      = {
  { class='UnitCloaker',options={ life=20 } },
  { class='Sound',options={ file="sounds/cloak.wav",volume=0.9 } },
}

local DecloakEffect    = {
  { class='UnitCloaker',options={ inverse=true, life=50 } },
  { class='UnitJitter',options={ life=24 } },
  { class='Sound',options={ file="sounds/cloak.wav",volume=0.9 } },
}
local EnemyDecloakEffect      = {
  { class='UnitCloaker',options={ inverse=true, life=60 } },
  { class='Sound',options={ file="sounds/cloak.wav",volume=0.9 } },
}

--[[
local function UnitDamaged(_,unitID,unitDefID,teamID)
  local allyTeamID = Spring.GetUnitAllyTeam(unitID)

  local LocalAllyTeamID
  local _, specFullView = Spring.GetSpectatingState()
  if (specFullView) then
    LocalAllyTeamID = allyTeamID
  else
    LocalAllyTeamID = Spring.GetLocalAllyTeamID()
  end

  if (Spring.GetUnitIsCloaked(unitID))and(allyTeamID~=LocalAllyTeamID) then

    if (particleIDs[unitID]) then
      for _,fxID in ipairs(particleIDs[unitID]) do
        Lups.RemoveParticles(fxID)
      end
    end

    particleIDs[unitID] = {}
    CloakedHitEffect.options.unit = unitID
    CloakedHitEffect.options.team = teamID
    CloakedHitEffect.options.unitDefID = unitDefID
    tinsert( particleIDs[unitID],Lups.AddParticles(CloakedHitEffect.class,CloakedHitEffect.options) )
  end
end
--]]

local function UnitCloaked(_,unitID,unitDefID,teamID)
  local allyTeamID = Spring.GetUnitAllyTeam(unitID)

  local LocalAllyTeamID
  local _, specFullView = Spring.GetSpectatingState()
  if (specFullView) then
    LocalAllyTeamID = allyTeamID
  else
    LocalAllyTeamID = Spring.GetLocalAllyTeamID()
  end

  if (particleIDs[unitID]) then
    for i=1,#particleIDs[unitID] do
      Lups.RemoveParticles(particleIDs[unitID][i])
    end
  end
  particleIDs[unitID] = {}
  if (LocalAllyTeamID==allyTeamID) then
    for i=1,#CloakEffect do
      local fx = CloakEffect[i]
      fx.options.unit      = unitID
      fx.options.unitDefID = unitDefID
      fx.options.team      = teamID
	  fx.options.allyTeam  = allyTeamID
	  tinsert( particleIDs[unitID],Lups.AddParticles(fx.class,fx.options) )
    end
  else
    for i=1,#EnemyCloakEffect do
      local fx = EnemyCloakEffect[i]
      fx.options.unit      = unitID
      fx.options.unitDefID = unitDefID
      fx.options.team      = teamID
	  fx.options.allyTeam  = allyTeamID
	  tinsert( particleIDs[unitID],Lups.AddParticles(fx.class,fx.options) )
    end
  end

end


local function UnitDecloaked(_,unitID,unitDefID,teamID)
  local allyTeamID = Spring.GetUnitAllyTeam(unitID)

  local LocalAllyTeamID
  local _, specFullView = Spring.GetSpectatingState()
  if (specFullView) then
    LocalAllyTeamID = allyTeamID
  else
    LocalAllyTeamID = Spring.GetLocalAllyTeamID()
  end

  if (particleIDs[unitID]) then
    for i=1,#particleIDs[unitID] do
      Lups.RemoveParticles(particleIDs[unitID][i])
    end
  end
  particleIDs[unitID] = {}
  if (LocalAllyTeamID==allyTeamID) then
    for i=1,#DecloakEffect do
      local fx = DecloakEffect[i]
      fx.options.unit      = unitID
      fx.options.unitDefID = unitDefID
      fx.options.team      = teamID
	  fx.options.allyTeam  = allyTeamID
	  tinsert( particleIDs[unitID],Lups.AddParticles(fx.class,fx.options) )
    end
  else
    for i=1,#EnemyDecloakEffect do
      local fx = EnemyDecloakEffect[i]
      fx.options.unit      = unitID
      fx.options.unitDefID = unitDefID
      fx.options.team      = teamID
	  fx.options.allyTeam  = allyTeamID
	  tinsert( particleIDs[unitID],Lups.AddParticles(fx.class,fx.options) )
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  «« Unit Destroyed handling »»
--

local function UnitDestroyed(_,unitID,unitDefID)
  if (particleIDs[unitID]) then
    local effects = particleIDs[unitID]
    for i=1,#effects do
      Lups.RemoveParticles(effects[i])
    end
    particleIDs[unitID] = nil
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function PlayerChanged(_,playerID)
  if (playerID == Spring.GetMyPlayerID()) then
    --// this should reset the cloak fx when becoming a spec
    --gadget.Update = ReinitializeUnitFX
    gadgetHandler:UpdateCallIn("Update")
  end
end

local function ReinitializeUnitFX()
  --// clear old FXs
  for _,unitFxIDs in pairs(particleIDs) do
    for i=1,#unitFxIDs do
      Lups.RemoveParticles(unitFxIDs[i])
    end    
  end
  particleIDs = {}

  --// initialize effects for existing units
  local allUnits = Spring.GetAllUnits();
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    if (Spring.GetUnitIsCloaked(unitID)) then
      local unitDefID = Spring.GetUnitDefID(unitID)
      local teamID = Spring.GetUnitTeam(unitID)
      UnitCloaked(nil,unitID,unitDefID,teamID)
    end
  end

  gadgetHandler:RemoveCallIn("Update")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Update()
  if (Spring.GetGameFrame()<1) then 
    return
  end

  Lups  = GG['Lups']

  if (Lups) then
    --gadgetHandler:AddSyncAction("lups_unit_cloakeddamaged", UnitDamaged)
    gadgetHandler:AddSyncAction("lups_unit_cloaked",        UnitCloaked)
    gadgetHandler:AddSyncAction("lups_unit_decloaked",      UnitDecloaked)
    gadgetHandler:AddSyncAction("lups_unit_destroyed",      UnitDestroyed)

    gadgetHandler:AddSyncAction("lups_luaui",               LupsLuaUI)
    gadgetHandler:AddSyncAction("lups_unit_created",        UnitCreated)
    gadgetHandler:AddSyncAction("lups_player_changed",      PlayerChanged)

    initialized=true
  else
    return
  end

  gadget.Update = ReinitializeUnitFX
  gadgetHandler:UpdateCallIn("Update")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("lups_unit_cloakeddamaged")
  gadgetHandler:RemoveSyncAction("lups_unit_cloaked")
  gadgetHandler:RemoveSyncAction("lups_unit_decloaked")
  gadgetHandler:RemoveSyncAction("lups_unit_destroyed")

  gadgetHandler:RemoveSyncAction("lups_luaui")
  gadgetHandler:RemoveSyncAction("lups_unit_created")
  gadgetHandler:RemoveSyncAction("lups_player_changed")

  if (initialized) then
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	Lups.RemoveParticles(unitFxIDs[i])
      end    
    end
    particleIDs = {}
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end
