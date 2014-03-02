function widget:GetInfo()
  return {
    name	= "Announcer",
    desc	= "Zero-K announcer, reacts to ingame events and notifies players. v1.1.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -1,
    enabled = false,
  }
end
-----------------------------------------------------------------------------------------------------------------------------
local impressiveKillerUnitsDef = { -- you still have to kill more than 600 metal...
 [ UnitDefNames['armcybr'].id ] = true,
 [ UnitDefNames['corroach'].id ] = true,
 [ UnitDefNames['corshad'].id ] = true,
 [ UnitDefNames['corsktl'].id ] = true,
 [ UnitDefNames['screamer'].id ] = true,
 [ UnitDefNames['corroach'].id ] = true,
 [ UnitDefNames['blastwing'].id ] = true,
--  [ UnitDefNames['tacnuke'].id ] = true, -- TODO this unit does not kill by itself, figure out a way to detect its children's kills
}
local impressiveVictimUnitsDef = { -- or this should die
 [ UnitDefNames['amgeo'].id ] = true,
 [ UnitDefNames['cafus'].id ] = true,
 [ UnitDefNames['chickenq'].id ] = true, -- extreme rare
--  [ UnitDefNames['armcomdgun'].id ] = true, -- too often
--  [ UnitDefNames['scorpion'].id ] = true, -- too often
--  [ UnitDefNames['dante'].id ] = true, -- too often
--  [ UnitDefNames['armraven'].id ] = true, -- too often
 [ UnitDefNames['corcrw'].id ] = true, -- krow
 [ UnitDefNames['funnelweb'].id ] = true,
 [ UnitDefNames['armbanth'].id ] = true,
 [ UnitDefNames['armorco'].id ] = true,
--  [ UnitDefNames['cornukesub'].id ] = true,
 [ UnitDefNames['armcarry'].id ] = true, -- these are not expensive but they are not so often built
 [ UnitDefNames['corbats'].id ] = true, -- these are not expensive but they are not so often built
}
local headshotUnitsDef = { -- or commtype
 [ UnitDefNames['armcomdgun'].id ] = true,
 [ UnitDefNames['scorpion'].id ] = true,
 [ UnitDefNames['dante'].id ] = true,
 [ UnitDefNames['armraven'].id ] = true,
 [ UnitDefNames['corcrw'].id ] = true,
 [ UnitDefNames['funnelweb'].id ] = true,
 [ UnitDefNames['armbanth'].id ] = true,
 [ UnitDefNames['armorco'].id ] = true,
} -- TODO make it so weapons are triggers, but not units themselves...
-----------------------------------------------------------------------------------------------------------------------------
local random			= math.random
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam	   	= Spring.GetUnitTeam
local spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetGameFrame		= Spring.GetGameFrame
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spGetGroundHeight     	= Spring.GetGroundHeight

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0

local GaiaTeamID	   	= Spring.GetGaiaTeamID()
local DeathDistance		= 500
local DeathDistanceSQ		= DeathDistance*DeathDistance

local DeathMarkers		= {}
local DeathExpire		= 30 -- frames after which DeathMarker is destroyed

local MemoData = {}

local sound_mode = 1 -- off/on
local LastSpam = -100

local sfx_path = "sounds/announcer/"

local function OptionsChanged() 
  if (sound_mode~= options.sound_mode) then
    sound_mode = options.sound_mode.value
  end
end

options_path = 'Settings/Audio/Announcer'
options_order = { 
  'sound_mode',  
}
options = {
  sound_mode = {
    name = 'Announcer enabled',
    type = 'bool',
    value = true,
    OnChange = OptionsChanged,
  },
}
-----------------------------------------------------------------------------------------------------------------------------

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

local function AnnouncerAirshot(x, y, z)
  if not(options.sound_mode.value) then return end
  if (LastSpam+30 >= spGetGameFrame()) then return end
  Spring.PlaySoundFile(sfx_path.."airshot.wav", 18.0, x, y, z)
  LastSpam = spGetGameFrame()
end

local function AnnouncerAwesome(x, y, z)
  if not(options.sound_mode.value) then return end
  if (LastSpam+30 >= spGetGameFrame()) then return end
  if (random(1,2) == 1) then
    Spring.PlaySoundFile(sfx_path.."awesome"..random(1,2)..".wav", 18.0, x, y, z)
  else
    Spring.PlaySoundFile(sfx_path.."amazing"..random(1,2)..".wav", 18.0, x, y, z)
  end
  LastSpam = spGetGameFrame()
end

local function AnnouncerImpressive(x, y, z)
  if not(options.sound_mode.value) then return end
  if (LastSpam+30 >= spGetGameFrame()) then return end
  if (random(1,2) == 1) then
    Spring.PlaySoundFile(sfx_path.."impressive.wav", 18.0, x, y, z)
  else
    Spring.PlaySoundFile(sfx_path.."amazing"..random(1,2)..".wav", 18.0, x, y, z)
  end
  LastSpam = spGetGameFrame()
