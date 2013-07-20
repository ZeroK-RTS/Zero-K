local version = "0.1.0"

function gadget:GetInfo()
  return {
    name      = "Takeover",
    desc      = "KoTH remake, instead of instantly winning game for controlling center of the map, capture a unit that will help you crush all enemies... "..version,
    author    = "Tom Fyuri", -- also kudos to Sprung, KingRaptor, xponen and jK
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = -1,
    enabled   = true
  }
end

--[[ The Takeover, King of The Hill on steroids.
...inspired by detriment hideout and wolas...

  Changelog:
7 July 2013 - 0.0.1 beta - First version, not working in multiplayer, working singleplayer.
8 July 2013 - 0.0.2 beta - Recoded voting implementation, getting closer to smooth beta playing, working multiplayer.
9 July 2013 - 0.0.3 beta - Voting menu looks better, fontsize now is dynamic - name's should fit, vote menu should no longer re-appear during game, krow is water friendly, emp timers are synced and much more.
18 July 2013 - 0.1 - Entire code was rewritten from scrach in both widget and mostly gadget files. Too many changes to fit them in few words.
		     Because of this, I was not able to complete half the features I promised you guys, sorry.
]]--

-- TODO FIXME this is copy paste from halloween, it's only used to simulate unit berserk state, but it needs to be replaced with more sane AI that will try to attack players, but not finish them off!
-- this is also used to decide disputable vote results (when same amount of votes have multiple optios)!
-- Seed unsynced random number generator.
-- Credits https://github.com/tvo/craig/blob/master/LuaRules/Gadgets/craig/main.lua
if (math.randomseed ~= nil) then
  --local r = Spring.DiffTimers(Spring.GetTimer(), Script.CreateScream())	-- FIXME crashes with "invalid args" error
  math.random()
  --math.randomseed(r)
end

local string_nominate = 'takeover_nominate';
local string_vote_for = 'takeover_agree_with';
local spSendLuaRulesMsg	    = Spring.SendLuaRulesMsg
local spSendLuaUIMsg	    = Spring.SendLuaUIMsg

--SYNCED-------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then

local UnitList = { "scorpion", "dante", "armraven", "armbanth", "corcrw", "armorco", "funnelweb",
    "corgol", "corsumo", "armmanni", "armzeus", "armcrabe", "armcarry", "corbats", "armcomdgun", "armcybr", "corroy", "amphassault",
    "corhlt", "armanni", "cordoom", "cafus", "armbrtha", "corbhmth",
    "zenith", "mahlazer", "raveparty", "armcsa" }
local GraceList = { 0, 15, 45, 90, 120, 240, 300, 450, 600, 750, 817, 900}

local string_vote_start = "takeover_vote_start";
local string_vote_end = "takeover_vote_end";
local string_takeover_owner = "takeover_new_owner";
local string_takeover_unit_died = "takeover_unit_dead"

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local squareSize      = Game.squareSize

-- TODO figure out what I don't need anymore and remove
local random	= math.random
local round	= math.round
local floor	= math.floor
local min	= math.min
local max	= math.max
local abs	= math.abs
local spGetTeamInfo 	    = Spring.GetTeamInfo
local GaiaTeamID 	    = Spring.GetGaiaTeamID()
local GaiaAllyTeamID	    = select(6,spGetTeamInfo(GaiaTeamID))
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitTeam	    = Spring.GetUnitTeam
local spGetTeamUnits 	    = Spring.GetTeamUnits
local spGetUnitHealth	    = Spring.GetUnitHealth
local spSetUnitHealth	    = Spring.SetUnitHealth
local spTransferUnit        = Spring.TransferUnit
local spGetUnitIsDead	    = Spring.GetUnitIsDead
local spGiveOrderToUnit	    = Spring.GiveOrderToUnit
local spSetTeamResources    = Spring.SetTeamResources
local spGetTeamResources    = Spring.GetTeamResources
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spCreateUnit	    = Spring.CreateUnit
local spGetGroundHeight     = Spring.GetGroundHeight
local spSetHeightMap	    = Spring.SetHeightMap
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spGetAllyTeamStartBox = Spring.GetAllyTeamStartBox
local spSetUnitNoSelect     = Spring.SetUnitNoSelect
local spGetGameFrame	    = Spring.GetGameFrame
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetGameRulesParam   = Spring.GetGameRulesParam
local spSetGameRulesParam   = Spring.SetGameRulesParam
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetTeamList	    = Spring.GetTeamList 
local spEcho                = Spring.Echo

