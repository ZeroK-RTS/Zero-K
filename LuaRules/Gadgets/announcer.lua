function gadget:GetInfo()
  return {
    name	= "Announcer",
    desc	= "Zero-K announcer, reacts to ingame events and broadcast them to widgets. v1.0.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -10,
    enabled 	= true,
  }
end

-- This is great place to write event detection, as example it currently can detect only next things:
-- Airshot (landunit was killed in midiar)
-- Impressive/Amazing (you skuttled or shadowed or lichoed someone, or expensive strider died)
-- Awesome/Amazing (basic multikill)
-- Headshot (you comsniped someone, or strider was sniped)
-- Both victim and killer get these, as well as anyone who witnessed that.
-- You may hear only one of above at a time, this is handled by widgets though. Events are still triggered as they happen.

-- TODO make an distinctive event for amazing/awesome...

if (gadgetHandler:IsSyncedCode()) then
------------------------------INTERNAL CONFIG--------------------------------------------------------------------------------
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
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spGetGameFrame	 	= Spring.GetGameFrame
local spGetGroundHeight     	= Spring.GetGroundHeight

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0

local GaiaTeamID	   	= Spring.GetGaiaTeamID()
local DeathDistance		= 500
local DeathDistanceSQ		= DeathDistance*DeathDistance

local DeathMarkers		= {}
local DeathExpire		= 30 -- frames after which DeathMarker is destroyed

local MemoData = {}

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  if (unitDefID ~= nil ) then
    local ud = UnitDefs[unitDefID]
    if (not ud.customParams.dontcount) and (not spGetUnitRulesParam(unitID, 'wasMorphedTo')) then
      local x,y,z = spGetUnitPosition(unitID)
      if (GaiaTeamID ~= attackerID) and (attackerTeamID ~= nil) then
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
	if (select(6,spGetTeamInfo(teamID)) ~= select(6,spGetTeamInfo(attackerTeamID))) then
	  if (attackerDefID ~= nil) then
	    Spring.Echo("impressive")
	    if ((impressiveKillerUnitsDef[attackerDefID]) and ((ud.metalCost >= 600) or ud.customParams.commtype)) or (impressiveVictimUnitsDef[unitDefID]) then
	      SendToUnsynced("announcer_impressive", teamID, attackerTeamID, x, y, z)
	    end
	    if (ud.customParams.commtype or headshotUnitsDef[unitDefID]) or ((headshotUnitsDef[attackerDefID]) and (ud.metalCost >= 1200) and (ud.canMove)) then
	      SendToUnsynced("announcer_headshot", teamID, attackerTeamID, x, y, z)
	    end
	  end
	  if (x ~= nil) then
	    local groundHeight = spGetGroundHeight(x,z)
	    if (y < waterLevel) then
	      groundHeight = waterLevel
	    end
	    if (not(ud.canFly) and ((y-40) >= groundHeight)) then -- 40 diff is just above defender
	      SendToUnsynced("announcer_airshot", teamID, attackerTeamID, x, y, z)
	    end
	  end
	end
      end
    end
  end
  if (MemoData[unitID]) then MemoData[unitID]=nil end
end

function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

function GetNearestMarker(x,z)
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

function gadget:GameFrame(n)
  for markerID, data in pairs(DeathMarkers) do
    if (n-45) >= data.time then
      local x = data.x
      local y = data.y
      local z = data.z
      local kills = data.kills
      local wasted = data.wasted
      if ((kills >= 10) and (wasted >= 900)) or (wasted >= 4500) then -- hard to get in the begining 'ey?
	for teamID, _ in pairs(data.teams) do
	  SendToUnsynced("announcer_awesome", teamID, x, y, z)
	end
      end
      DeathMarkers[markerID] = nil
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------
else
  
local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spIsPosInLos         = Spring.IsPosInLos
local spGetMyPlayerID	   = Spring.GetMyPlayerID
local spGetTeamInfo	   = Spring.GetTeamInfo

function Airshot(_, teamID, attackerID, x, y, z)
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if spec or spIsPosInLos(x, y+30, z, myAllyTeam) or (select(6,spGetTeamInfo(teamID))==myAllyTeam) or (select(6,spGetTeamInfo(attackerID))==myAllyTeam) then
    if (Script.LuaUI('AnnouncerAirshot')) then
      Script.LuaUI.AnnouncerAirshot(spGetMyPlayerID(),x,y,z)
    end
  end
end

function Awesome(_, teamID, x, y, z)
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if spec or spIsPosInLos(x, y+30, z, myAllyTeam) or (select(6,spGetTeamInfo(teamID))==myAllyTeam) then
    if (Script.LuaUI('AnnouncerAwesome')) then
      Script.LuaUI.AnnouncerAwesome(spGetMyPlayerID(),x,y,z)
    end
  end
end

function Impressive(_, teamID, attackerID, x, y, z)
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if spec or spIsPosInLos(x, y+30, z, myAllyTeam) or (select(6,spGetTeamInfo(teamID))==myAllyTeam) or (select(6,spGetTeamInfo(attackerID))==myAllyTeam) then
    if (Script.LuaUI('AnnouncerImpressive')) then
      Script.LuaUI.AnnouncerImpressive(spGetMyPlayerID(),x,y,z)
    end
  end
end

function Headshot(_, teamID, attackerID, x, y, z)
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if spec or spIsPosInLos(x, y+30, z, myAllyTeam) or (select(6,spGetTeamInfo(teamID))==myAllyTeam) or (select(6,spGetTeamInfo(attackerID))==myAllyTeam) then
    if (Script.LuaUI('AnnouncerHeadshot')) then
      Script.LuaUI.AnnouncerHeadshot(spGetMyPlayerID(),x,y,z)
    end
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction("announcer_airshot", Airshot)
  gadgetHandler:AddSyncAction("announcer_awesome", Awesome)
  gadgetHandler:AddSyncAction("announcer_impressive", Impressive)
  gadgetHandler:AddSyncAction("announcer_headshot", Headshot)
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("announcer_airshot")
  gadgetHandler:RemoveSyncAction("announcer_awesome")
  gadgetHandler:RemoveSyncAction("announcer_impressive")
  gadgetHandler:RemoveSyncAction("announcer_headshot")
end

end