end

local function AnnouncerHeadshot(x, y, z)
  if not(options.sound_mode.value) then return end
  if (LastSpam+30 >= spGetGameFrame()) then return end
  Spring.PlaySoundFile(sfx_path.."headshot.wav", 18.0, x, y, z)
  LastSpam = spGetGameFrame()
end

local function GetNearestMarker(x,z)
  local best_marker = nil
  local best_dist = nil
  for markerID, data in pairs(DeathMarkers) do
    local dist = disSQ(x,z,data.x,data.z)
    if (dist < DeathDistanceSQ) and ((best_marker == nil) or (dist < best_dist)) then
      best_dist = dist
      best_marker = markerID
    end
  end
  return best_marker
end

local function UnitDead(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  if (unitDefID ~= nil ) then
    local ud = UnitDefs[unitDefID]
    if (not ud.customParams.dontcount) and (not spGetUnitRulesParam(unitID, 'wasMorphedTo')) then
      local x,y,z = spGetUnitPosition(unitID)
      if (GaiaTeamID ~= attackerID) then -- and (attackerTeamID ~= nil) then
	local markerID = GetNearestMarker(x,z) -- Z level is ignored
	if (markerID ~= nil) then
	  DeathMarkers[markerID].kills = DeathMarkers[markerID].kills + 1
	  -- TODO nanoframes metalcost should be scaled by their health
	  DeathMarkers[markerID].wasted = DeathMarkers[markerID].wasted + ud.metalCost
	  DeathMarkers[markerID].x = (DeathMarkers[markerID].x+x)/2
	  DeathMarkers[markerID].z = (DeathMarkers[markerID].z+z)/2
	  DeathMarkers[markerID].y = spGetGroundHeight(DeathMarkers[markerID].x,DeathMarkers[markerID].z)
	  DeathMarkers[markerID].time = spGetGameFrame()
	  DeathMarkers[markerID].teams[teamID] = true
	  if (attackerTeamID ~= nil) then
	    DeathMarkers[markerID].teams[attackerTeamID] = true
	  end
	else
	  DeathMarkers[unitID] = {
	    kills = 1,
	    wasted = 0+ud.metalCost,
	    x = x,
	    y = y,
	    z = z,
	    time = spGetGameFrame(),
	    teams = {}
	  }
	  DeathMarkers[unitID].teams[teamID] = true
	  if (attackerTeamID ~= nil) then
	    DeathMarkers[unitID].teams[attackerTeamID] = true
	  end
	end
	if (attackerTeamID == nil) or (select(6,spGetTeamInfo(teamID)) ~= select(6,spGetTeamInfo(attackerTeamID))) then
	  if (attackerDefID ~= nil) then
	    if ((impressiveKillerUnitsDef[attackerDefID]) and ((ud.metalCost >= 600) or ud.customParams.commtype)) or (impressiveVictimUnitsDef[unitDefID]) then
	      AnnouncerImpressive(x, y, z)
	    end
	    if (ud.customParams.commtype or headshotUnitsDef[unitDefID]) or (((attackerDefID~=nil) and headshotUnitsDef[attackerDefID]) and (ud.metalCost >= 1200) and (ud.canMove)) then
	      AnnouncerHeadshot(x, y, z)
	    end
	  end
	  if (x ~= nil) then
	    local groundHeight = spGetGroundHeight(x,z)
	    if (y < waterLevel) then
	      groundHeight = waterLevel
	    end
	    if (not(ud.canFly) and ((y-40) >= groundHeight)) then -- 40 diff is just above defender
	      AnnouncerAirshot(x, y, z)
	    end
	  end
	end
      end
    end
  end
  if (MemoData[unitID]) then MemoData[unitID]=nil end
end

function widget:GameFrame(n)
  for markerID, data in pairs(DeathMarkers) do
    if (n-45) >= data.time then
      local x = data.x
      local y = data.y
      local z = data.z
      local kills = data.kills
      local wasted = data.wasted
      if ((kills >= 10) and (wasted >= 900)) or (wasted >= 6200) then -- hard to get in the begining 'ey?
	for teamID, _ in pairs(data.teams) do
	  AnnouncerAwesome(x, y, z)
	end
      end
      DeathMarkers[markerID] = nil
    end
  end
end

local function AnnouncerUnitDestroyed(PlayerID, unitID, attackerID)
--   Spring.Echo("got event: "..tostring(unitID).." died by "..tostring(attackerID))
  local unitDefID = spGetUnitDefID(unitID)
  local teamID = spGetUnitTeam(unitID)
  local attackerDefID, attackerTeamID
  if (attackerID ~= nil) then
    attackerDefID = spGetUnitDefID(attackerID)
    attackerTeamID = spGetUnitTeam(attackerID)
  end
  UnitDead(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:RegisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
end

function widget:Shutdown()
  widgetHandler:DeregisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
end
