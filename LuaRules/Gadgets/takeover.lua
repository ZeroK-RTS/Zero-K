local version = "0.2.0"

function gadget:GetInfo()
  return {
    name      = "Takeover",
    desc      = "KoTH remake, instead of instantly winning game for controlling center of the map, capture a unit that will help you crush all enemies... "..version,
    author    = "Tom Fyuri", -- also kudos to Sprung, KingRaptor, xponen and jK
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = 1,
    enabled   = true
  }
end

--[[ The Takeover, King of The Hill on steroids.
...inspired by detriment hideout and wolas...

  Changelog:
7 July 2013 - 0.0.1 beta - First version, not working in multiplayer, working singleplayer.
8 July 2013 - 0.0.2 beta - Recoded voting implementation, getting closer to smooth beta playing, working multiplayer.
9 July 2013 - 0.0.3 beta - Voting menu looks better, fontsize now is dynamic - name's should fit, vote menu should no longer re-appear during game, krow is water friendly, emp timers are synced and much more.
20 July 2013 - 0.1.0 - Entire code was rewritten from scrach in both widget and mostly gadget files. Too many changes to fit them in few words.
		     Because of this, I was not able to complete half the features I promised you guys, sorry.
25 July 2013 - 0.2.0 - The promised feature list is slowly getting completed and as well as most bugs are getting fixed. Suggestions are also getting implemented.
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
local string_upvote = 'takeover_upvote';
local string_downvote = 'takeover_downvote';
local spSendLuaRulesMsg	    = Spring.SendLuaRulesMsg
local spSendLuaUIMsg	    = Spring.SendLuaUIMsg

--SYNCED-------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
  
local Config = VFS.Include("LuaRules/Configs/takeover_config.lua") and VFS.Include("LuaRules/Configs/takeover_config.lua") or nil
local UnitList = Config and Config.Units or {}
local GraceList = Config and Config.Delays or {}

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local squareSize      = Game.squareSize
local mapWidth
local mapHeight

-- TODO figure out what I don't need anymore and remove
local random	= math.random
local round	= math.round
local floor	= math.floor
local ceil	= math.ceil
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
local spCreateUnit	    = Spring.CreateUnit
local spDestroyUnit	    = Spring.DestroyUnit
local spGetGroundHeight     = Spring.GetGroundHeight
local spSetHeightMap	    = Spring.SetHeightMap
local spSetHeightMapFunc    = Spring.SetHeightMapFunc
local spGetAllyTeamStartBox = Spring.GetAllyTeamStartBox
local spSetUnitNoSelect     = Spring.SetUnitNoSelect
local spGetGameFrame	    = Spring.GetGameFrame
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetGameRulesParam   = Spring.GetGameRulesParam
local spSetGameRulesParam   = Spring.SetGameRulesParam
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetTeamList	    = Spring.GetTeamList 
local spEcho                = Spring.Echo

local spGetPlayerInfo	    = Spring.GetPlayerInfo
local spGetAllyTeamList	    = Spring.GetAllyTeamList

local CMD_MOVE_STATE	= CMD.MOVE_STATE
local CMD_FIRE_STATE	= CMD.FIRE_STATE
local CMD_RECLAIM    	= CMD.RECLAIM
local CMD_REPAIR	= CMD.REPAIR
local CMD_ATTACK	= CMD.ATTACK
local CMD_GUARD		= CMD.GUARD
local CMD_FIGHT		= CMD.FIGHT
local CMD_STOP          = CMD.STOP
local CMD_RECLAIM	= CMD.RECLAIM
local CMD_LOAD_UNITS	= CMD.LOAD_UNITS
local CMD_OPT_SHIFT	= CMD.OPT_SHIFT
local CMD_INSERT	= CMD.INSERT
local CMD_REPEAT	= CMD.REPEAT
local CMD_SELFD		= CMD.SELFD
local CMD_IDLEMODE	= CMD.IDLEMODE
local CMD_ONOFF		= CMD.ONOFF

local OnBlockList = { -- you shall not be able to use these while unit is dormant
  [CMD_MOVE_STATE] = true,
  [CMD_FIRE_STATE] = true,
  [CMD_RECLAIM] = true,
  [CMD_LOAD_UNITS] = true,
  [CMD_REPAIR] = false,
  [CMD_SELFD] = true,
}

local TheUnits = {}
local MostMetalOwnerData = {} -- for every TheUnits i
local UnitNoOverhealData = {}
local ObjectiveData = {} -- for cap data

local TheUnitsAreChained  = false
local DelayInFrames
local TimeLeftInSeconds
local PollActive = false

local NominationList = {};
local DEFAULT_CHOICE = Config and Config.DEFAULT_CHOICE or nil
if DEFAULT_CHOICE then
  DEFAULT_CHOICE[2] = UnitDefNames[DEFAULT_CHOICE[2].."_tq"].id
end
local CAP_POINTS_PER_SEC = 0.5 -- 30/16 actually?, but i round it a bit then?
local MostPopularChoice = DEFAULT_CHOICE -- center map detriment that wakes up after 5 minutes and is immortal while emped or timer > 0

local zerocapturepowerunits = {
  [ UnitDefNames['terraunit'].id ] = true,
  [ UnitDefNames['pw_generic'].id ] = true,
  [ UnitDefNames['pw_hq'].id ] = true,
  [ UnitDefNames['tele_beacon'].id ] = true,
}

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
-- local captureWeaponDefs, _ = include("LuaRules/Configs/capture_defs.lua")
local _, thingsWhichAreDrones = include "LuaRules/Configs/drone_defs.lua"

local CopyTable = Spring.Utilities.CopyTable

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

local function UpdatePollData()
  local most_score = 0
  local worst_score = 0
  for i=1,#NominationList do
    if (NominationList[i].upvotes_count > most_score) then
      most_score = NominationList[i].upvotes_count
    end
    if (NominationList[i].downvotes_count > worst_score) then
      worst_score = NominationList[i].downvotes_count
    end
  end
  
  -- sort poll
  local NewNominationList = {}
  local j = most_score
  while (j >= -worst_score) do
    for nom,data in pairs(NominationList) do
      if data.score == j then
	NewNominationList[#NewNominationList+1] = CopyTable(NominationList[nom], true)
      end
    end
    j=j-1
  end
  NominationList = NewNominationList    
  
  -- update internal poll data
  local ok_score = 0
  spSetGameRulesParam("takeover_nominations", #NominationList)
  for i=1,#NominationList do
    spSetGameRulesParam("takeover_owner_nomination"..i, NominationList[i].ownerID)
    spSetGameRulesParam("takeover_location_nomination"..i, NominationList[i].opts[1])
    spSetGameRulesParam("takeover_unit_nomination"..i, NominationList[i].opts[2])
    spSetGameRulesParam("takeover_grace_nomination"..i, NominationList[i].opts[3])
    spSetGameRulesParam("takeover_godmode_nomination"..i, NominationList[i].opts[4])
    spSetGameRulesParam("takeover_upvotes_nomination"..i, NominationList[i].upvotes_count)
    spSetGameRulesParam("takeover_downvotes_nomination"..i, NominationList[i].downvotes_count)
    -- update info regarding who votes for what
    local uplist = 0
    for pid,_ in pairs(NominationList[i].upvotes) do
      uplist=uplist+1
      spSetGameRulesParam("takeover_upvotepid_nomination"..i.."_"..uplist, pid)
    end
    local downlist = 0
    for pid,_ in pairs(NominationList[i].downvotes) do
      downlist=downlist+1
      spSetGameRulesParam("takeover_upvotepid_nomination"..i.."_"..downlist, pid)
    end
    spSetGameRulesParam("takeover_score_nomination"..i, NominationList[i].score)
  end -- this data is parsed by widget
  local ok_score = math.floor(most_score-worst_score)*0.6 -- absolute winners if 60% of server votes for the nomination
  
  -- find ok options
  local most_voted = {}
  for i=1,#NominationList do
    if (NominationList[i].score >= ok_score) then
      most_voted[#most_voted+1] = i
    end
  end
    
  if (#most_voted == 0) then -- hello default choices
    MostPopularChoice = DEFAULT_CHOICE -- center map detriment that wakes up after 5 minutes and is immortal while emped or timer > 0
    spSetGameRulesParam("takeover_winner_owner", -1) -- -1 means springiee or default
    spSetGameRulesParam("takeover_winner_opts1", DEFAULT_CHOICE[1])
    spSetGameRulesParam("takeover_winner_opts2", DEFAULT_CHOICE[2])
    spSetGameRulesParam("takeover_winner_opts3", DEFAULT_CHOICE[3])
    spSetGameRulesParam("takeover_winner_opts4", DEFAULT_CHOICE[4])
    spSetGameRulesParam("takeover_winner_upvotes", -1)
    spSetGameRulesParam("takeover_winner_downvotes", -1)
  elseif (#most_voted == 1) then -- hello sole winner
    most_voted = most_voted[1]
    MostPopularChoice = {
      NominationList[most_voted].opts[1],
      NominationList[most_voted].opts[2],
      NominationList[most_voted].opts[3],
      NominationList[most_voted].opts[4],
    };
    spSetGameRulesParam("takeover_winner_owner", NominationList[most_voted].ownerID)
    spSetGameRulesParam("takeover_winner_opts1", NominationList[most_voted].opts[1])
    spSetGameRulesParam("takeover_winner_opts2", NominationList[most_voted].opts[2])
    spSetGameRulesParam("takeover_winner_opts3", NominationList[most_voted].opts[3])
    spSetGameRulesParam("takeover_winner_opts4", NominationList[most_voted].opts[4])
    spSetGameRulesParam("takeover_winner_upvotes", NominationList[most_voted].upvotes_count)
    spSetGameRulesParam("takeover_winner_downvotes", NominationList[most_voted].downvotes_count)
  else
    spSetGameRulesParam("takeover_winner_owner", -2) -- -2 means random out of most popular array
    spSetGameRulesParam("takeover_winner_opts1", -1)
    spSetGameRulesParam("takeover_winner_opts2", -1)
    spSetGameRulesParam("takeover_winner_opts3", -1)
    spSetGameRulesParam("takeover_winner_opts4", -1)
    spSetGameRulesParam("takeover_winner_upvotes", -1)
    spSetGameRulesParam("takeover_winner_downvotes", -1)
    MostPopularChoice = { "random", most_voted } -- this means, we will decide winner on gamestart
  end
end

local function UpvoteNomination(playerID, nom)
  if (NominationList[nom].upvotes[playerID] == nil) then
    if (NominationList[nom].downvotes[playerID] ~= nil) then
      NominationList[nom].downvotes[playerID] = nil
      NominationList[nom].downvotes_count = NominationList[nom].downvotes_count - 1
    else
      NominationList[nom].upvotes[playerID] = true
      NominationList[nom].upvotes_count = NominationList[nom].upvotes_count + 1
    end
    NominationList[nom].score = NominationList[nom].upvotes_count - NominationList[nom].downvotes_count
    return true
  end
  return false
end

local function DownvoteNomination(playerID, nom)
  if (NominationList[nom].downvotes[playerID] == nil) then
    if (NominationList[nom].upvotes[playerID] ~= nil) then
      NominationList[nom].upvotes[playerID] = nil
      NominationList[nom].upvotes_count = NominationList[nom].upvotes_count - 1
    else
      NominationList[nom].downvotes[playerID] = true
      NominationList[nom].downvotes_count = NominationList[nom].downvotes_count + 1
    end
    NominationList[nom].score = NominationList[nom].upvotes_count - NominationList[nom].downvotes_count
    return true
  end
  return false
end

local function CreateNomination(playerID, location, unit, grace, godmode)
  NominationList[#NominationList+1] = {
    ownerID = playerID,
    opts = { location, unit, grace, godmode },
    upvotes = {},
    downvotes = {},
    upvotes_count = 0,
    downvotes_count = 0,
    score = nil, -- always recalculated, on updates, highest value = most promising nomination
  };
  return #NominationList
end

local function ParseParams(line)
  params={}
  for word in line:gmatch("[^%s]+") do params[#params+1]=tonumber(word) end
  return params  
end

local function PlayerUpVote(playerID, name, params)
  if (#params ~= 1) then return end
  local nom = tonumber(params[1])
  if (NominationList[nom] == nil) then return end
  if (UpvoteNomination(playerID, nom)) then UpdatePollData() end
end

local function PlayerDownVote(playerID, name, params)
  if (#params ~= 1) then return end
  local nom = tonumber(params[1])
  if (NominationList[nom] == nil) then return end
  if (DownvoteNomination(playerID, nom)) then UpdatePollData() end
end

local function NominateNewRule(playerID, name, params, spec)
  if (#params ~= 4) then return end
  -- extract stuff and check for validity
  local location = params[1]
  local unit = params[2]
  local grace = params[3]
  local godmode = params[4]
  if (location == nil) or (grace == nil) or (godmode == nil) or (UnitDefs[unit] == nil) or (UnitDefs[unit].customParams.tqobj ~= "true") then return end -- safe check complete
  -- is there any nomination like the one player nominated?
  local nom = nil
  for i=1,#NominationList do
    if (NominationList[i].opts[1] == location) and (NominationList[i].opts[2] == unit) and (NominationList[i].opts[3] == grace) and (NominationList[i].opts[4] == godmode) then
      -- oh there is
      nom = i
      break
    end
  end
  if (nom == nil) then
    -- create nomination
    nom = CreateNomination(playerID, location, unit, grace, godmode)
    if not spec then
      UpvoteNomination(playerID, nom)
    end
    UpdatePollData()
  else
    -- if there is already such nomination upvote it
    if (UpvoteNomination(playerID, nom)) then
      UpvoteNomination(playerID, nom)
      UpdatePollData()
    end
  end
end

function gadget:Initialize()
  if (not modOptions.zkmode) or (tostring(modOptions.zkmode) ~= "takeover") or (Config == nil) then
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
      spSetHeightMap(centerX + x, centerZ + z, wantedHeight)
    end
  end
end

local function GetTimeFormatted2(time)
  local delay_minutes = floor(time/60) -- TODO optimise this, this can be done lot better and faster
  local delay_seconds = time-delay_minutes*60
  local time_text = "no delay"
  if (time > 0) then
    if (0 == delay_seconds) and (delay_minutes > 0) then
      time_text = delay_minutes.."m"
    elseif (delay_minutes == 0) then
      time_text = delay_seconds.."s"
    else
      time_text = delay_minutes.."m "..delay_seconds.."s"
    end -- should be possible to do this much faster
  end
  return time_text
end

local function GetCapDataForCost(mcost)
  local me = mcost
  local radius = 0
  local mod = 0.5
  local submod = 0
  local steps = 0
  local score = 0
  while (me > 0) do
    steps=steps+1
    local t
    if (me > 500) then
      t = 500
    else
      t = me
    end
    radius = t*mod + radius
    me = me-t
    submod = submod + 0.05
    mod=mod*(0.5+submod)
    if (steps < 3) then
      score = score + 3
    elseif (steps < 6) then
      score = score + 1.5
    else
      score = score + 0.75
    end
  end
  score = score * 6
  if (score < 3) then
    score = 3
  end
  if (radius < 250) then
    radius = 250
  elseif (radius > 1337) then
    radius = 1337
  end
  return round(radius), score
end
-- few examples
-- cost - metal cost of unit
-- cap1 - contested time when unit is 0% emped (seconds)
-- cap2 - contested time when unit is 100% emped (seconds)
-- cap3 - contested time when unit has 10% health and 100% emped (seconds)
-- emp for every 1% you get 3% speed boost (so max mod - 300%)
-- damage for every 1.8% damaged, you get 1% speed boost (so max mod - 150%)
-- dominatrix damage, for every 1% dominatrix damage, you get 3% speed boost (so max mod is - 300%)
-- fully emped, damaged and 99% dominatrix capped detriment should be stolen within 35 seconds in the ring.
-- boosts accumulate
-- radius - capture radius, min 250, max 1337
--  cost	cap1		cap2		cap3		radius
--   320	18		6		4		250
--  1500	45		15		10		470
--  2200	63		21		14		538.64
--  3500	72		24		16		611.838125
--  6000	94.5		31.5		21		698.13505446875
-- 10500	135		45		30		1267.6975112885
-- 24000	256.5		85.5		57		1337
-- basically for every 1% of objective's emped state, most metalcost allyteam in circle gets 3.33% additional score points, which makes capping faster

local function InitializeObjective(unitID, index, ud, lockdown)
  ObjectiveData[unitID] = { index = index, capradius, capscore, siege = false, lastsiege = -1000, AllyTeamsProgress = {}, TeamsProgress = {}}
  local rad, score = GetCapDataForCost(ud.metalCost)
  ObjectiveData[unitID].capradius = rad
  spSetUnitRulesParam(unitID, "takeover_cap_range", round(rad), {public = true}) -- lol didn't know about public
  ObjectiveData[unitID].capscore = score
  spSetGameRulesParam("takeover_team_unit"..index, GaiaTeamID)
  spSetGameRulesParam("takeover_allyteam_unit"..index, GaiaAllyTeamID)
  local health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(unitID)
  local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
  local emp = (paralyzeDamage or 0)
  local hp  = (health or 0)
  spSetGameRulesParam("takeover_maxhp_unit"..index, maxHealth)
  spSetGameRulesParam("takeover_hp_unit"..index, ceil(hp))
  spSetGameRulesParam("takeover_emphp_unit"..index, empHP)
  spSetGameRulesParam("takeover_emp_unit"..index, ceil(emp))
  
  if (lockdown) then
    spSetUnitNoSelect(unitID, true)
    spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {}) -- don't attack
    spGiveOrderToUnit(unitID, CMD_MOVE_STATE, {0}, {}) -- don't move
    spGiveOrderToUnit(unitID, CMD_ONOFF, {0}, {}) -- don't work
    spGiveOrderToUnit(unitID, CMD_IDLEMODE, {0}, {}) -- don't fly
    spSetGameRulesParam("takeover_siege_unit"..index, 0)
  end
  spSetGameRulesParam("takeover_id_unit"..index, unitID)
  spSetGameRulesParam("takeover_udid_unit"..index, spGetUnitDefID(unitID))
  TheUnits[index] = unitID -- this has to be last, or errorz
end

function FindHighestPoint(x1,z1,x2,z2)
  local step = 20
  local bx, bz, h
  local x = x1
  local z = z1
  local bh = 0
  while (x <= x2) do
    while (z <= z2) do
      h = spGetGroundHeight(x,z)
      if (h > bh) then
	bh = h
	bx = x
	bz = z
      end
      z = z + step
    end
    x = x + step
  end
  return bx, bz
end

function gadget:GameStart() -- i didn't want to clutter this code with many params, also it's possible to do everything inside this callback
  if (type(MostPopularChoice) == "table") and (MostPopularChoice[1] == "random") then
    local most_voted = MostPopularChoice[2][random(1,# MostPopularChoice[2])]
    MostPopularChoice = {
      NominationList[most_voted].opts[1],
      NominationList[most_voted].opts[2],
      NominationList[most_voted].opts[3],
      NominationList[most_voted].opts[4],
    };
    spSetGameRulesParam("takeover_winner_owner", NominationList[most_voted].playerID)
  end
  spSetGameRulesParam("takeover_winner_opts1", MostPopularChoice[1])
  spSetGameRulesParam("takeover_winner_opts2", MostPopularChoice[2])
  spSetGameRulesParam("takeover_winner_opts3", MostPopularChoice[3])
  spSetGameRulesParam("takeover_winner_opts4", MostPopularChoice[4])
  DelayInFrames = 32*MostPopularChoice[3];
  TimeLeftInSeconds = MostPopularChoice[3];
  spSetGameRulesParam("takeover_timeleft", TimeLeftInSeconds)
  -- set up land for units, not if player's selected water unit, make it water then :)
  local ground = true -- flying or ground type, require little terraforming
  local ud = UnitDefs[MostPopularChoice[2]]
  if (ud.minWaterDepth > 0) then
    ground = false
  end
  mapWidth = Game.mapSizeX
  mapHeight = Game.mapSizeZ
  local SpawnPos = { { mapWidth/2, mapHeight/2 } } -- center, if map has no spawn boxes, then it's this
  
  local SpawnBoxes = {} -- TODO this code needs rewrite
  for _,allyTeam in ipairs(spGetAllyTeamList()) do
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
	  width = width, height = height,
	}
      end
    end
  end
  
  local spawn_type = 0 -- 0 unknown, 1 - sides (2 teams), 2 - corners (2/4 teams)
  if (#SpawnBoxes > 0) then -- merge this part with code-part below
    if (#SpawnBoxes == 2) then
      if (SpawnBoxes[1].width == SpawnBoxes[2].width) and (SpawnBoxes[1].height == SpawnBoxes[2].height) then
	spawn_type = 1
	if (SpawnBoxes[1].width <= mapWidth*0.6) and (SpawnBoxes[1].height <= mapHeight*0.6) then
	  spawn_type = 2
	end
      end
    elseif (#SpawnBoxes == 4) then
      if (SpawnBoxes[1].width == SpawnBoxes[2].width) and (SpawnBoxes[1].height == SpawnBoxes[2].height) and (SpawnBoxes[1].height == SpawnBoxes[3].height) and (SpawnBoxes[1].height == SpawnBoxes[3].height) and (SpawnBoxes[1].height == SpawnBoxes[4].height) and (SpawnBoxes[1].height == SpawnBoxes[4].height) then
	spawn_type = 1
	if (SpawnBoxes[1].width <= mapWidth*0.4) and (SpawnBoxes[1].height <= mapHeight*0.4) then
	  spawn_type = 2
	end
      end
    end
  end
  
  if (#SpawnBoxes > 0) and (MostPopularChoice[1] == 1) then -- spawn boxes choice
    SpawnPos = {}
    for i=1,#SpawnBoxes do
      SpawnPos[i] = { SpawnBoxes[i].centerx, SpawnBoxes[i].centerz }
    end
  elseif (MostPopularChoice[1] == 2) then -- 3 across map
    if (#SpawnBoxes == 4) and (spawn_type == 2) then
      MostPopularChoice[1] = 3 -- 4 teams in corners, cool ffa, why spoil it with 3 units when 2 teams won't get them for sure?
    else
      if (spawn_type == 2) then
	local horizon = random(0,1) -- TODO make it so it doesn't spawn in player boxes but rather chooses more distant locations :)
	if (horizon == 0) then
	  SpawnPos = {
	    {mapWidth/2, mapHeight/2},
	    {mapWidth*0.25, mapHeight*0.25},
	    {mapWidth*0.75, mapHeight*0.75},
	  }
	else
	  SpawnPos = {
	    {mapWidth/2, mapHeight/2},
	    {mapWidth*0.75, mapHeight*0.25},
	    {mapWidth*0.25, mapHeight*0.75},
	  }
	end
      elseif (spawn_type == 1) then -- teams utilise cross method as well
	local horizon = 0
	if (mapWidth == mapHeight) then
	  horizon = random(0,1) -- dem no spawn pos.. so unit spawn pos shall be random ?
	elseif (mapWidth > mapHeight) then
	  horizon = 1
	end
	if (horizon == 1) then
	  SpawnPos = {
	    {mapWidth/2, mapHeight/2},
	    {mapWidth*0.25, mapHeight/2},
	    {mapWidth*0.75, mapHeight/2},
	  }
	else
	  SpawnPos = {
	    {mapWidth/2, mapHeight/2},
	    {mapWidth/2, mapHeight*0.25},
	    {mapWidth/2, mapHeight*0.75},
	  }
	end
      else -- unknown type, random will do
	if (random(0,1) == 0) then
	  local horizon = random(0,1) -- TODO make it so it doesn't spawn in player boxes but rather chooses more distant locations :)
	  if (horizon == 0) then
	    SpawnPos = {
	      {mapWidth/2, mapHeight/2},
	      {mapWidth*0.25, mapHeight*0.25},
	      {mapWidth*0.75, mapHeight*0.75},
	    }
	  else
	    SpawnPos = {
	      {mapWidth/2, mapHeight/2},
	      {mapWidth*0.75, mapHeight*0.25},
	      {mapWidth*0.25, mapHeight*0.75},
	    }
	  end
	else
	  local horizon = 0
	  if (mapWidth == mapHeight) then
	    horizon = random(0,1) -- dem no spawn pos.. so unit spawn pos shall be random ?
	  elseif (mapWidth > mapHeight) then
	    horizon = 1
	  end
	  if (horizon == 1) then
	    SpawnPos = {
	      {mapWidth/2, mapHeight/2},
	      {mapWidth*0.25, mapHeight/2},
	      {mapWidth*0.75, mapHeight/2},
	    }
	  else
	    SpawnPos = {
	      {mapWidth/2, mapHeight/2},
	      {mapWidth/2, mapHeight*0.25},
	      {mapWidth/2, mapHeight*0.75},
	    }
	  end
	end
      end
    end
  elseif (MostPopularChoice[1] == 3) then -- 5 around map
    if (spawn_type <= 1) then -- diagonal
      SpawnPos = {
	{mapWidth/2, mapHeight/2},
	{mapWidth*0.25, mapHeight*0.25},
	{mapWidth*0.75, mapHeight*0.25},
	{mapWidth*0.75, mapHeight*0.75},
	{mapWidth*0.25, mapHeight*0.75},
      }
    else -- cross
      SpawnPos = {
	{mapWidth/2, mapHeight/2},
	{mapWidth/2, mapHeight*0.25},
	{mapWidth/2, mapHeight*0.75},
	{mapWidth*0.75, mapHeight/2},
	{mapWidth*0.25, mapHeight/2},
      }
    end
  else
    MostPopularChoice[1] = 0 -- failed to spawn somewhere
  end
  
  -- fix center positions, whenever generating spawn positions, whatever that may be, center pos should be first in array
  if (MostPopularChoice[1] ~= 1) then
    local mx = 160
    local mz = 160
    if (mx > mapWidth*0.02) then mx = round(mapWidth*0.02) end
    if (mz > mapHeight*0.02) then mz = round(mapHeight*0.02) end
    SpawnPos[1] = { FindHighestPoint(SpawnPos[1][1]-mx,SpawnPos[1][2]-mz,SpawnPos[1][1]+mx,SpawnPos[1][2]+mz) }
  end
  
  -- TODO instead of terra, if unit can fit in the boat, give him "special" boat (should copy immortality ability, if there is one), put unit on boat and let it "sail"
  --if (not ud.canMove) then -- water? nevermind water, spawn reef in the middle of the hill, it's okay! spawn bandit in the ocean? why not!
  for i=1,#SpawnPos do
    local y = spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2])
    if (y < 0) or (not ud.canMove) then
      local up = y-waterLevel
      if (up > 0) then up = 20; else up = -up+20; end
      spSetHeightMapFunc(hqHeightMapFunc, SpawnPos[i][1], SpawnPos[i][2], up)
    end
  end
  --end
--   else
--     for i=1,#SpawnPos do
--       local down = spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2])-waterLevel
--       if (down > 0) then down = -down-20; else down = -20; end
--       spSetHeightMapFunc(hqHeightMapFunc, SpawnPos[i][1], SpawnPos[i][2], down)
--     end
--   end
  
  -- spawn units
  for i=1,#SpawnPos do
--     local uniqname = UnitDefs[MostPopularChoice[2]].name.."_tq"
    local unit = spCreateUnit(UnitDefs[MostPopularChoice[2]].id, SpawnPos[i][1], spGetGroundHeight(SpawnPos[i][1], SpawnPos[i][2])+40, SpawnPos[i][2],"n",GaiaTeamID)
    -- since i can see who is objective in unitcreated callback...
--     if (unit ~= nil) then
--       local id = #TheUnits+1
--       TheUnits[id] = unit
--       InitializeObjective(unit, id, UnitDefNames[uniqname])
--     end
  end
  if (#TheUnits > 0) then
    TheUnitsAreChained = true
    --- tell everyone what happened
    local loc_text = "at center";
    if (MostPopularChoice[1] == 1) then
      loc_text = "in spawn boxes";
    elseif (MostPopularChoice[1] == 2) then
      loc_text = "across map";
    elseif (MostPopularChoice[1] == 3) then
      loc_text = "around map";
    end
    local time_text = GetTimeFormatted2(MostPopularChoice[3])
    local god_text = "mortal";
    if (MostPopularChoice[4] == 1) then
      god_text = "semi-mortal";
    elseif (MostPopularChoice[4] == 2) then
      god_text = "immortal";
    end
    spEcho("Takeover Vote Result: "..god_text.." "..UnitDefs[MostPopularChoice[2]].humanName.." being spawned "..loc_text.." and dormant for "..time_text..".");
  end
  
  PollActive = false -- UNCOMMENT ME
  spSetGameRulesParam("takeover_units", #TheUnits)
  spSetGameRulesParam("takeover_vote", 0) -- UNCOMMENT ME
end

-- local function GiveUnitToMostMetalPlayerNear(unit,allyTeam)
--   local x,_,z = spGetUnitPosition(TheUnit)
--   local units = spGetUnitsInCylinder(x, z, CAPTURE_RANGE)
--   local score = {}
--   local TheUnitTeam = spGetUnitTeam(unit)
--   if (#units > 0) then
--     for j=1,#units do
--       local unitID = units[j]
--       if (unitID ~= TheUnit) then
-- 	local unitTeam = spGetUnitTeam(unitID)
-- -- 	if (unitTeam ~= TheUnitTeam) then -- apparently this can cause situation when #winners is empty when it shouldn't
-- 	if (score[unitTeam] == nil) then
-- 	  score[unitTeam] = 0
-- 	end
-- 	score[unitTeam] = score[unitTeam] + UnitDefs[spGetUnitDefID(unitID)].metalCost;
-- -- 	end
--       end
--     end
--   end
--   local best_score
--   for _,sc in pairs(score) do -- TODO get rid of the pairs and replace with smth like for i=1,n do
--     if (best_score == nil) or (sc > best_score) then
--       best_score = sc
--     end
--   end
--   local winners = {}
--   for team,sc in pairs(score) do -- TODO get rid of the pairs and replace with smth like for i=1,n do
--     if (best_score == sc) then
--       winners[#winners+1] = team
--     end
--   end
--   if (winners == nil) or (#winners < 1) then -- just to be sure it never happens again
--     return false
--   end
--   spTransferUnit(unit, winners[random(1,#winners)], false);
--   return true
-- end

-- TODO
-- add cap car damage here too, cap car should do any damage it wants, but not transfer unit on 100%, instead, all capcar damage, allied team wise should contribute to capture speed
-- i wonder how should i do that... probably GG. stuff capcar has and finally change the layer to 1, but then i need to edit some of capcar code to ignore objective... fine... someday :p
local function PerformCaptureLoop(unitID, i, data, hp, maxHealth, emp, empHP, capture, frame)
  local emp_bonus = (emp/empHP)*2+1
  if (emp_bonus > 3) then emp_bonus = 3 end -- you can't get more bonus than 3x faster
  local dmg_bonus = (1-(hp/maxHealth))*(5/9)+1 -- 0.1*5/9+1 ~= 1.5
  if (dmg_bonus > 1.5) then dmg_bonus = 1.5 end -- no more than 0.5x faster bonus
  local cap_bonus = capture*2+1
  if (cap_bonus > 3) then cap_bonus = 3 end -- you can't get more bonus than 3x faster
  local points = CAP_POINTS_PER_SEC * emp_bonus * dmg_bonus * cap_bonus
  if (data.siege) and (frame-120 > data.lastsiege) then
    local ok = true
    for allyteam,score in pairs(data.AllyTeamsProgress) do
      if (score > 0) then
	ok = false
	break
      end
    end
    if ok then
--       Spring.Echo("Siege stopped")
      data.siege = false
      spSetGameRulesParam("takeover_siege_unit"..i, 0)
      data.AllyTeamsProgress = {}
      data.TeamsProgress = {}
    end
  end
  local x,_,z = spGetUnitPosition(unitID)
  local units = spGetUnitsInCylinder(x, z, data.capradius)
  local winner_allyteam = spGetUnitAllyTeam(unitID)
  local allyTeamScore = {}
  local teamScore = {} -- only used to determine which player in the allyteam gets the unit
  local enemies = false
  if (#units > 0) then
    for j=1,#units do
      local unit = units[j]
      local udid = spGetUnitDefID(unit)
      if (unit ~= unitID) and (udid) and (not zerocapturepowerunits[udid]) then
	local team = spGetUnitTeam(unit)
	local unitAllyTeam = spGetUnitAllyTeam(unit)
	if (allyTeamScore[unitAllyTeam] == nil) then
	  allyTeamScore[unitAllyTeam] = 0
	end
	if (teamScore[team] == nil) then
	  teamScore[team] = 0
	end
	local mc = UnitDefs[udid].metalCost
	if (select(5,spGetUnitHealth(unit)) < 1) then mc = 0 end -- nanoframed bastard, no unit for you!
	allyTeamScore[unitAllyTeam] = allyTeamScore[unitAllyTeam] + mc
	teamScore[team] = teamScore[team] + mc
	if (winner_allyteam ~= unitAllyTeam) then
	  if (data.siege == false) then -- contestants have arrived
-- 	    Spring.Echo("Siege started")
	    spSetGameRulesParam("takeover_siege_unit"..i, 1)
	    data.siege = true
	  end
	  data.lastsiege = frame -- basically siege stops when noone attackin'
	  enemies = true
	end
      end
    end
  end
  if (data.siege) then -- who cares if the only people standing around are allies?
    -- now most interesting new feature of latest version, all teams gain cap meter, but only the most score team gets the best of it :)
    local best_ally_score = 0 -- that means you should be able to cap anything with flea, as long as there are no other contestants
    local best_score = 0
    for allyteam,sc in pairs(allyTeamScore) do
      if (sc > best_ally_score) then
	best_ally_score = sc
	winner_allyteam = allyteam
      end
    end
    local winner_team = spGetUnitTeam(unitID)
    for team,sc in pairs(teamScore) do
      if (sc > best_score) then
	best_score = sc
	winner_allyteam = team
      end
    end
    if (best_ally_score > 0) then
      -- now let's scale score
      for i,sc in pairs(allyTeamScore) do
	if (sc > 0) then
	  if (sc < best_ally_score/10) then -- untested change, you need to have at least 10% of most powerful army in metalcost to participate in capture
	    sc = 0
	  end
	  allyTeamScore[i] = points*(sc/best_ally_score)
	end
      end
      for i,sc in pairs(teamScore) do
	if (sc > 0) then
	  if (sc < best_score/10) then -- untested change, you need to have at least 10% of most powerful army in metalcost to participate in capture
	    sc = 0
	  end
	  teamScore[i] = points*(sc/best_score)
	end
      end
      -- now let's add points, note if you had no unit, your personal team points will be removed, if entire allyteam has lost all units in circle, entire allyteam score will be decremented
      for allyteam,sc in pairs(data.AllyTeamsProgress) do
	if (allyTeamScore[allyteam] ~= nil) and (enemies) then
	  data.AllyTeamsProgress[allyteam] = sc + allyTeamScore[allyteam]
	else
	  data.AllyTeamsProgress[allyteam] = sc - CAP_POINTS_PER_SEC
	end
	allyTeamScore[allyteam] = nil
      end
      for team,sc in pairs(data.TeamsProgress) do
	if (teamScore[team] ~= nil) and (enemies) then
	  data.TeamsProgress[team] = sc + teamScore[team]
	else
	  data.TeamsProgress[team] = sc - CAP_POINTS_PER_SEC
	end
	teamScore[team] = nil
      end
      -- all the data that wasn't looped
      for allyteam,sc in pairs(allyTeamScore) do
	data.AllyTeamsProgress[allyteam] = sc
      end
      for team,sc in pairs(teamScore) do
	data.TeamsProgress[team] = sc
      end
      -- now, who ever accumulated most points needed wins!
      local winners_ally_team = {}
      for allyteam,sc in pairs(data.AllyTeamsProgress) do
	if (sc >= data.capscore) then
	  winners_ally_team[#winners_ally_team+1] = allyteam
	end
      end
      if (#winners_ally_team > 0) then
	local solewinner = winners_ally_team[random(1,#winners_ally_team)]
	local megascore = -1
	local megateam = -1
	-- determine most useful player
	for team,sc in pairs(data.TeamsProgress) do
	  local teams_ally = select(6,spGetTeamInfo(team))
	  if (teams_ally == solewinner) then
	    if (sc > megascore) then
	      megascore = sc
	      megateam = team
	    end
	  end
	end
	if (megateam > -1) and ((spGetUnitTeam(unitID) == GaiaTeamID) or (megateam ~= spGetUnitTeam(unitID))) then -- could probably not move unit between same ally team?
	  spTransferUnit(unitID, megateam, false)
	  data.AllyTeamsProgress[solewinner] = 0 -- owner allyteam will have 0 progress
	  for allyteam,sc in pairs(data.AllyTeamsProgress) do
	    data.AllyTeamsProgress[allyteam] = sc/2 -- halves all enemy progress, because unit was captured
	  end
	  data.TeamsProgress = {} -- entire team data is emptied, since it is no more up to date
	  data.siege = false -- siege will reset if enemy units are still present
	  spSetGameRulesParam("takeover_siege_unit"..i, 0)
  --       else
  -- 	Spring.Echo("sum thin wong") -- >_>
	end
      end
    end
--     -- why this? this will make it sure that if both players have same metalcost value near unit if it will change sides unfairly, but rather enemy forces hinder capture process
--     for allyteam,sc in pairs(score) do -- TODO get rid of the pairs and replace with smth like for i=1,n do
--       if (best_score == sc) and (allyteam ~= winner_allyteam) then
-- 	winner_allyteam = nil
-- 	break
--       end
--     end
--     if (winner_allyteam ~= nil) then
--       if (MostMetalOwnerData[i][winner_allyteam] == nil) then
-- 	MostMetalOwnerData[i][winner_allyteam] = 1; -- score
--       else
-- 	MostMetalOwnerData[i][winner_allyteam] = MostMetalOwnerData[i][winner_allyteam] + 1;
--       end
--     end
--       -- I can check for most score in same gameframe :)
--     for allyteam,sc in pairs(MostMetalOwnerData[i]) do
--       if (sc >= 9) then
-- 	if (GiveUnitToMostMetalPlayerNear(TheUnit,allyteam)) then
-- 	  -- reset everyone's score, basically it just empties the capture data, but since if any other enemy unit is present and unit is still empied, it will commence again
-- 	  spSetGameRulesParam("takeover_siege_unit"..i, 0)
-- 	  MostMetalOwnerData[i] = nil 
-- 	end
-- 	break
--       end
--     end
  end
  for _,allyteam in ipairs(spGetAllyTeamList()) do -- transmit all allyteam's progress on capping
    local sc = data.AllyTeamsProgress[allyteam]
    sc = sc and round(data.AllyTeamsProgress[allyteam]/data.capscore*100) or 0
    spSetUnitRulesParam(unitID, "takeover_cap_allyteam"..allyteam, sc, {public = true}) -- lol didn't know about public
    --Spring.Echo("takeover_cap_allyteam"..allyteam.." "..sc)
  end
end

function gadget:GameFrame (f)
  if (TheUnitsAreChained) and (f == DelayInFrames) then --FIXME probably better if equation can be done, or this section can be rewritten somehow
    spSetGameRulesParam("takeover_timeleft", TimeLeftInSeconds)
    TheUnitsAreChained = false;
    local TheUnit
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= -1) then
	spSetUnitNoSelect(TheUnit,false)
	if (spGetUnitTeam(TheUnit) ~= GaiaTeamID) then
	  spGiveOrderToUnit(TheUnit, CMD_FIRE_STATE, {2},{})
	  spGiveOrderToUnit(TheUnit, CMD_MOVE_STATE,{1},{})
	  spGiveOrderToUnit(TheUnit, CMD_ONOFF, {1},{})
	  spGiveOrderToUnit(TheUnit, CMD_IDLEMODE, {1},{})
	end
-- 	if (spGetUnitTeam(TheUnit) == GaiaTeamID) then
-- 	  spGiveOrderToUnit(TheUnit, CMD_REPEAT,{1},{})
-- 	  spGiveOrderToUnit(TheUnit, CMD_FIRE_STATE, {2},{})
-- 	  spGiveOrderToUnit(TheUnit, CMD_MOVE_STATE,{2},{})
-- 	  local xmin,xmax
-- 	  local zmin,zmax
-- 	  xmin = floor(Game.mapSizeX/2 - Game.mapSizeX/6)
-- 	  zmin = floor(Game.mapSizeZ/2 - Game.mapSizeZ/6)
-- 	  xmax = floor(Game.mapSizeX/2 + Game.mapSizeX/6)
-- 	  zmax = floor(Game.mapSizeZ/2 + Game.mapSizeZ/6)
-- 	  for i=1,random(1,10) do
-- 	    x = random(xmin,xmax)
-- 	    z = random(zmin,zmax)
-- 	    spGiveOrderToUnit(TheUnit,CMD_INSERT,{-1,CMD_FIGHT,CMD_OPT_SHIFT,x,0,z},{"alt"});
-- 	  end
-- 	end
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
      if (TheUnit ~= -1) then
	health,maxHealth,paralyzeDamage,capture,_ = spGetUnitHealth(TheUnit)
	empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
	emp = (paralyzeDamage or 0)
	hp  = (health or 0)
	spSetGameRulesParam("takeover_maxhp_unit"..i, maxHealth)
	spSetGameRulesParam("takeover_hp_unit"..i, ceil(hp))
	spSetGameRulesParam("takeover_emphp_unit"..i, empHP)
	spSetGameRulesParam("takeover_emp_unit"..i, ceil(emp))
	-- also need to check capture conditions
	-- how does this work? if your unit is near TheUnit, it adds you to list and every second you earn 1 score point, first one getting 3 points
	-- if multiple players get 3 points, the best elo player that still has units near TheUnit gets it, notice only team with highest metalcost near TheUnit gets 1 score point
	-- if you don't but still have units, you keep your score, but you have less than 3 seconds to kill other player's army, in other words your progress is paused
	PerformCaptureLoop(TheUnit, i, ObjectiveData[TheUnit], hp, maxHealth, emp, empHP, capture, f)
      end -- why in gameframe? because units regen and i don't know if unitdamaged callback is called when unit gains health instead of losing
    end
  end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
  if (MostPopularChoice[4] > 0) then
    local TheUnit
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= -1) and (TheUnit == unitID) then
	local x,_,z = spGetUnitPosition(unitID)
	if (x < 0) or (z < 0) or (x > mapWidth) or (z > mapHeight) then return damage; end -- so you left map? become mortal glitcher :)
	local health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(unitID)
	local buttomhp = maxHealth/10
	local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
	local emp = (paralyzeDamage or 0)/empHP
	if (MostPopularChoice[4] == 2) or ((MostPopularChoice[4] == 1) and (unitTeam == GaiaTeamID)) then
-- 	  Spring.Echo(weaponID.." "..health.." "..damage)
	  if (weaponID < 0) then return 0; end
	  if ((emp >= 1) or (TheUnitsAreChained)) then
	    -- you may ask yourself why, the answer is: i do not want to block emp/slow damage, if you know way to make this better, contact me
	    UnitNoOverhealData[unitID] = health
	    spSetUnitHealth(unitID, {health = health+floor(damage+1)});
	  end	  
	  if (health-damage < buttomhp) then
-- 	  if (health-damage >= buttomhp) then --- tried to rewrite it, but failed ;(
	    UnitNoOverhealData[unitID] = health
 	    spSetUnitHealth(unitID, {health = health+floor(damage+1-health+buttomhp)});
-- 	  elseif (health-damage < buttomhp) then
-- 	    UnitNoOverhealData[unitID] = buttomhp+floor(damage+1)
--  	    spSetUnitHealth(unitID, {health = buttomhp+floor(damage+1)});
	  end
	elseif (MostPopularChoice[4] == 1) then
	  if (weaponID < 0) then return 0; end
	  if ((emp >= 1) or (TheUnitsAreChained) or (unitTeam == GaiaTeamID)) then
	    if (weaponID < 0) then return 0; end
	    UnitNoOverhealData[unitID] = health
	    spSetUnitHealth(unitID, {health = health+floor(damage+1)});
	  end
	end
-- 	local health = select(1,spGetUnitHealth(unitID))
-- 	if (health > maxHealth) then
-- 	  UnitNoOverhealData[unitID] = health
-- 	  spSetUnitHealth(unitID, {health = maxHealth})
-- 	end
      end
    end
  end
end

-- fix to issue when emp drones and so it won't heal unit
function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
  if (MostPopularChoice[4] > 0) then
    local TheUnit
    for i=1,#TheUnits do
      TheUnit = TheUnits[i]
      if (TheUnit ~= -1) and (TheUnit == unitID) and (UnitNoOverhealData[unitID]) then
	local health,maxHealth,paralyzeDamage,_ = spGetUnitHealth(unitID)
	if (health > UnitNoOverhealData[unitID]) then
	  spSetUnitHealth(unitID, {health = UnitNoOverhealData[unitID]})
	  UnitNoOverhealData[unitID] = nil
	end
	if (health > maxHealth) then
	  UnitNoOverhealData[unitID] = health
	  spSetUnitHealth(unitID, {health = maxHealth})
	end
      end
    end
  end
end

function gadget:AllowUnitTransfer(unitID, unitDefID, oldTeam, newTeam)
  if (newTeam == GaiaTeamID) then
    return false
  end
  return true
end
  
function gadget:UnitCreated(unitID, unitDefID, teamID)
  if (UnitDefs[unitDefID].customParams.tqobj) then
    local TheUnit
    local id = -1
    for i,unit in pairs(TheUnits) do
      if (unit > -1) and (spGetUnitRulesParam(unit, "wasMorphedTo") ~= nil) and (spGetUnitRulesParam(unit, "wasMorphedTo") == unit) then
	id = i
	break
      end
    end
    local oldobj
    if (ObjectiveData[unit] ~= nil) then
      oldobj = CopyTable(ObjectiveData[unit], true)
    end
    if (id ~= -1) then
      gadget:UnitDestroyed(unitID, unitDefID, teamID)
    end
    if (id ~= -1) then
      InitializeObjective(unitID, id, UnitDefs[unitDefID], spGetGameFrame()<=300) -- objective ain't dead anymore, hehehehe
      if (oldobj ~= nil) then
	ObjectiveData[unitID] = oldobj
      end
    else
      InitializeObjective(unitID, #TheUnits+1, UnitDefs[unitDefID], spGetGameFrame()<=300) -- objective ain't dead anymore, hehehehe
    end
  elseif (thingsWhichAreDrones[unitDefID]) and ((TheUnitsAreChained) or (teamID == GaiaTeamID)) then
    local carrierID = GG.droneList[unitID].carrier
    if (carrierID.customParams.tqobj) then
	spDestroyUnit(unitID, false, true) -- impossible to drop drones orders because drone gadget updates them every 2 seconds :)
    end
  end
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= -1) and (TheUnit == unitID) then
      spSetGameRulesParam("takeover_team_unit"..i, newTeamID)
      spSetGameRulesParam("takeover_allyteam_unit"..i, select(6,spGetTeamInfo(newTeamID)))
      if (TheUnitsAreChained) or (newTeamID == GaiaTeamID) then
	spGiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {}) -- don't attack
	spGiveOrderToUnit(unitID, CMD_MOVE_STATE, {0}, {}) -- don't move
	spGiveOrderToUnit(unitID, CMD_ONOFF, {0}, {}) -- don't work
	spGiveOrderToUnit(unitID, CMD_IDLEMODE, {0}, {}) -- don't fly
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
      spSetGameRulesParam("takeover_udid_unit"..i, -1)
      spSetGameRulesParam("takeover_team_unit"..i, -1)
      spSetGameRulesParam("takeover_allyteam_unit"..i, -1)
      spSetGameRulesParam("takeover_maxhp_unit"..i, 1)
      spSetGameRulesParam("takeover_hp_unit"..i, 0)
      spSetGameRulesParam("takeover_emphp_unit"..i, 1)
      spSetGameRulesParam("takeover_emp_unit"..i, 0)
      TheUnits[i] = -1 -- because apparently if i have for example { 1245, 532, 345 } and i set 532 to nil, for i=1,#TheUnits will never reach 345 O_O
      ObjectiveData[unitID] = nil
      break
    end
  end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= -1) and (unitID == TheUnit) and (TheUnitsAreChained) and (TimeLeftInSeconds>0) then
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
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions) --, fromSynced)
  -- you shall not use the dormant unit
  local TheUnit
  for i=1,#TheUnits do
    TheUnit = TheUnits[i]
    if (TheUnit ~= -1) then
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
      else
	if (unitID == TheUnit) and (cmdID == CMD_RECLAIM) and (#cmdParams == 1) and (cmdParams[1] == TheUnit) then -- you may never be able to reclaim objective
	  return false
	end
      end
    end
  end
  return true
end

function gadget:RecvLuaMsg(line, playerID)
  local name, _, spectator = spGetPlayerInfo(playerID)
  if PollActive then
    if (not spectator) then
      if line:find(string_nominate) then
	NominateNewRule(playerID, name, ParseParams(line), false)
      elseif line:find(string_upvote) then
	PlayerUpVote(playerID, name, ParseParams(line))
      elseif line:find(string_downvote) then
	PlayerDownVote(playerID, name, ParseParams(line))
      end
    elseif line:find(string_nominate) then
	NominateNewRule(playerID, name, ParseParams(line), true)
    end
  end
end

else --------------------------------------------------------------------------------------------------- unsycned

local function ParseVote(cmd, line, words, playerID)
  if (#words == 5) then
    spSendLuaRulesMsg(string_nominate.." "..words[1].." "..words[2].." "..words[3].." "..words[4])
  end
end

local function UpVote(cmd, line, words, playerID)
  if (#words == 2) then
    spSendLuaRulesMsg(string_upvote.." "..words[1].." "..words[2])
  end
end

local function DownVote(cmd, line, words, playerID)
  if (#words == 2) then
    spSendLuaRulesMsg(string_downvote.." "..words[1].." "..words[2])
  end
end
  
function gadget:Initialize()
  if (not Spring.GetModOptions().zkmode) or (tostring(Spring.GetModOptions().zkmode) ~= "takeover") or (Config == nil) then
      gadgetHandler:RemoveGadget()
  end
  gadgetHandler:AddChatAction(string_nominate, ParseVote)
  gadgetHandler:AddChatAction(string_upvote, UpVote)
  gadgetHandler:AddChatAction(string_downvote, DownVote)
end

end