local spGetPlayerInfo	    = Spring.GetPlayerInfo
local GetAllyTeamList	    = Spring.GetAllyTeamList

local CMD_MOVE_STATE	= CMD.MOVE_STATE
local CMD_FIRE_STATE	= CMD.FIRE_STATE
local CMD_RECLAIM    	= CMD.RECLAIM
local CMD_REPAIR	= CMD.REPAIR
local CMD_ATTACK	= CMD.ATTACK
local CMD_FIGHT		= CMD.FIGHT
local CMD_RECLAIM	= CMD.RECLAIM
local CMD_LOAD_UNITS	= CMD.LOAD_UNITS
local CMD_OPT_SHIFT	= CMD.OPT_SHIFT
local CMD_INSERT	= CMD.INSERT
local CMD_REPEAT	= CMD.REPEAT
local CMD_SELFD		= CMD.SELFD

local OnBlockList = { -- you shall not be able to use these while unit is dormant
  [CMD_MOVE_STATE] = true,
  [CMD_FIRE_STATE] = true,
  [CMD_RECLAIM] = true,
  [CMD_LOAD_UNITS] = true,
  [CMD_REPAIR] = false,
  [CMD_SELFD] = true,
}

local TheUnits = {} -- should hold UnitID array
local MostMetalOwnerData = {} -- for every TheUnits i
local TheUnitsAreChained  = false
local DelayInFrames
local TimeLeftInSeconds
local PollActive = false

local PlayerList = {};
local NominationList = {};
local DEFAULT_CHOICE = {0, UnitDefNames["armzeus"].id, 240, 2} -- mortal dante (armorco) should probably fit better, but this zeus is immortal :)
local CAPTURE_RANGE = 256 -- capture range, you need to stand this close to begin unit capture process
local MostPopularChoice = DEFAULT_CHOICE -- center map detriment that wakes up after 5 minutes and is immortal while emped or timer > 0

local function lowerkeys(t)
  local tn = {}
  for i,v in pairs(t) do
    local typ = type(i)
    if type(v)=="table" then
      v = lowerkeys(v)
    end
    if typ=="string" then
      tn[i:lower()] = v
    else
      tn[i] = v
    end
  end
  return tn
end

local paralyzeOnMaxHealth = ((lowerkeys(VFS.Include"gamedata/modrules.lua") or {}).paralyze or {}).paralyzeonmaxhealth
local captureWeaponDefs, _ = include("LuaRules/Configs/capture_defs.lua")

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

local function GetPlayerPID(playerID)
  for i=1,#PlayerList do
    if (PlayerList[i].playerID == playerID) then
      return i
    end
  end
  return -1
end

