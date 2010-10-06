-- $Id$

function widget:GetInfo()
  return {
    name      = "Comm Marker",
    desc      = "Marks enemy comms while playing commends",
    author    = "Google Frog",
    date      = "Oct 13, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

local unitDetected
local spMarkerAddPoint  = Spring.MarkerAddPoint
local spGetUnitDefID    = Spring.GetUnitDefID 
local spGetUnitPosition = Spring.GetUnitPosition
local spGetPlayerInfo   = Spring.GetPlayerInfo
local spGetMyPlayerID   = Spring.GetMyPlayerID


function widget:UnitEnteredLos(unitID, allyTeam)
	unitDetected( unitID, false, allyTeam )
end

function unitDetected( unitID, allyTeam, teamId )

  local playerID = spGetMyPlayerID()
  local _, _, spec, _, _, _, _, _ = spGetPlayerInfo(playerID)
  if ( (spec == true) or (not Game.commEnds) ) then
	Spring.Echo("Comm Marker removed")
	widgetHandler:RemoveWidget()
	return false
  end

  local udef = UnitDefs[spGetUnitDefID(unitID)] 
  local x, y, z = spGetUnitPosition(unitID)
  local pos = {x, y, z}
  
  if (udef.isCommander == true) then
    spMarkerAddPoint( pos[1], pos[2], pos[3],  "Comm" )
    --setMarkerForUnit( unitID, udef, { x,y,z }, type, range, damage or nil )
  end
end
