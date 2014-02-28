function gadget:GetInfo()
  return {
    name	= "Announcer",
    desc	= "Zero-K announcer, reacts to ingame events and broadcast them to widgets. v1.1.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -10,
    enabled 	= true,
  }
end
-- v1.1.
-- now it's not spec cheating at all. also most of the code moved to widget.
-- now this gadget simply allows widgets to get info on enemies upon unitdestroyed.
-- you may still not know enemy unit's fate if it died outside your los.
if (gadgetHandler:IsSyncedCode()) then
------------------------------INTERNAL CONFIG--------------------------------------------------------------------------------
local spValidUnitID		= Spring.ValidUnitID
local spGetUnitLosState		= Spring.GetUnitLosState
local spGetAllyTeamList	  	= Spring.GetAllyTeamList
local AllyTeams = {}

-- is the enemy unitID position knowable to an allyteam
local function isUnitVisible(unitID, allyTeam)
  if spValidUnitID(unitID) then
    local state = spGetUnitLosState(unitID,allyTeam)
    return state and state.los -- (state.los or state.radar) -- for the time being broadcast only if it happened in los, you do not know for sure if radar dot died... or your radar is out of power.
  else
    return false
  end
end

function gadget:Initialize()
  local allyteams = spGetAllyTeamList()
  for _,allyTeam in ipairs(allyteams) do
    AllyTeams[#AllyTeams+1] = allyTeam
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  for i=1,#AllyTeams do
    local allyTeam = AllyTeams[i]
    if (isUnitVisible(unitID, allyTeam)) then
      SendToUnsynced("announcerUnitDestroyed", allyTeam, unitID, attackerID) -- do not broadcast defids! widgets may figure this out on their own!
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------
else

local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
local spGetMyPlayerID	   = Spring.GetMyPlayerID

-- this reminds me of FPS where you can see who killed who at top-right of the screen
local function UnitDead(_, allyTeam, unitID, attackerID)
  local myAllyTeam = spGetLocalAllyTeamID()
  if (Script.LuaUI('AnnouncerUnitDestroyed') and (myAllyTeam == allyTeam)) then
    Script.LuaUI.AnnouncerUnitDestroyed(spGetMyPlayerID(),unitID,attackerID)
  end
end

function gadget:Initialize()
  gadgetHandler:AddSyncAction("announcerUnitDestroyed", UnitDead)
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("announcerUnitDestroyed")
end

end