local function UpdatePollData()
  -- update internal poll data
  spSetGameRulesParam("takeover_nominations", #NominationList)
  for i=1,#NominationList do
    spSetGameRulesParam("takeover_owner_nomination"..i, NominationList[i].playerID)
    spSetGameRulesParam("takeover_location_nomination"..i, NominationList[i].opts[1])
    spSetGameRulesParam("takeover_unit_nomination"..i, NominationList[i].opts[2])
    spSetGameRulesParam("takeover_grace_nomination"..i, NominationList[i].opts[3])
    spSetGameRulesParam("takeover_godmode_nomination"..i, NominationList[i].opts[4])
    spSetGameRulesParam("takeover_votes_nomination"..i, NominationList[i].votes)
  end -- this data is parsed by widget
  
  -- recalculate most popular option, quite easy, build a table of most wanted option
  local most_votes = 0
  for i=1,#NominationList do
    if (NominationList[i].votes > most_votes) then
      most_votes = NominationList[i].votes
    end
  end
  
  local most_voted = {}
  for i=1,#NominationList do
    if (NominationList[i].votes == most_votes) then
      most_voted[#most_voted+1] = i
    end
  end
    
  if (#most_voted == 0) then -- hello default choices
    MostPopularChoice = DEFAULT_CHOICE -- center map detriment that wakes up after 5 minutes and is immortal while emped or timer > 0
    spSetGameRulesParam("takeover_winner_owner", -1) -- -1 means springiee or default
    spSetGameRulesParam("takeover_winner_opts1", 0)
    spSetGameRulesParam("takeover_winner_opts2", UnitDefNames["armorco"].id)
    spSetGameRulesParam("takeover_winner_opts3", 300)
    spSetGameRulesParam("takeover_winner_opts4", id)
    spSetGameRulesParam("takeover_winner_votes", 0)
  elseif (#most_voted == 1) then -- hello sole winner
    most_voted = most_voted[1]
    MostPopularChoice = {
      NominationList[most_voted].opts[1],
      NominationList[most_voted].opts[2],
      NominationList[most_voted].opts[3],
      NominationList[most_voted].opts[4],
    };
    spSetGameRulesParam("takeover_winner_owner", NominationList[most_voted].playerID)
    spSetGameRulesParam("takeover_winner_opts1", NominationList[most_voted].opts[1])
    spSetGameRulesParam("takeover_winner_opts2", NominationList[most_voted].opts[2])
    spSetGameRulesParam("takeover_winner_opts3", NominationList[most_voted].opts[3])
    spSetGameRulesParam("takeover_winner_opts4", NominationList[most_voted].opts[4])
    spSetGameRulesParam("takeover_winner_votes", most_votes)
  else
    spSetGameRulesParam("takeover_winner_owner", -2) -- -2 means random out of most popular array
    spSetGameRulesParam("takeover_winner_opts1", -1)
    spSetGameRulesParam("takeover_winner_opts2", -1)
    spSetGameRulesParam("takeover_winner_opts3", -1)
    spSetGameRulesParam("takeover_winner_opts4", -1)
    spSetGameRulesParam("takeover_winner_votes", most_votes)
    MostPopularChoice = { "random", most_voted } -- this means, we will decide winner on gamestart
  end
end

local function PlayerAgreeWith(playerID, name, line)
  words={}
  for word in line:gmatch("[^%s]+") do words[#words+1]=word end
  if (#words ~= 2) then return end
  local Nominator = tonumber(words[2])
  local notfound, TPID = GetPlayerPID(Nominator)
  if notfound then return end
  local PID = GetPlayerPID(playerID)
  if PID == -1 then
    PlayerList[#PlayerList+1] = {
      name = name;
      playerID = playerID;
      nomination = PlayerList[TPID].nomination;
    };
    NominationList[PlayerList[TPID].nomination].votes = NominationList[PlayerList[TPID].nomination].votes+1;
  else
--     if (PlayerList[PID].nomination) then
    NominationList[PlayerList[PID].nomination].votes = NominationList[PlayerList[PID].nomination].votes-1;
--     end
    PlayerList[PID].nomination = PlayerList[TPID].nomination;
    NominationList[PlayerList[TPID].nomination].votes = NominationList[PlayerList[TPID].nomination].votes+1;
  end
  UpdatePollData()
end

local function NominateNewRule(playerID, name, line)
  words={}
  for word in line:gmatch("[^%s]+") do words[#words+1]=word end
  if (#words ~= 5) then return end
  -- extract stuff and check for validity
  local location = tonumber(words[2])
  local unit = tonumber(words[3])
  local grace = tonumber(words[4])
  local godmode = tonumber(words[5])
  if (location == nil) or (grace == nil) or (godmode == nil) or (UnitDefs[unit] == nil) then return end -- safe check complete
  local PID = GetPlayerPID(playerID)
  if PID == -1 then
    -- is there any nomination like the one player nominated?
    local nom = #NominationList+1
    for i=1,#NominationList do
      if (NominationList[i].opts[1] == location) and (NominationList[i].opts[2] == unit) and (NominationList[3].opts[1] == grace) and (NominationList[i].opts[4] == godmode) then
	-- oh there is
	nom = i
	break
      end
    end
    if (nom == #NominationList+1) then
      NominationList[nom] = {
	playerID = playerID,
	opts = { location, unit, grace, godmode },
	votes = 1,
      };
    end
    PlayerList[#PlayerList+1] = {
      name = name;
      playerID = playerID;
      nomination = nom
    };
  else -- if player is making a new nomination, destroy his previous nomination - make players abandon his new rules.
    local ThisPlayer = PlayerList[PID].nomination
    for i=1,#PlayerList do
      if (i ~= PID) then
	if (PlayerList[i].nomination == ThisPlayer) then
	  PlayerList[i].nomination = nil
	end
      end
    end
    NominationList[ThisPlayer].opts = { location, unit, grace, godmode };
  end
  UpdatePollData()
end

function gadget:Initialize()
  if (not modOptions.zkmode) or (tostring(modOptions.zkmode) ~= "takeover") then
    gadgetHandler:RemoveGadget()
  end
  -- should I also check if game is zero-k or not?
  
  PollActive = true
  spSetGameRulesParam("takeover_vote", 1)
end

local function Paralyze(unitID, seconds) -- original function belonged to xponen but it was producing not correct result, sorry xponen, code was rewriten
  local maxHealth = select(2,spGetUnitHealth(unitID)); local paralyze = maxHealth+maxHealth*(seconds+0.6)/37.5; spSetUnitHealth(unitID, { paralyze = paralyze })
end -- xponen: its like a famous scientist say: the world work with constant 37.5 with no apparent reason at all!

local function hqHeightMapFunc(centerX, centerZ, terraHeight) -- function stolen from gamemode_dota.lua idk who coded this
  local centerHeight = spGetGroundHeight(centerX, centerZ)
  local wantedHeight
  local size = 144

  for z = -size, size, squareSize do
    for x = -size, size, squareSize do
      wantedHeight = centerHeight + min((size - max(abs(x), abs(z))) * (terraHeight / 64), terraHeight)
--       if (wantedHeight > spGetGroundHeight(centerX + x, centerZ + z)) then
      spSetHeightMap(centerX + x, centerZ + z, wantedHeight)
--       end
    end
  end
end

local function GetTimeFormatted(time, addzeros)
  local delay_minutes = math.floor(time/60) -- TODO optimise this, this can be done lot better and faster
  local delay_seconds = time-delay_minutes*60
  local time_text = "   no\ndelay"
  if (time > 0) then
    if (0 == delay_seconds) and (delay_minutes > 0) then
      time_text = delay_minutes.."m"
    elseif (delay_minutes == 0) then
      time_text = delay_seconds.."s"
    else
      time_text = delay_minutes.."m\n"..delay_seconds.."s"
    end -- should be possible to do this much faster
  end
  if addzeros then
    if (delay_minutes < 10) then 
      delay_minutes = "0"..delay_minutes
    end
    if (delay_seconds < 10) then
      delay_seconds = "0"..delay_seconds
    end
  end
  return delay_minutes, delay_seconds, time_text
end

function gadget:GameStart() -- i didn't want to clutter this code with many params, also it's possible to do everything inside this callback
  if type(MostPopularChoice) == "table" then
    if (MostPopularChoice[1] == "random") then
      MostPopularChoice = MostPopularChoice[2][random(1,# MostPopularChoice[2])]
      spSetGameRulesParam("takeover_winner_owner", NominationList[MostPopularChoice].playerID)
    end
  else
    spSetGameRulesParam("takeover_winner_owner", 0)
  end
--   if (#NominationList > 0) then
--     MostPopularChoice = {
--       NominationList[MostPopularChoice][1],
--       NominationList[MostPopularChoice][2],
--       NominationList[MostPopularChoice][3],
--       NominationList[MostPopularChoice][4],
--     };
--   end
  spSetGameRulesParam("takeover_winner_opts1", MostPopularChoice[1])
  spSetGameRulesParam("takeover_winner_opts2", MostPopularChoice[2])
  spSetGameRulesParam("takeover_winner_opts3", MostPopularChoice[3])
  spSetGameRulesParam("takeover_winner_opts4", MostPopularChoice[4])
  DelayInFrames = 32*MostPopularChoice[3];
  TimeLeftInSeconds = MostPopularChoice[3];
  spSetGameRulesParam("takeover_timeleft", TimeLeftInSeconds)
  --- tell everyone what happened
  local loc_text = "at center";
  if (MostPopularChoice[1] == 1) then
    loc_text = "in spawn boxes";
  elseif (MostPopularChoice[1] == 2) then
    loc_text = "across map";
  end
  local time_text = select(3,GetTimeFormatted(MostPopularChoice[3], false))
  local god_text = "mortal";
  if (MostPopularChoice[4] == 1) then
    god_text = " semi-mortal";
  elseif (MostPopularChoice[4] == 2) then
    god_text = "immortal";
  end
  spEcho("Takeover Vote Result: "..god_text.." "..UnitDefs[MostPopularChoice[2]].humanName.." being spawned "..loc_text.." and dormant for "..time_text..".");
  -- set up land for units, not if player's selected water unit, make it water then :)
  local ground = true -- flying or ground type, require little terraforming
  local ud = UnitDefs[MostPopularChoice[2]]
  --if (ud ~= nil) then
  if (ud.minWaterDepth > 0) then
    ground = false
  end
  local mapWidth = Game.mapSizeX
  local mapHeight = Game.mapSizeZ
  local SpawnPos = { { mapWidth/2, mapHeight/2 } } -- center, if map has no spawn boxes, then it's this
  
  local SpawnBoxes = {} -- TODO this code needs rewrite
  for _,allyTeam in ipairs(GetAllyTeamList()) do
    local x1, z1, x2, z2 = spGetAllyTeamStartBox(allyTeam)
    if x1 then
      local width = abs(x2-x1)
      local height = abs(z2-z1)
      if (width < mapWidth) or (height < mapHeight) then
	SpawnBoxes[#SpawnBoxes+1] = {
	  --allyTeam = allyTeam,
	  x1 = x1, x2 = x2,
	  z1 = z1, z2 = z2,
	  centerx = (x1+x2)/2, 
	  centerz = (z1+z2)/2,
	  --width = width, height = height,
	}
      end
    end
  end
  
  if (#SpawnBoxes > 0) and (MostPopularChoice[1] > 0) then
    if (MostPopularChoice[1] == 1) then
      SpawnPos = {}
      for i=1,#SpawnBoxes do
	SpawnPos[i] = { SpawnBoxes[i].centerx, SpawnBoxes[i].centerz }
      end
    else -- this is kinda harder, need to detrimine 2 farthest centers x,y, and make units pos across
      local best_pair = nil
      for i=1,#SpawnBoxes do
	for j=1,#SpawnBoxes do
	  if (i~=j) then
	    if (best_pair == nil) then
	      best_pair = { i, j, disSQ(SpawnBoxes[i].x,SpawnBoxes[i].z,SpawnBoxes[j].x,SpawnBoxes[j].z) }
	    else
	      local my_dist = disSQ(SpawnBoxes[i].x,SpawnBoxes[i].z,SpawnBoxes[j].x,SpawnBoxes[j].z)
	      if (my_dist > best_pair[3]) then
		best_pair = { i, j, my_dist }
	      end
	    end
	  end
	end
      end
      -- now i need to determine farthest points
      -- verticaly?
      local ver_dist = disSQ(mapWidth/2, SpawnBoxes[best_pair[1]].centerx, mapHeight*0.75, SpawnBoxes[best_pair[2]].centerz) + disSQ(mapWidth/2, SpawnBoxes[best_pair[1]].centerx, mapHeight*0.75, SpawnBoxes[best_pair[2]].centerz)
      local hor_dist = disSQ(mapWidth*0.75, SpawnBoxes[best_pair[1]].centerx, mapHeight/2, SpawnBoxes[best_pair[2]].centerz) + disSQ(mapWidth*0.75, SpawnBoxes[best_pair[1]].centerx, mapHeight/2, SpawnBoxes[best_pair[2]].centerz)
      if (ver_dist > hor_dist) then
	SpawnPos = {
	  {mapWidth/2, mapHeight*0.25},
	  {mapWidth/2, mapHeight/2},
	  {mapWidth/2, mapHeight*0.75},
	}
      else -- apparently horizontally is better
	SpawnPos = {
	  {mapWidth*0.25, mapHeight/2},
	  {mapWidth/2, mapHeight/2},
	  {mapWidth*0.75, mapHeight/2},
	}
      end
    end
  elseif (MostPopularChoice[1] == 2) then
    local horizon = 0
    if (mapWidth == mapHeight) then
      horizon = random(0,1) -- dem no spawn pos.. so unit spawn pos shall be random ?
    elseif (mapWidth > mapHeight) then
      horizon = 1
    end
    if (horizon == 1) then
      SpawnPos = {
	{mapWidth*0.25, mapHeight/2},
	{mapWidth/2, mapHeight/2},
	{mapWidth*0.75, mapHeight/2},
      }
    else
      SpawnPos = {
	{mapWidth/2, mapHeight*0.25},
	{mapWidth/2, mapHeight/2},
	{mapWidth/2, mapHeight*0.75},
      }
    end
  end
  
  -- TODO rewrite so groundheight is actually averaged...
  if (ground) then
    for i=1,#SpawnPos do
      local up = spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2])-waterLevel
      if (up > 0) then up = 20; else up = -up+20; end
      spSetHeightMapFunc(hqHeightMapFunc, SpawnPos[i][1], SpawnPos[i][2], up)
    end
  else
    for i=1,#SpawnPos do
      local down = spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2])-waterLevel
      if (down > 0) then down = -down-20; else down = -20; end
      spSetHeightMapFunc(hqHeightMapFunc, SpawnPos[i][1], SpawnPos[i][2], down)
    end
  end
  
  -- spawn units
  for i=1,#SpawnPos do
    local unit = spCreateUnit(MostPopularChoice[2], SpawnPos[i][1], spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2]), SpawnPos[i][2],"n",GaiaTeamID)
    if (unit ~= nil) then
      TheUnits[#TheUnits+1] = unit
      --MostMetalOwnerData[#TheUnits] = {} -- add capture data -- moved to gameframe
      spSetGameRulesParam("takeover_team_unit"..#TheUnits, GaiaTeamID)
      spSetGameRulesParam("takeover_allyteam_unit"..#TheUnits, GaiaAllyTeamID)
      local health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(unit)
      local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
      local emp = (paralyzeDamage or 0)
      local hp  = (health or 0)
      spSetGameRulesParam("takeover_maxhp_unit"..#TheUnits, maxHealth)
      spSetGameRulesParam("takeover_hp_unit"..#TheUnits, hp)
      spSetGameRulesParam("takeover_emphp_unit"..#TheUnits, empHP)
      spSetGameRulesParam("takeover_emp_unit"..#TheUnits, emp)
      spSetUnitNoSelect(unit, true)
      spGiveOrderToUnit(unit, CMD_FIRE_STATE, {0}, {}) -- don't attack
      spGiveOrderToUnit(unit, CMD_MOVE_STATE, {0}, {}) -- don't move
      --Paralyze(unit, MostPopularChoice[3]) -- no need anymore
      spSetGameRulesParam("takeover_siege_unit"..i, 0)
      spSetGameRulesParam("takeover_id_unit"..#TheUnits, unit)
    end
  end
  if (#TheUnits > 0) then
    TheUnitsAreChained = true
  end
  
  PollActive = false -- UNCOMMENT ME
  spSetGameRulesParam("takeover_units",#TheUnits)
  spSetGameRulesParam("takeover_vote", 0) -- UNCOMMENT ME
end

local function GiveUnitToMVP(unit,allyTeam) -- TODO rewrite this function to make it perfect, ideal, marvelous as it can ever be
  local teams = {}
  for _,t in pairs(spGetTeamList()) do
    local allyteam = select(6,spGetTeamInfo(t))
    if allyTeam == allyteam then
      teams[#teams+1] = t
    end
  end
  local mvp
  for i=1,#teams do
    local id,elo
    local _,id,_,isAI = spGetTeamInfo(teams[i])
    elo = select(10,spGetPlayerInfo(id))
    elo = (elo.elo ~= nil) and elo.elo or 1000 -- this should make it look like AI has elo of 1000, right?
    if (not isAI) then
      elo = elo + 250 -- this is for singleplayer support
    end
    if (mvp == nil) then
      mvp = { id = id, team = teams[i], elo = elo }
    elseif (mvp.elo < elo) then
      mvp = { id = id, team = teams[i], elo = elo }
    end
  end
  spTransferUnit(unit, mvp.team, false);
end

function gadget:GameFrame (f)
  if (TheUnitsAreChained) and (f == DelayInFrames) then --FIXME probably better if equation can be done, or this section can be rewritten somehow
    spSetGameRulesParam("takeover_timeleft", TimeLeftInSeconds)
    TheUnitsAreChained = false;
    local TheUnit
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= nil) then
	spSetUnitNoSelect(TheUnit,false)
	if (spGetUnitTeam(TheUnit) == GaiaTeamID) then
	  spGiveOrderToUnit(TheUnit, CMD_REPEAT,{1},{})
	  spGiveOrderToUnit(TheUnit, CMD_FIRE_STATE, {2},{})
	  spGiveOrderToUnit(TheUnit, CMD_MOVE_STATE,{2},{})
	  local xmin,xmax
	  local zmin,zmax
	  xmin = floor(Game.mapSizeX/2 - Game.mapSizeX/6)
	  zmin = floor(Game.mapSizeZ/2 - Game.mapSizeZ/6)
	  xmax = floor(Game.mapSizeX/2 + Game.mapSizeX/6)
	  zmax = floor(Game.mapSizeZ/2 + Game.mapSizeZ/6)
	  for i=1,random(1,10) do
	    x = random(xmin,xmax)
	    z = random(zmin,zmax)
	    spGiveOrderToUnit(TheUnit,CMD_INSERT,{-1,CMD_FIGHT,CMD_OPT_SHIFT,x,0,z},{"alt"});
	  end
	end
      end
    end
  end
  if ((f%32)==0) then
    if (TimeLeftInSeconds > 0) then
      TimeLeftInSeconds = TimeLeftInSeconds - 1
      spSetGameRulesParam("takeover_timeleft", TimeLeftInSeconds)
    end
  end
  if ((f%15)==0) then -- should i implement actual timers here instead of frame%number? just like gui has?
    local health,maxHealth,paralyzeDamage,empHP,emp,hp
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= nil) then
	health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(TheUnit)
	empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
	emp = (paralyzeDamage or 0)
	hp  = (health or 0)
	spSetGameRulesParam("takeover_maxhp_unit"..i, maxHealth)
	spSetGameRulesParam("takeover_hp_unit"..i, hp)
	spSetGameRulesParam("takeover_emphp_unit"..i, empHP)
	spSetGameRulesParam("takeover_emp_unit"..i, emp)
	emp = emp/empHP
	-- also need to check capture conditions
	-- how does this work? if your unit is near TheUnit, it adds you to list and every second you earn 1 score point, first one getting 3 points
	-- if multiple players get 3 points, the best elo player that still has units near TheUnit gets it, notice only team with highest metalcost near TheUnit gets 1 score point
	-- if you don't but still have units, you keep your score, but you have less than 3 seconds to kill other player's army, in other words your progress is paused
	if (emp >= 1) then
	  if (MostMetalOwnerData[i] == nil) then MostMetalOwnerData[i] = {} end
	  spSetGameRulesParam("takeover_siege_unit"..i, 1)
    	  local x,y,z = spGetUnitPosition(TheUnit)
	  local units = spGetUnitsInCylinder(x, z, CAPTURE_RANGE)
	  local score = {}
	  if (#units > 0) then
	    for j=1,#units do
	      local unitID = units[j]
	      if (unitID ~= TheUnit) then
		local unitAllyTeam = spGetUnitAllyTeam(unitID)
		if (score[unitAllyTeam] == nil) then
		  score[unitAllyTeam] = 0
		end
		score[unitAllyTeam] = score[unitAllyTeam] + UnitDefs[spGetUnitDefID(unitID)].metalCost;
-- 		Spring.Echo(UnitDefs[spGetUnitDefID(unitID)].humanName.." is in capture range.")
	      end
	    end
	  end
	  local best_score, winner_allyteam
	  for allyteam,sc in pairs(score) do -- TODO get rid of the pairs and replace with smth like for i=1,n do
-- 	    Spring.Echo("Ally team: "..allyteam.." with "..sc.." metalcost value around unit.")
	    if (best_score == nil) or (sc > best_score) then
	      best_score = sc
	      winner_allyteam = allyteam
	    end
	  end
	  -- why this? this will make it sure that if both players have same metalcost value near unit if it will change sides unfairly, but rather enemy forces hinder capture process
	  for allyteam,sc in pairs(score) do -- TODO get rid of the pairs and replace with smth like for i=1,n do
	    if (best_score == sc) and (allyteam ~= winner_allyteam) then
	      winner_allyteam = nil
	      break
	    end
	  end
	  if (winner_allyteam ~= nil) then
	    if (MostMetalOwnerData[i][winner_allyteam] == nil) then
	      MostMetalOwnerData[i][winner_allyteam] = 1; -- score
	    else
	      MostMetalOwnerData[i][winner_allyteam] = MostMetalOwnerData[i][winner_allyteam] + 1;
	    end
	  end
	    -- I can check for most score in same gameframe :)
	  for allyteam,sc in pairs(MostMetalOwnerData[i]) do
	    if (sc == 3) then
	      GiveUnitToMVP(TheUnit,allyteam) -- that is if winner is only one... it should be one, right?
	      break
	    end
	  end
	elseif (emp < 0.8) then -- if unit is less than 80% emped, drop all capture progress for unit
	  if (MostMetalOwnerData[i] ~= nil) then
	    spSetGameRulesParam("takeover_siege_unit"..i, 0)
	    MostMetalOwnerData[i] = nil 
	  end
	end
      end -- why in gameframe? because units regen and i don't know if unitdamaged callback is called when unit gains health instead of losing
    end
  end
end

--function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
  if (MostPopularChoice[4] > 0) then
    local TheUnit
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= nil) and (TheUnit == unitID) then
        if (TheUnitsAreChained) and (weaponID) and (captureWeaponDefs[weaponID]) then
	  return 0; -- negates dommi damage awwwright
        end
	local health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(unitID)
	local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
	local emp = (paralyzeDamage or 0)/empHP
	local hp  = (health or 0)/maxHealth
	if (MostPopularChoice[4] == 2) then
	  if ((emp >= 1) or (TheUnitsAreChained)) then
	    spSetUnitHealth(unitID, {health = health+floor(damage+1)}); -- you may ask yourself why, the answer is: i do not want to block emp/slow damage, if you know way to make this better, contact me
	  elseif (maxHealth/10 > health) then 
	    spSetUnitHealth(unitID, {health = maxHealth/10+floor(damage+1)});
	  elseif (health-damage < maxHealth/10) then
	    spSetUnitHealth(unitID, {health = maxHealth/10+floor(health-maxHealth/10+1)});
	  end
	elseif (MostPopularChoice[4] == 1) then
	  if ((emp >= 1) or (TheUnitsAreChained)) then
	    spSetUnitHealth(unitID, {health = health+floor(damage+1)});
	  end
	end
	local health = select(1,spGetUnitHealth(unitID))
	if (health > maxHealth) then
	  spSetUnitHealth(unitID, {health = maxHealth})
	end
      end
    end
  else
    gadgetHandler:RemoveCallIn("UnitPreDamaged")
  end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= nil) and (TheUnit == unitID) then
      spSetGameRulesParam("takeover_team_unit"..i, newTeamID)
      spSetGameRulesParam("takeover_allyteam_unit"..i, select(6,spGetTeamInfo(newTeamID)))
      if (TheUnitsAreChained) then
	spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {}) -- don't attack
	spGiveOrderToUnit(unitID, CMD_MOVE_STATE, {0}, {}) -- don't move
      end
    end
  end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam) -- TODO detect if TheUnits were resurrected :)
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (unitID == TheUnit) then
      spSetGameRulesParam("takeover_id_unit"..i, -1)
      spSetGameRulesParam("takeover_team_unit"..i, -1)
      spSetGameRulesParam("takeover_allyteam_unit"..i, -1)
      spSetGameRulesParam("takeover_maxhp_unit"..i, 1)
      spSetGameRulesParam("takeover_hp_unit"..i, 0)
      spSetGameRulesParam("takeover_emphp_unit"..i, 1)
      spSetGameRulesParam("takeover_emp_unit"..i, 0)
      TheUnits[i] = nil
    end
  end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= nil) and (unitID == TheUnit) and (TheUnitsAreChained) and (TimeLeftInSeconds>0) then
      Paralyze(transportID,TimeLeftInSeconds)
    end
  end
end

-- idk what are these used for and how, my guess it's a filter so only "true" listen commands are processed by allowcommand &/or commandfallback
-- function gadget:AllowCommand_GetWantedCommand()
--   return {[CMD_ATTACK] = true, [CMD_RECLAIM] = true, [CMD_LOAD_UNITS] = true}
-- end
-- 
-- function gadget:AllowCommand_GetWantedUnitDefID()
--   return true
-- end

-- TODO FIXME i need some help figuring out how to block area load units command (exclude TheUnit from picking up) help wanted!
-- also I don't know it blocks AI control over unit
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions) --, fromSynced)
  -- you shall not use the dormant unit
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= nil) then
      if (TheUnitsAreChained) then
	if (unitID == TheUnit) then
	  return false
	elseif (OnBlockList[cmdID]) and (#cmdParams == 1) and (cmdParams[1] == TheUnit) then -- you shall not reclaim me or touch me      
	  return false
	end
      elseif (MostPopularChoice[4] > 0) then
	if (unitID == TheUnit) and (cmdID == CMD_SELFD) then
	  return false
	end
      end
    end
  end
  return true
end

function gadget:RecvLuaMsg(line, playerID)
  local name, _, spectator = spGetPlayerInfo(playerID)
  if PollActive and (not spectator) then
    if line:find(string_vote_for) then
      PlayerAgreeWith(playerID, name, line)
    elseif line:find(string_nominate) then
      NominateNewRule(playerID, name, line)
    end
  end
end

else --------------------------------------------------------------------------------------------------- unsycned

local function ParseVote(cmd, line, words, playerID)
  if (#words == 2) then
    local str = string_vote_for.." "..words[1].." "..words[2]
    spSendLuaRulesMsg(str)
  elseif (#words == 5) then
    local str = string_nominate.." "..words[1].." "..words[2].." "..words[3].." "..words[4]
    spSendLuaRulesMsg(str)
  end
end
  
function gadget:Initialize()
  if (not Spring.GetModOptions().zkmode) or (tostring(Spring.GetModOptions().zkmode) ~= "takeover") then
      gadgetHandler:RemoveGadget()
  end
  gadgetHandler:AddChatAction(string_nominate, ParseVote)
  gadgetHandler:AddChatAction(string_vote_for, ParseVote)
end

end