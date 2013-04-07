function gadget:GetInfo()
  return {
    name      = "Chicken control",
    desc      = "v0.001 Silly mode to allow players play as chickens a bit...",
    author    = "Tom Fyuri",
    date      = "Apr 2013",
    license   = "GPL v2 or later",
    layer     = 11,
    enabled   = true
  }
end
--[[ how should it work?
chicken units are given equally to everyone on chicken team.
players can use only chickens. rules are same as chickens. also someone eventually will get queen.
that's all.

-- TODO list:
1) as far as i know there can be multiple chicken bots on different teams, but only one of them will play, if that's the case, handle it...
2) block take command and allow computer chicken to play as well...
3) don't give chickens to afk and resigned players...
4) have fun...
]]--

if(not Spring.GetModOptions()) then
      return false
end

local modOptions = Spring.GetModOptions()
local playerchickens = modOptions.playerchickens or false
if (playerchickens == false) then
      return
end

local IgnoreUnits = {
  [ UnitDefNames['roost'].id ] = true,
}

-- and so players get a share
if (gadgetHandler:IsSyncedCode()) then

local spGetTeamInfo     = Spring.GetTeamInfo
local spGetTeamList	= Spring.GetTeamList
local spGetTeamLuaAI	= Spring.GetTeamLuaAI
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spDestroyUnit	= Spring.DestroyUnit
local spTransferUnit     = Spring.TransferUnit
  
local function GetTeamIsChicken(teamID)
  local luaAI = spGetTeamLuaAI(teamID)
  if luaAI and string.find(string.lower(luaAI), "chicken") then
    return true
  end
  return false
end

local ChickenTeam
local ChickenAllyTeam
local GiveToTeam
local ChickenPlayers = {}

function gadget:Initialize()
  if(playerchickens == false) then
      gadgetHandler:RemoveGadget()
  end
  local teams = spGetTeamList()
  for i=1,#teams do
    if GetTeamIsChicken(teams[i]) then
      ChickenTeam = teams[i]
      break
    end
  end
  if (ChickenTeam == nil) then gadgetHandler:RemoveGadget() end
  ChickenAllyTeam = select(6,spGetTeamInfo(ChickenTeam))
  local j = -1
  for i=1,#teams do
    local allyTeam = select(6,spGetTeamInfo(teams[i]))
    if (spGetTeamLuaAI(teams[i]) == "") and (allyTeam == ChickenAllyTeam) then
      j=j+1
      ChickenPlayers[j] = teams[i]
    end
  end
  if (j>-1) then
    GiveToTeam = 0
  else
    --GiveToTeam = -1
    gadgetHandler:RemoveGadget()
  end
  --Spring.Echo("Chicken allyteam is "..ChickenAllyTeam)
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  local allyTeam = select(6,spGetTeamInfo(unitTeam))
  --Spring.Echo("Unit spawned and ally team is "..allyTeam)
  if (unitTeam == ChickenTeam) then
    -- as a testing let's just cycle through recievers
    if (not IgnoreUnits[unitDefID]) then
      --if (GiveToTeam > 0) then
      spTransferUnit(unitID, ChickenPlayers[GiveToTeam], false)
      GiveToTeam=GiveToTeam+1
      if (GiveToTeam > #ChickenPlayers) then
	GiveToTeam = 0
      end
      --end
    end
  elseif (allyTeam == ChickenAllyTeam) then
    local ud = UnitDefs[unitDefID]
    if (ud.customParams.commtype) then
      spDestroyUnit(unitID, false, true) -- bye bye commander
    end
  end
end

end