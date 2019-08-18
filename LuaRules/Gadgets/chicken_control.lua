function gadget:GetInfo()
  return {
    name      = "Chicken control",
    desc      = "v0.004 Silly mode to allow players play as chickens a bit...",
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
0) !!! chicken queen is different in walkingand flying modes, make sure only one players controls both !!!
1) probably allow computer chicken to play as well... maybe not?
2) don't give chickens to afk and resigned players...
3) is it possible to disable com selection screen for chicken players?
4) have fun...

-- changelog 0.004:
attemption to ignore afk/resigned players when giving chickens.

-- changelog 0.003:
revertion of previous action, now roosts should belong to AI always.

-- changelog 0.002:
attemption to block roost self-d-bility.

-- changelog 0.001:
initial release.

]]--

if(not Spring.GetModOptions()) then
  return false
end

local modOptions = Spring.GetModOptions()
local playerChickens = tobool(modOptions.playerchickens) or false

-- and so players get a share
if (gadgetHandler:IsSyncedCode()) then

local NotGivingToPlayersUnits = {
  [ UnitDefNames['roost'].id ] = true,
}

local spGetTeamInfo     = Spring.GetTeamInfo
local spGetTeamList	= Spring.GetTeamList
local spGetTeamLuaAI	= Spring.GetTeamLuaAI
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spDestroyUnit	= Spring.DestroyUnit
local spTransferUnit    = Spring.TransferUnit
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
  
local function GetTeamIsChicken(teamID)
  local luaAI = spGetTeamLuaAI(teamID)
  if luaAI and string.find(string.lower(luaAI), "chicken") then
    return true
  end
  return false
end

local ChickenTeam = -1
local ChickenAllyTeam
local GiveToTeam
local ChickenPlayers = {}
local MaxLoop

function gadget:Initialize()
  if (playerChickens == false) then
    --Spring.Echo("chicken_control gadget quit, modoption disabled")
    gadgetHandler:RemoveGadget()
  end
  local teams = spGetTeamList()
  for i=1,#teams do
    if GetTeamIsChicken(teams[i]) then
      ChickenTeam = teams[i]
      --break
    end
  end
  if (ChickenTeam == -1) then
    --Spring.Echo("chicken_control gadget quit. did not find chicken")
    gadgetHandler:RemoveGadget()
  end
  ChickenAllyTeam = select(6,spGetTeamInfo(ChickenTeam, false))
  local j = 0
  for i=1,#teams do
    local allyTeam = select(6,spGetTeamInfo(teams[i], false))
    if (spGetTeamLuaAI(teams[i]) == "") and (allyTeam == ChickenAllyTeam) then
      j=j+1
      ChickenPlayers[j] = teams[i]
    end
  end
  if (j>0) then
    GiveToTeam = 1
  else
    --Spring.Echo("chicken_control gadget quit, did not find chicken players")
    gadgetHandler:RemoveGadget()
  end
  MaxLoop = #ChickenPlayers+1
  --Spring.Echo("Chicken allyteam is "..ChickenAllyTeam)
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam, capture)
  -- refuse /take for roosts...
  if (oldTeam == ChickenTeam) and (NotGivingToPlayersUnits[unitDefID]) then
    return false
  end
  return true
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
  local allyTeam = spGetUnitAllyTeam(unitID)
  --Spring.Echo("Unit spawned and ally team is "..allyTeam)
  local curLoop = 0
  local anyone_not_spec = false
  local condition = true
  if (unitTeam == ChickenTeam) then
    if (not NotGivingToPlayersUnits[unitDefID]) then
      while (condition) do
	if (ChickenPlayers[GiveToTeam] ~= nil) then
	  local leader = select(2, spGetTeamInfo(ChickenPlayers[GiveToTeam], false))
	  if (leader >= 0) then -- otherwise spec
	    local active = select(2, spGetPlayerInfo(leader, false))
	    anyone_not_spec = true
	    --Spring.Echo("chicken_control "..leader.." not spectator")
	    if active then
	      condition = false
	      --Spring.Echo("chicken_control "..leader.." is active")
	      spTransferUnit(unitID, ChickenPlayers[GiveToTeam], false)
	    end
	  else
	    --Spring.Echo("chicken_control "..leader.." is spectator")
	    ChickenPlayers[GiveToTeam] = nil
	  end
	end
	GiveToTeam=GiveToTeam+1
	if (GiveToTeam > #ChickenPlayers) then
	  GiveToTeam = 1
	end
	curLoop=curLoop+1
	if (curLoop > MaxLoop) then
	  condition = false
	  if not anyone_not_spec then
	    --Spring.Echo("chicken_control gadget quit")
	    gadgetHandler:RemoveGadget() -- probably noone alive ?
	  end
	end
      end
    end
  end
-- -- now thats legacy - commander is not given in the first place
--   elseif (allyTeam == ChickenAllyTeam) then
--     local ud = UnitDefs[unitDefID]
--     if (ud.customParams.commtype) then
--       spDestroyUnit(unitID, false, true) -- bye bye commander
--     end
--   end
end

end
