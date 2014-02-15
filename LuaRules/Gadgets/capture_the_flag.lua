local version = "0.1.0"

function gadget:GetInfo()
  return {
    name      = "Capture The Flag",
    desc      = "CTF original game mode. Capture the flags! Version "..version,
    author    = "Tom Fyuri",
    date      = "Feb 2014",
    license   = "GPL v2 or later",
    layer     = -1,
    enabled   = true	-- don't disable me please
  }
end

--[[ Capture The Flag.
1. Teams spawn with 3 flags. Flag icon appears of top of all command centers. Centers spawn slightly closer to front lines.
2. It's invincible, you can't attack it, to capture enemy flag walk close by it's command center. To score stolen flag, walk close by your team's center.
3. The more flags you own, the more resources every player on your team gets (both M&E). Bonus is everytime bigger the more you have. Losing flags, on the other hand will give a lot less resources.
4. Losing team get's ability to call in dead commanders again. They get brand new ones delivered from orbit to any place they want in LoS.
  Commanders also the level of [amount_of_flags_initialy - amount_of_flags_left], so if number is bigger than 0 and you lost commander in battle. You may call in another one.
  NOTE: If you reclaimed commander or you made it suicide, you are not given this ability.
  In some cases you may have multiple commanders, if that's the case, you might get ability to stack extra backup coms.
5. If you lose all flags (enemy scores your last flag), you have 2 minutes to redeem your team by scoring 1 flag. If you fail to do so, you will lose the game.
6. There can be multiple command centers (the more players the more centers), and they upgrade themselves overtime (for every level of command center they give additional 50% resources).

You can have multiple command structures, the number is:
1 - if less than 3 players present in team.
2 - if less than 6 players present in team.
3 - if less more or equal to 6 players in team.

Centers are dispersed equally inside spawn boxes. If there is no spawn boxes on map. Currently the game mode will disable itself.
Spawn center will push out any unit that was stuck inside it, upon spawning.

You can capture flag using any unit apart from flying units. You can pick up flag carriers using transport though.

  Summary (features):
- Controlling flags increase m&e income.
- Losing flags gives free commanders (but overtime having more flags benefits you more).
- Having 0 flags will result in defeat within 2 minutes (it's okay if last flag is stolen though).
- Having many players in single team will result in multiple flag bases.
- You can capture only 1 flag at a time. If 2 teams control each other flags for 120 secs, flags are teleported back.
- Walking over your own team's flag will teleport it back to the base.
- Walking over your enemy's flag will pick it up, bring it to your own base!
- Contested flags do not count towards bonus income!
- There can only be one single stolen&contested flag at a time!

  immediate TODO:
- Rewrite widget (it only shows 2 teams, yet gadget supports more allyteams!).
- Make a wiki page.
  
  things to test/tweak:
- Backup commander logic needed to be tested more, and the extra income should be balanced on the results of testing. (this needs actual playing)
- Flag shouldn't terraform place where it is dropped. (it can also float on water)
  
  later TODO:
- Make mode options tweakable.
- Drop flag button should drop flag infront of unit, yet be smart and if flag will be in inaccessable place or out of map - refuse to drop.
- Sub gamemode: Reverse CTF or escort - instead of capturing and bringing enemy flag to your base, you should bring your own flag to enemy base to score, all the other rules stay the same!
- Somehow terraforming flag bases should be pointless or less useful as it stands now.
- If map is big, flag capture ranges should scale slightly.
- If CC spawns above ground it should level ground actually.
- Gadget should be able to send some text string for clients (widget) to display.
- Tweak pool/tickets and make AI call in coms if available right away.
- Multi-contest resolution (when multiple teams are stuck because they stealed each other flags).
- Some more endgame content (either superunit or turn CCs into superweapons for last team standing (having non 0 flags), so they finish other teams in spectacular way).
- Make CAI search it's own team's flags and pick them up. CAI also should stay there until flag is scored.

  Changelog:
9 February 2014 - 0.0.1 beta	- First version. 
10 February 2014 - 0.0.2	- Second version with water support and few bug fixes.
11 February 2014 - 0.0.3	- Income lowered by 2. Bug fixes. CC spawn logic changed. Backup commanders are stackable. And lots of bug fixes.
12 February 2014 - 0.0.4	- Few bug fixes, CCs should also show capture range rings.
12 February 2014 - 0.0.5	- Flags in limbo eventually return to their base and allow game to proceed smoothly and critical bugs with duplicating flags and/or disappearing fixed.
13 February 2014 - 0.0.6	- Improved CC spawn logic, it should support team fights, ffa fights (simply spawnings CCs inside spawn boxes). It also works for no spawn boxes maps too. Tweaked income, was too big and calculated wrong. Fixes to commander pool logic.
14 February 2014 - 0.0.7	- Improved CC spawn logic again. Now it supports for example BlueBend.
15 February 2014 - 0.0.8	- Dropflag button added. Also income is fixed again. (it was broken in 0.0.6 and 0.0.7 for 1 team...)
15 Februray 2014 - 0.0.9	- CAI knows how to cap enemy flag, albeit algo is simple, run towards nearest flag base.
15 Februray 2014 - 0.1.0	- Some options made tweakable. Fixed inablity to select different com.
]]--  
-- NOTE: code is largely based on abandoned takeover game mode, it just doesn't have anything ingame voting related...

-- TODO FIXME write good randomizer... unless spring will pick some randomseed on it's own...
if (math.randomseed ~= nil) then
  --local r = Spring.DiffTimers(Spring.GetTimer(), Script.CreateScream())	-- FIXME crashes with "invalid args" error
  math.random()
  --math.randomseed(r)
end

include("LuaRules/Configs/customcmds.h.lua")

--SYNCED-------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

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
local cos	= math.cos
local sin	= math.sin
local PI	= math.pi
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
local spAddTeamResource     = Spring.AddTeamResource
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
local spSetTeamRulesParam   = Spring.SetTeamRulesParam
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spSetUnitRulesParam   = Spring.SetUnitRulesParam
local spGetTeamRulesParam   = Spring.GetTeamRulesParam
local spGetUnitsInCylinder  = Spring.GetUnitsInCylinder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetUnitIsCloaked    = Spring.GetUnitIsCloaked
local spSetUnitAlwaysVisible= Spring.SetUnitAlwaysVisible
local spAreTeamsAllied	    = Spring.AreTeamsAllied
local spGetUnitPosition     = Spring.GetUnitPosition
local spSetUnitPosition	    = Spring.SetUnitPosition
local spIsPosInLos	    = Spring.IsPosInLos
local spGetTeamList	    = Spring.GetTeamList
local spValidUnitID	    = Spring.ValidUnitID
local spEcho                = Spring.Echo
local spKillTeam	    = Spring.KillTeam

local spGetPlayerInfo	    = Spring.GetPlayerInfo
local spGetAllyTeamList	    = Spring.GetAllyTeamList

local FlagCarrier = {} -- unitID has allyTeam's flag
local DroppedFlags = {} -- functions almost same as CC, expect if you pick your own flag it's teleported to CC instead of being picked up
local CommandCenters = {} -- arraylist centers
local FlagAmount = {} -- number per allyteam, essentially score
local ContestedTeam = {} -- if team's flag stolen it gets into this array
local ContestData = {} -- holds a tables with opposing allyTeams and timer...
local DefeatTimer = {} -- every second you have 0 flags you are doomed :D
-- if both teams are in this array a timer is set to teleport their flags to bases in 120 sec
local CallBackup = {} -- per team, holds lvl of commander player may call in (respawn)
local CommChoice = {} -- players can change commchoice ingame...
local OrbitDrop = {} -- delayed delivering...
local BlackListed = {} -- per unitid.. i put here transported units and unblacklist on unloading/death
local ReturnFlagTimer = {}
local CommanderPool = {} -- maximum amount of commanders per player
local CommanderTickets = {} -- amount of tickets per player
local CommanderTimer = {} -- timer starts to go down if player has less commanders than his pool allows, timer resets (and comm ticket is given) if enemy scores your team's flag
local CommanderSpeedUpTimer = {} -- by teamID, if enemy team scores, it will allow to call in backup comm much sooner
local Godmode = {} -- unitid... only CCs are dropped here, flags are not though
local TeamsInAlliance = {} -- by allyteam... teamIDs
local CountInAlliance = {} -- by allyteam... number of teamIDs, to make Payday function work better and faster
local ActivePlayers = {} -- by playerID, holds teamID, when game starts all players are dumped inside

-- rules
local TIMER_DEFEAT = tonumber(modOptions.ctf_death_time or 120) -- time in seconds when you lose because you have 0 flags left. by default 2min.
local TIMER_TELEPORT_FLAGS = 120 -- time in seconds if 2 teams hold each other flags - flags teleport back to bases
local PICK_RADIUS = 75
local PICK_RADIUS_SQ = PICK_RADIUS*PICK_RADIUS
local CAP_RADIUS = 250
local CAP_RADIUS_SQ = CAP_RADIUS*CAP_RADIUS
local DENY_DROP_RADIUS = 400 -- dont comdrop on enemy carrier... no fun
local DENY_DROP_RADIUS_SQ = DENY_DROP_RADIUS*DENY_DROP_RADIUS
local MAX_Z_DIFFERENCE = 75 -- no capturing from space lol
local FLAG_AMOUNT_INIT = floor(tonumber(modOptions.ctf_flags or 1))
local ME_BONUS = function(i) return ((1.4^(1+i)+(1.5+(i*1.5))))*0.4-1.16 end --[[
NOTE: this table is for income
for every flag your team owns from 0 to 6 - your own income, examples:
flags 	1 second	1 minute
0	0		0
1	0.824		49.44
2	1.7376		104.256
3	2.77664		166.5984
4	3.991296	239.47776
5	5.4518144	327.108864
6	7.25654016	435.3924096
4 vs 2 - ~135 per minute advantage, your enemy respawns with 1lvl coms. -- additional +2.25m&e income per player (comparing to enemy team) seems fair to counter this with respawning few commanders being lvl1.
5 vs 1 - ~277 per minute advantage, your enemy respawns with 2lvl coms. -- additional +4.63m&e income per player (comparing to enemy team) seems fair to counter this with respawning few commanders being lvl2.
6 vs 0 - ~435 per minute advantage, your enemy respawns with 3lvl coms and have 3 minutes to grab 1 flag before auto-resign.
also, the longer game progresses the more income all teams will get, it is increased from 1.00 multiplier (base) to 1.875 (which should be at 1*player_amount minute into the game).
this makes this entirely worthwhile to capture flags. because even by losing single flag you make your own position less favorable in the long run.
no matter what you do command center is indestructible, yet gives constant bonus income.
]]-- 
-- TODO some of these could be modifyable by modoptions
local ME_BONUS_C = {} -- this one fills in automatically from function above on gamestart, it's income per TEAM, NOT PER PLAYER!
local ME_BONUS_MULT = tonumber(modOptions.ctf_inc_mult or 1.0)
local ME_BONUS_DELAY = 1920 -- 1 minute, this will be multiplied by player amount, so every DELAY minutes centres upgrade
local ME_CENTER_UP_MAX = 3 -- 3 upgrades max
local ME_CENTER_BONUS_INIT = 0.5 -- for every level the bonus is halved... read below ME_CENTER_CURRENT_BONUS
local ME_CENTER_INIT_LVL = 0
local ME_CENTER_LVL = ME_CENTER_INIT_LVL
local ME_CENTER_CURRENT_BONUS = 1 -- this get's changed to 1.5 1.75 and 1.875...
local COM_DROP_DELAY = 3 -- in seconds
local COM_DROP_TIMER = tonumber(modOptions.ctf_resp_time or 150) -- 1 free ticket per 2 and half minutes by default
local LONELY_FLAG_TIMER = 120 -- if flag is untouched for 120 seconds teleport it back, may be super useful if for some reason flag disappeared (bug)?
local CTF_ONE_SECOND_FRAME = 30 -- frames per second
local MERGE_DIST = 450 -- spawn positions below 450 dist? merge them!
local MERGE_DIST_SQ = MERGE_DIST*MERGE_DIST
local CC_TOO_NEAR = 450
local CC_TOO_NEAR_SQ = CC_TOO_NEAR*CC_TOO_NEAR
-- NOTE maybe it's better to simply make centers behave like mexes so you may connect them to OD grid...

local energy_mult = 1.0 -- why not obey them too
local metal_mult = 1.0

local DelayedInit = nil -- non nil if gamestarted event failed, this is fallback thing to retry spawning
local GameStarted = false

local CMD_DROP_FLAG 	= 35300
local CMD_INSERT	= CMD.INSERT
local CMD_MOVE		= CMD.MOVE
local CMD_OPT_INTERNAL	= CMD.OPT_INTERNAL

--//------------------ Code to determine command center spawn positions and teleport stucked commanders away and so on -- BEGIN

function FigureSide(x, y)
  if (x < mapWidth/3) then 
    if (y < mapHeight/3) then
      return 1
    elseif (y < mapHeight/(3/2)) then
      return 2
    else
      return 3
    end
  elseif (y < mapWidth/(3/2)) then 
    if (y < mapHeight/3) then
      return 4
    elseif (y < mapHeight/(3/2)) then
      return 5
    else
      return 6
    end
  else 
    if (y < mapHeight/3) then
      return 7
    elseif (y < mapHeight/(3/2)) then
      return 8
    else
      return 9
    end
  end
  return 5 -- LOL
end

function InvertFacing(s)
  if (s == "w") then
    return "e"
  elseif (s == "e") then
    return "w"
  elseif (s == "n") then
    return "s"
  else
    return "n"
  end
end

function ToFacing(x, y)
  local lol = FigureSide(x,y)
  if (lol == 2) then
    return "s"
  elseif (lol == 4) then
    return "e"
  elseif (lol == 6) then
    return "w"
  elseif (lol == 8) then
    return "n"
  elseif (lol == 1) then
    local n = random (1,2)
    if (n == 1) then
      return "e"
    else
      return "s"
    end
  elseif (lol == 3) then
    local n = random (1,2)
    if (n == 1) then
      return "w"
    else
      return "s"
    end
  elseif (lol == 7) then
    local n = random (1,2)
    if (n == 1) then
      return "e"
    else
      return "n"
    end
  elseif (lol == 9) then
    local n = random (1,2)
    if (n == 1) then
      return "w"
    else
      return "n"
    end
  else -- 5 lol
    local n = random(1,4)
    if (n == 1) then
      return "n"
    elseif (n == 2) then
      return "w"
    elseif (n == 3) then
      return "s"
    else
      return "e"
    end
  end
end

function FindClosest(ex,ey,cx,cy,ignore_list)
  local closest_index = 0
  local closest_dist = nil
  for index=1,#ex do
    if ignore_list==nil or not(ignore_list[index]) then
      local dist = disSQ(ex[index],ey[index],cx,cy)
      if (closest_dist == nil) or (dist < closest_dist) then
	closest_index = index
	closest_dist = dist
      end
    end
  end
  if (closest_dist == nil) then return nil end
  return closest_index,ex[closest_index],ey[closest_index]
end

function CalcSpawnPos(spawns)
  local ex = {}
  local ey = {}
  local m = floor((spawns-2)*4+8)
  local x = mapWidth/2
  local z = mapHeight/2
  local adjRadius1 = x * 0.6
  local adjRadius2 = z * 0.6
  if ((mapWidth >= 6000) and (mapHeight >= 6000)) or ((mapWidth/3 >= 2800) and (mapHeight/3 >= 2800) and ((mapWidth+mapHeight)/2) >= 6000) then
    adjRadius1 = x * 0.5
    adjRadius2 = z * 0.5
  elseif ((mapWidth >= 2400) and (mapHeight >= 2400)) or ((mapWidth/3 >= 900) and (mapHeight/3 >= 900) and ((mapWidth+mapHeight)/2) >= 2400) then
    adjRadius1 = x * 0.55
    adjRadius2 = z * 0.55
  end
  for i = 1,m do
    local radians = 2.0 * PI * i / m
    local sinR = sin( radians )
    local cosR = cos( radians )
    local posx = x + sinR
    local posz = z + cosR
    posx = x + ( sinR * adjRadius1 )
    posz = z + ( cosR * adjRadius2 )
    ex[#ex+1] = posx
    ey[#ey+1] = posz
  end
  return ex,ey
end

function DetermineSpawns(allyTeams)
  local SpawnBoxes = {}
  for _,allyTeam in ipairs(allyTeams) do
    local x1, z1, x2, z2 = spGetAllyTeamStartBox(allyTeam)
    if x1 then
      local width = abs(x2-x1)
      local height = abs(z2-z1)
      if (width < mapWidth) or (height < mapHeight) then
	SpawnBoxes[#SpawnBoxes+1] = {
	  cc_count = 0,
	  player_count = #spGetTeamList(allyTeam),
	  allyTeam = allyTeam,
	  x1 = x1, x2 = x2, -- not needed?
	  z1 = z1, z2 = z2, -- not needed?
	  centerx = (x1+x2)/2, 
	  centerz = (z1+z2)/2,
	}
      end
    end
  end
  local CentreSpawns,player_num,players_per_team,allyTeam_num
  player_num = 0
  players_per_team = 0
  allyTeam_num = #allyTeams
  if (#SpawnBoxes <= 1) then -- horribly something went wrong
    SpawnBoxes = nil
  end
  if (SpawnBoxes ~= nil) then
    allyTeam_num = #SpawnBoxes -- why? if player had no spawnbox, don't consider him part of the game..
    for _,data in ipairs(SpawnBoxes) do
      player_num = player_num + data.player_count
      if (data.player_count > players_per_team) then
	players_per_team = data.player_count
      end
    end
  else
    for _,allyTeam in ipairs(allyTeams) do
      local pc = #spGetTeamList(allyTeam)
      player_num = player_num + pc
      if (pc > players_per_team) then
	players_per_team = pc
      end
    end
  end
  -- now figure out if map is narrow, if it is too narrow spawn only 1 CC, otherwise draw ellipse inside spring map and figure out fair coordinates to spawn centers
  -- this allows to support 2 & 4 teams just fine, though i won't put any limit for team number
  local cc_count = 1
  local narrow = false
  if ((mapWidth/5) > mapHeight) or ((mapHeight/5) > mapWidth) or (mapHeight < 400) or (mapWidth < 400) then
    narrow = true -- only 1 CC per allyteam, otherwise depending on player count
  end
  if not(narrow) then
    if (player_num > 5) then
      cc_count = 3
    elseif (player_num > 2) then
      cc_count = 2
    end
  else
    cc_count = 1
  end
  if (SpawnBoxes ~= nil) then
    CentreSpawns = EllipseWay(SpawnBoxes,cc_count,player_num,players_per_team,allyTeam_num)
    if (CentreSpawns == nil) then -- so they overlap this is kinda bad but spawn boxes are there
      spEcho("CTF: Spawning flag bases the fallback plan A way.")
     CentreSpawns = PlayerBoxWay(SpawnBoxes)
    else
      spEcho("CTF: Spawning flag bases the usual way.")
    end
  end
  if (CentreSpawns == nil) then
    spEcho("CTF: Spawning flag bases the fallback plan B way.")
    if (DelayedInit == nil) then
      DelayedInit = 29
    else
      CentreSpawns = FallbackWay(allyTeams)
      DelayedInit = nil
    end
  end
  if (CentreSpawns ~= nil) and (#CentreSpawns <= 1) then -- oh crap
    CentreSpawns = nil
  end
  return CentreSpawns,players_per_team,player_num
end

function MergeTooNear(ex, ey)
  local nx = {}
  local ny = {}
  -- this works rather simple
  for i=1,#ex do
    local merged = false
    for j=1,#nx do
      if (ex[i] ~= nx[j]) and (ey[i] ~= ny[j]) and (disSQ(ex[i], ey[i], nx[j], ny[j]) < MERGE_DIST_SQ) then
	nx[j] = (nx[j]+ex[i])/2
	ny[j] = (ny[j]+ey[i])/2
	merged = true
      end
    end
    if not(merged) then
      nx[#nx+1]=ex[i]
      ny[#ny+1]=ey[i]
    end
  end
  return nx,ny
end

function PlayerBoxWay(SpawnBoxes) -- TODO if playerbox is huge, spawn multiple CCs depending on playercount
  -- it probably should also try to make CCs closer to center of the map rather than center of spawn point but that's for later too
  local CentreSpawns = {}
  for _,spawn in ipairs(SpawnBoxes) do
    CentreSpawns[#CentreSpawns+1] = {
      x = spawn.centerx, z = spawn.centerz, allyTeam = spawn.allyTeam
    }
  end
  return CentreSpawns
end

function NormalizeCoords(cx,cz)
  if (cx < 200) then
    cx = 200
  elseif (cx-200 > mapWidth) then
    return mapWidth-200
  end
  if (cz < 200) then
    cz = 200
  elseif (cz-200 > mapHeight) then
    return mapHeight-200
  end
  return cx,cz
end

function FallbackWay(allyTeams) -- TODO incase players spawn extrimely close to each other, make it so their spawn bases positions are simply random somewhere on map, if that's the case, well damn very very very small maps lol!
  -- this way is kinda fun, detect all commanders, sum all Xs,Zs divide by commander count and place at the resulted X,Z CC for that team
  CentreSpawns = {}
  for _,allyTeam in ipairs(allyTeams) do
    local commanders = {}
    for _,teamID in ipairs(spGetTeamList(allyTeam)) do
      local units = spGetTeamUnits(teamID)
      for i=1,#units do
	local unitDefID = spGetUnitDefID(units[i])
	if spValidUnitID(units[i]) and UnitDefs[unitDefID].customParams.commtype then
	  commanders[#commanders+1] = units[i]
	end
      end
    end
    -- now get the position
    local cx = 0
    local cz = 0
    for i=1,#commanders do
      local x,_,z = spGetUnitPosition(commanders[i])
      cx = cx+x
      cz = cz+z
    end
    cx = cx/#commanders
    cz = cz/#commanders
    cx,cz = NormalizeCoords(cx,cz)
    CentreSpawns[#CentreSpawns+1] = {
      x = cx, z = cz, allyTeam = allyTeam
    }
  end
  return CentreSpawns
end

function EllipseWay(SpawnBoxes,cc_count,player_num,players_per_team,allyTeam_num)
  -- TODO detect if mex position is inside CC, if yes shift CC slightly
  local ex, ey = CalcSpawnPos(allyTeam_num)
  ex, ey = MergeTooNear(ex, ey)
  local CentreSpawns = {}
  local core
  local cx,cy
  local used = {}
  local index_to_center = {}
  for _,spawn in ipairs(SpawnBoxes) do
    index,cx,cy = FindClosest(ex, ey, spawn.centerx, spawn.centerz, nil)
    if (used[index]) then return nil end
    used[index] = true
     CentreSpawns[#CentreSpawns+1] = {
      x = cx, z = cy, allyTeam = spawn.allyTeam, index=index
    }
    spawn.cc_count = spawn.cc_count + 1
    index_to_center[index] = index
--     spEcho("used "..index)
  end
  local j = -1
  local Ignore = {}
  for i=1, #ex do
    -- if 1 and 3 has cores then ignore index 2 because too near
    if j > 0 then
--       spEcho("compare b "..i.." "..j)
      if (index_to_center[j] ~= nil) and (index_to_center[i] ~= nil) then
	Ignore[j+1] = true
-- 	spEcho("Ignore "..ex[j+1].." "..ey[j+1])
      end
    else
      local t = #ex+j
--       spEcho("compare a "..i.." "..t)
      if (index_to_center[t] ~= nil) and (index_to_center[i] ~= nil) then
	local n = t+1
	if (n > #ex) then
	  n = i-1
	end
	Ignore[n] = true
-- 	spEcho("Ignore "..ex[n].." "..ey[n])
      end
    end
    j=j+1
  end
  if (cc_count > 1) then
    core = #CentreSpawns
    for i=1,core do
      Ignore[CentreSpawns[i].index]=true
      index_to_center[CentreSpawns[i].index] = i
    end
  --
    for _,spawn in ipairs(SpawnBoxes) do
      index,cx,cy = FindClosest(ex, ey, spawn.centerx, spawn.centerz, Ignore)
      if (used[index]) then return nil end -- damn it
      used[index] = true
      CentreSpawns[#CentreSpawns+1] = {
	x = cx, z = cy, allyTeam = spawn.allyTeam, index=index
      }
      spawn.cc_count = spawn.cc_count + 1
    end
  --
    for i=core+1,#CentreSpawns do
      Ignore[CentreSpawns[i].index]=true
      index_to_center[CentreSpawns[i].index] = i
    end
    for _,spawn in ipairs(SpawnBoxes) do
      index,cx,cy = FindClosest(ex, ey, spawn.centerx, spawn.centerz, Ignore)
      if (used[index]) then return nil end -- damn it
      used[index] = true
      CentreSpawns[#CentreSpawns+1] = {
	x = cx, z = cy, allyTeam = spawn.allyTeam, index=index
      }
      spawn.cc_count = spawn.cc_count + 1
    end
  -- detect whether any neighbour center is..
    for i=#index_to_center+1,#CentreSpawns do
      index_to_center[CentreSpawns[i].index] = i
    end
    if (cc_count == 2) then
      local sx,sy
      -- now find middle CC of every team and remove it
      for _,spawn in ipairs(SpawnBoxes) do
	sx = 0
	sy = 0
	for _,data in pairs(CentreSpawns) do
	  if (data.allyTeam == spawn.allyTeam) then
	    sx=sx+data.x
	    sy=sy+data.z
	  end
	end
	sx = sx/3
	sy = sy/3
	index,_,_ = FindClosest(ex,ey,sx,sy,nil)
	CentreSpawns[index_to_center[index]] = nil
	spawn.cc_count = spawn.cc_count - 1
      end
    end
  end
  -- now important, if CC's distance between each other is too near -> return nil...
  for a,data in pairs(CentreSpawns) do
    for b,datb in pairs(CentreSpawns) do
      if (a ~= b) then
	local ax = data.x
	local ay = data.z
	local bx = datb.x
	local by = datb.z
	if (disSQ(ax,ay,bx,by) < CC_TOO_NEAR_SQ) then
	  return nil -- :(
	end
      end
    end
  end
  return CentreSpawns
end

function WithoutGaia(allyTeams)
  allyTeams2 = {}
  for _,allyTeam in ipairs(allyTeams) do
    if (allyTeam ~= GaiaAllyTeamID) then
      allyTeams2[#allyTeams2+1] = allyTeam
    end
  end
  return allyTeams2
end

function SpawnCommandCenters()
  local allyTeams = WithoutGaia(spGetAllyTeamList())
  local CentreSpawns,PlayersPerTeam,player_num
  CentreSpawns,PlayersPerTeam,player_num = DetermineSpawns(allyTeams)
  
  if (DelayedInit == nil) and (CentreSpawns == nil) then
    spEcho("CTF: For some reason no flag bases could be spawned. Please bug report map name and spawn positions, if possible.")
    gadgetHandler:RemoveGadget()
--     return
  elseif (CentreSpawns ~= nil) then
    ProceedSmoothly(allyTeams,CentreSpawns,PlayersPerTeam,player_num)
  end
end
  
function ProceedSmoothly(allyTeams,CentreSpawns,PlayersPerTeam,player_num)
  for _,allyTeam in ipairs(allyTeams) do
    DefeatTimer[allyTeam] = TIMER_DEFEAT
    FlagAmount[allyTeam] = FLAG_AMOUNT_INIT
    TeamsInAlliance[allyTeam] = {}
    CountInAlliance[allyTeam] = 0
    spSetGameRulesParam("ctf_contest_time_team"..allyTeam,TIMER_TELEPORT_FLAGS)
    spSetGameRulesParam("ctf_flags_team"..allyTeam, FLAG_AMOUNT_INIT)
    spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, TIMER_DEFEAT)
  end
  spSetGameRulesParam("ctf_cc_lvl", ME_CENTER_INIT_LVL)
  
  -- mults
  local em = spGetGameRulesParam("energymult")
  local mm = spGetGameRulesParam("metalmult")
  if (em ~= nil) then
    energy_mult = em
  end
  if (mm ~= nil) then
    metal_mult = mm
  end
  local max_flags = #allyTeams * FLAG_AMOUNT_INIT
  for ip=0, max_flags do
    ME_BONUS_C[ip] = ME_BONUS(ip) * ME_BONUS_MULT * PlayersPerTeam
  end
  ME_BONUS_DELAY = ME_BONUS_DELAY * player_num
  -- player data
  for allyTeam,_ in pairs(FlagAmount) do
    teams = spGetTeamList(allyTeam)
    for i=1,#teams do
      local teamID = teams[i]
      CommanderPool[teamID]=0
      CommanderTickets[teamID]=0
      CommanderTimer[teamID]=COM_DROP_TIMER
      spSetGameRulesParam("ctf_orbit_pool"..teamID, 0)
      spSetGameRulesParam("ctf_orbit_tickets"..teamID, 0)
      spSetGameRulesParam("ctf_orbit_timer"..teamID, COM_DROP_TIMER)
      ActivePlayers[select(2,spGetTeamInfo(teamID))] = teamID
      TeamsInAlliance[allyTeam][teamID] = true
      CountInAlliance[allyTeam] = CountInAlliance[allyTeam] + 1
    end
  end
  -- TODO disperse CCs amongst players, rather than giving all to single player
  for _,data in pairs(CentreSpawns) do
    local y = spGetGroundHeight(data.x, data.z)
    if (y < waterLevel) then
      y = waterLevel end
    CommandCenters[#CommandCenters+1] = { id = spCreateUnit("ctf_center", data.x, y, data.z, ToFacing(data.x, data.z), GetTeamFromAlly(data.allyTeam)), allyTeam = data.allyTeam, x = data.x, y = y, z = data.z }
    spSetUnitAlwaysVisible(CommandCenters[#CommandCenters].id, true)
    Godmode[CommandCenters[#CommandCenters].id] = true
    UnStuckGuys(data.x, data.z, 130)
  end
  GameStarted = true
  spEcho("CTF: Enjoy your game.")
end

function UnStuckGuys(x, z, sq)
  local sq = sq/2
  local d = 40
  local units = spGetUnitsInRectangle(x-sq,z-sq,x+sq,z+sq)
  local rd, udefId, udef
  for i = 1, #units do
    -- TODO make it slightly more intelegent
    udefId = spGetUnitDefID(units[i])
    udef = UnitDefs[udefId]
    if (udef.canMove) then -- naturally not structures
      rd = math.random(1,4) -- n,e,s,w
      if (rd == 1) then
	spSetUnitPosition(units[i], x-sq-40, z-sq-40)
	Spring.MoveCtrl.SetPosition(units[i], x-sq-40, z-sq-40)
      elseif (rd == 2) then
	spSetUnitPosition(units[i], x+sq+40, z-sq-40)
	Spring.MoveCtrl.SetPosition(units[i], x+sq+40, z-sq-40)
      elseif (rd == 3) then
	spSetUnitPosition(units[i], x-sq-40, z+sq+40)
	Spring.MoveCtrl.SetPosition(units[i], x-sq-40, z+sq+40)
      else
	spSetUnitPosition(units[i], x-sq+40, z+sq+40)
	Spring.MoveCtrl.SetPosition(units[i], x-sq+40, z+sq+40)
      end
    end
  end
end

function GetTeamFromAlly(allyTeam)
  -- get any non-dead player on team, actually simple now
  local teams = {}
  local best_elo = 0
  local best_target
  for _,teamID in ipairs(spGetTeamList(allyTeam)) do
    local _, active, spec, _, _, _, _, _, _, customKeys = spGetPlayerInfo(select(2,spGetTeamInfo(teamID)))
    if active and not spec and not spGetTeamRulesParam(teamID, "WasKilled") then -- non dead, fine give him stuff ?
      teams[#teams+1] = teamID
      local leader = select(2, spGetTeamInfo(teamID))
      local customKeys = select(10,spGetPlayerInfo(leader))
      if (customKeys.elo) and (tonumber(customKeys.elo) > best_elo) then
	best_elo = tonumber(customKeys.elo)
	best_target = teamID
      end
    end
  end
  if (best_target) then 
    return best_target
  elseif (teams ~= nil) and (#teams > 0) then
    return teams[random(1,#teams)]
  else -- uh uh
    teams = spGetTeamList(allyTeam)
    if (teams == nil) or (#teams < 1) then
      spEcho("CTF: Couldn't spawn flag base, no players present in ally team. Exiting...")
      gadgetHandler:RemoveGadget()
      return
    end
    return teams[random(1,#teams)]
  end
end

--//------------------ Code to determine command center spawn positions and teleport stucked commanders away -- END
--//------------------ Misc code -- BEGIN

function Payday()
  local income,teams
  local candidatesForTake
  for allyTeam,flags in pairs(FlagAmount) do -- TODO not give m&e bonus to afk players
    if (flags > 0) then
      income = ME_BONUS_C[FlagAmount[allyTeam]] * ME_CENTER_CURRENT_BONUS
      spSetGameRulesParam("ctf_income_team"..allyTeam, floor(income*metal_mult*100))
      local inc = income*(1/CountInAlliance[allyTeam])
      for teamID,_ in pairs(TeamsInAlliance[allyTeam]) do
	spAddTeamResource(teamID, "m", inc*metal_mult)
	spAddTeamResource(teamID, "e", inc*energy_mult)
      end
    else
      spSetGameRulesParam("ctf_income_team"..allyTeam, 0)
    end
  end
end

function UpgradeCenters()
  ME_CENTER_LVL = ME_CENTER_LVL + 1
  spEcho("CTF: Your income (lvl"..ME_CENTER_LVL..") has been upgraded, enjoy your additional resources!")
  spSetGameRulesParam("ctf_cc_lvl", ME_CENTER_LVL)
  local bonus = ME_CENTER_BONUS_INIT
  local extra = 1
  for i=1,ME_CENTER_LVL do
    extra = extra+bonus
    bonus = bonus/2
  end
  -- so it's 1 on lvl 0
  -- 1.5 on lvl 1
  -- 1.75 on lvl 2
  -- and finaly 1.875 extra on lvl 3
  ME_CENTER_CURRENT_BONUS = extra
end

function gadget:UnitPreDamaged(unitID) --, unitDefID, unitTeam, damage, paralyzer)
  if (Godmode[unitID]) then --or (DroppedFlags[unitID]) then
    return 0
  end
  --return damage
end

function ParseCoords(line)
  params={}
  for word in line:gmatch("[^%s]+") do
    params[#params+1]=tonumber(word)
  end
  return params
end

function gadget:RecvLuaMsg(line, playerID)
  local _, _, spectator, teamID, allyTeam = spGetPlayerInfo(playerID)
  if (not spectator) then
    if line:find("ctf_respawn") then
      local params = ParseCoords(line)
      CommDrop(playerID,teamID,allyTeam,params[1],params[2],params[3])
    end
  end
end

function InsideMap(x,z)
  if (x >= 0) and (x <= mapWidth) and (z >= 0) and (z <= mapHeight) then
    return true
  else
    return false
  end
end

function NoEnemyCarriersNear(allyTeam, x, z)
  for unitID, enemyTeam in pairs(FlagCarrier) do
    if (enemyTeam ~= allyTeam) then
      local cx,_,cz = spGetUnitPosition(unitID)
      if (disSQ(x,z,cx,cz) <= DENY_DROP_RADIUS) then
	return false
      end
    end
  end
  return true
end

-- modified start_unit_setup code FIXME this needs to be tested with commends lol
function CommDrop(playerID,teamID,allyTeam,x,y,z)
  -- get start unit
  local startUnit = GG.startUnits[teamID] and GG.startUnits[teamID] or "armcom1"
  
  local customKeys = select(10, spGetPlayerInfo(playerID))
  if customKeys and customKeys.jokecomm then
    startUnit = DEFAULT_UNIT
  end
  if startUnit and spIsPosInLos(x,y,z,allyTeam) and InsideMap(x,z) and NoEnemyCarriersNear(allyTeam,x,z) then -- if not in LoS... well, try again!
    -- check whether there is better com
    local max_morph = FLAG_AMOUNT_INIT - FlagAmount[allyTeam]
    if (max_morph > 5) then max_morph = 5 end
    if (max_morph > 1) then
      local startUnit2 = string.sub(startUnit, 1, -2)..max_morph
      if (UnitDefNames[startUnit2]) then -- ohhh
	startUnit = startUnit2
      end
    end
    OrbitDrop[#OrbitDrop+1] = {
      at = spGetGameFrame()+(CTF_ONE_SECOND_FRAME*COM_DROP_DELAY),
      startUnit = startUnit, x = x,
      y = y, z = z, facing = InvertFacing(ToFacing(x,z)), teamID = teamID }
    CommanderPool[teamID]=CommanderPool[teamID]-1
    CommanderTickets[teamID]=CommanderTickets[teamID]-1
    CommanderTimer[teamID]=COM_DROP_TIMER
    spSetGameRulesParam("ctf_orbit_pool"..teamID, CommanderPool[teamID])
    spSetGameRulesParam("ctf_orbit_tickets"..teamID, CommanderTickets[teamID])
    spSetGameRulesParam("ctf_orbit_timer"..teamID, COM_DROP_TIMER)
  end
end

function DeliverDrops(f)
  for i,data in pairs(OrbitDrop) do
    if (data) and (data.at < f) then
      local unitID = GG.DropUnit(data.startUnit, data.x, data.y, data.z, data.facing, data.teamID)
      if (unitID) then
	Spring.SpawnCEG("teleport_in", data.x, data.y, data.z)
	OrbitDrop[i] = nil
      end -- else give ability again, com drop failed... FIXME
    end
  end
end

function PlayerDied(playerID, teamID)--, allyTeam)
  -- basically if team dies or player resigns, give his pool and tickets to other alive players
  -- so if it's 2 vs 5 in the end, the team of 2 guys will probably have 3 and 2 commanders lol
  -- and they will be able to call in as many!
  -- TODO this function needs lots of clean up! and some optimizing!
  local pool_to_give = CommanderPool[teamID]
  local tickets_to_give = CommanderTickets[teamID]
  CommanderPool[teamID]=0
  CommanderTickets[teamID]=0
  CommanderTimer[teamID]=COM_DROP_TIMER
  spSetGameRulesParam("ctf_orbit_pool"..teamID, 0)
  spSetGameRulesParam("ctf_orbit_tickets"..teamID, 0)
  spSetGameRulesParam("ctf_orbit_timer"..teamID, COM_DROP_TIMER)
  ActivePlayers[playerID] = nil
  local oldAllyTeam
  for allyTeam,_ in pairs(FlagAmount) do
    for compareID,_ in pairs(TeamsInAlliance[allyTeam]) do
      if (compareID == teamID) then
	TeamsInAlliance[allyTeam][teamID] = nil
	CountInAlliance[allyTeam] = CountInAlliance[allyTeam] - 1
	oldAllyTeam = allyTeam
	break
      end
    end
  end
  if (oldAllyTeam == nil) then return end -- couldn't figure out? well too bad...
  if (pool_to_give == 0) and (tickets_to_give == 0) then return end -- job well done
  local highestRank = 0
  local highestPool = 0
  local candidatesForTake = {}
  for cteamID,_ in pairs(TeamsInAlliance[oldAllyTeam]) do
    local leader = select(2, spGetTeamInfo(cteamID))
    local _, active, spec, _, _, _, _, _, _, customKeys = spGetPlayerInfo(select(2,spGetTeamInfo(cteamID)))
    if not spec and not spGetTeamRulesParam(cteamID, "WasKilled") then
      local elo = 0
      if (customKeys) and (customKeys.elo) then
	elo = tonumber(customKeys.elo)
      end
      candidatesForTake[#candidatesForTake+1] = {team = cteamID, rank = elo, pool = CommanderPool[cteamID], tickets = CommanderTickets[cteamID]}
      if (elo > highestRank) then
	highestRank = rank
      end
      if (CommanderPool[cteamID] > highestPool) then
	highestPool = CommanderPool[cteamID]
      end
    end
  end
  if (#candidatesForTake==0) then return end -- job well done  
  -- TODO implement it the way so it prefers to give high elo players pool first, and tickets too, and then the rest of the team
  -- just sort candidatesForTake by elo... in some function
  local try_again = true
  while (try_again) and (pool_to_give > 0) do
    for i=1,#candidatesForTake do
      if (pool_to_give == 0) then break end
      local player = candidatesForTake[i]
      if highestPool > player.pool then
	CommanderPool[player.team] = CommanderPool[player.team] + 1
	spSetGameRulesParam("ctf_orbit_pool"..player.team, CommanderPool[player.team])
	pool_to_give = pool_to_give - 1
	try_again = false
      end
    end
    if (try_again) then
      highestPool = highestPool + 1
    end
  end
  try_again = true
  -- new tickets do not reset com timer... hope that's fine?
  while (try_again) and (tickets_to_give > 0) do
    try_again = false
    for i=1,#candidatesForTake do
      if (tickets_to_give == 0) then break end
      local player = candidatesForTake[i]
      if player.tickets < player.pool then
	CommanderTickets[player.team] = CommanderTickets[player.team] + 1
	spSetGameRulesParam("ctf_orbit_tickets"..player.team, CommanderTickets[player.team])
	tickets_to_give = tickets_to_give - 1
	try_again = true
      end
    end
  end
end

function LetThemCallBackup(allyTeam)
  teams = spGetTeamList(allyTeam)
  for teamID,_ in pairs(TeamsInAlliance[allyTeam]) do
    if (CommanderSpeedUpTimer[teamID]) then -- if you suicided com you get no extra :)
      CommanderTimer[teamID] = 3 -- or maybe 1.. or 0?
    end
  end
end

function OrbitTimer()
  for allyTeam,flags in pairs(FlagAmount) do
    for teamID,_ in pairs(TeamsInAlliance[allyTeam]) do
      if (CommanderPool[teamID] > CommanderTickets[teamID]) then
	CommanderTimer[teamID] = CommanderTimer[teamID] - 1
      end
      if (CommanderTimer[teamID]) <= 0 then
	CommanderTimer[teamID] = COM_DROP_TIMER
	CommanderTickets[teamID] = CommanderTickets[teamID] + 1
	spSetGameRulesParam("ctf_orbit_tickets"..teamID, CommanderTickets[teamID])
      end
      spSetGameRulesParam("ctf_orbit_timer"..teamID, CommanderTimer[teamID])
    end
  end
end

function zDifference(z,z2)
  if (abs(z-z2) < MAX_Z_DIFFERENCE) then
    return true
  else
    return false
  end
end
  
function gadget:UnitUnloaded(unitID)
  --BlackListed[unitID] = nil -- ok
  BlackList(unitID, 3) -- no insta grab and pickup! lal
end

function gadget:UnitLoaded(unitID)
  BlackListed[unitID] = -1 -- forever blacklisted
end

function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

function RunToBase(unitID, teamID, allyTeam)
  local best_id = 0
  local best_dist = nil
  local x,y,z = spGetUnitPosition(unitID)
  for i=1,#CommandCenters do
    local cc = CommandCenters[i]
    if (cc.allyTeam == allyTeam) then
      local dist = disSQ(x,z,cc.x,cc.z)
      if (best_dist == nil) or (dist < best_dist) then
	best_dist = dist
	best_id = i
      end
    end
  end
  -- run towards it
  if (best_dist ~= nil) then
    local tx = CommandCenters[best_id].x
    local tz = CommandCenters[best_id].z
    if (tx > x) then tx = tx-100
    else tx = tx+100 end
    if (tz > z) then tz = tz-100
    else tz = tz+100 end
    -- FIXME make sure unit does this, and not stands...
    spGiveOrderToUnit(unitID, CMD_INSERT, {0, CMD_MOVE, 0, tx, 0, tz}, {"alt"}) -- FIXME not always works
  end
end

--//------------------ Misc code -- BEGIN
--//------------------ CTF logic code -- BEGIN

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (cmdID == CMD_DROP_FLAG) then
    DropFlagCmd(unitID, unitDefID, teamID, cmdID, cmdParams)
    return false
  end
  return true
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
  if (cmdID ~= CMD_DROP_FLAG) then
    return false
  end
  return true, DropFlagCmd(unitID, unitDefID, teamID, cmdID, cmdParams)
end

function BlackList(unitID, time)
  BlackListed[unitID] = (time*CTF_ONE_SECOND_FRAME)+spGetGameFrame()
end

function DropFlagCmd(unitID, unitDefID, teamID, cmdID, cmdParams)
  if not(FlagCarrier[unitID]) then
    return false
  end
  local x,y,z = spGetUnitPosition(unitID)
  -- TODO forbid flag drop instead of returning it to enemy, lol, if it's impossible to drop flag or terrain is really bad (highslope/etc)
  if (InsideMap(x,z) == false) then
    ReturnFlag(nil, nil, FlagCarrier[unitID]) -- flag outside of map
  else
    BlackList(unitID, 3) -- forbid unit to pick up flags for 3 seconds
    DropFlag(FlagCarrier[unitID], x, y, z)
  end
  FlagCarrier[unitID] = nil
  spSetUnitAlwaysVisible(unitID, false)
  return true
end

function gadget:UnitTaken(unitID, unitDefID, teamID, newTeamID)
  if (FlagCarrier[unitID]) then
    local oldAllyTeam = select(6,spGetTeamInfo(teamID))
    local allyTeam = select(6,spGetTeamInfo(newTeamID))
    if (oldAllyTeam ~= allyTeam) then -- transfer things
      if (FlagCarrier[unitID] == allyTeam) then -- contested flag is the same as unit owner
	ReturnFlag(nil, unitID, allyTeam)
      else
	TransferFlag(unitID, oldAllyTeam, unitID, allyTeam, FlagCarrier[unitID])
      end
    end
  end
end

-- new func, hope i didn't mess up
function TransferFlag(unitID, oldAllyTeam, newUnitID, allyTeam, FlagAllyTeam)
  ContestedTeam[FlagAllyTeam] = allyTeam
  if (unitID ~= newUnitID) then -- probably morphed unit
    FlagCarrier[newUnitID] = FlagAllyTeam
    spSetUnitAlwaysVisible(newUnitID, true)
    spSetGameRulesParam("ctf_unit_stole_team"..FlagAllyTeam, newUnitID)
  end
end

function TeleportFlag(TargetAllyTeam)
  -- find who's holding this flag
  for unitID, allyTeam in pairs(FlagCarrier) do
    if (allyTeam == TargetAllyTeam) then
      ReturnFlag(nil, unitID, allyTeam)
    end
  end
  for flagID, data in pairs(DroppedFlags) do
    if (data.allyTeam == TargetAllyTeam) then
      ReturnFlag(flagID, nil, data.allyTeam)
    end
  end
  -- done
end

function DropFlag(allyTeam, x, y, z)
  local y = spGetGroundHeight(x,z)
  if (y < waterLevel) then
    y = waterLevel end
  local flagID = spCreateUnit("ctf_flag", x, y, z, ToFacing(x,z), GetTeamFromAlly(allyTeam))
  if (flagID == nil) then
--     spEcho("DropFlag failed")
    ReturnFlag(nil, nil, allyTeam)
  else
--     spEcho("Dropped flag success")
    ReturnFlagTimer[flagID] = LONELY_FLAG_TIMER
    spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, flagID)
    DroppedFlags[flagID] = { allyTeam = allyTeam, x = x, y = y, z = z, id = flagID }
    spSetUnitAlwaysVisible(flagID, true)
  end
end

function ReturnFlag(flagID, unitID, allyTeam)
  if (flagID) then
    DroppedFlags[flagID] = nil
    spDestroyUnit(flagID, false, true)
  end
  FlagAmount[allyTeam] = FlagAmount[allyTeam]+1
  spSetGameRulesParam("ctf_flags_team"..allyTeam, FlagAmount[allyTeam])
  ContestedTeam[allyTeam] = nil
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, 0)
  DefeatTimer[allyTeam] = TIMER_DEFEAT
  spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, DefeatTimer[allyTeam])
  if (unitID) then
    spSetUnitAlwaysVisible(unitID, false)
    spSetGameRulesParam("ctf_unit_stole_team"..FlagCarrier[unitID], 0)
  end
--   spEcho("Return flag "..tostring(flagID).." "..tostring(unitID).." "..tostring(allyTeam).." "..tostring(spValidUnitID(unitID)))
end

function PickFlag(flagID, unitID, allyTeam, enemyTeam)
  DroppedFlags[flagID] = nil
  spDestroyUnit(flagID, false, true)
  FlagCarrier[unitID] = allyTeam
  ContestedTeam[allyTeam] = enemyTeam
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, unitID)
  spSetUnitAlwaysVisible(unitID, true)
  local isAI = select(4,spGetTeamInfo(spGetUnitTeam(unitID)))
  if (isAI) then
    RunToBase(unitID, teamID, enemyTeam)
  end
--   spEcho("Pick flag "..tostring(flagID).." "..tostring(unitID).." "..tostring(allyTeam).." "..tostring(enemyTeam).." "..tostring(spValidUnitID(unitID)))
end

function StealFlag(unitID, allyTeam, enemyTeam)
  FlagCarrier[unitID] = allyTeam
  ContestedTeam[allyTeam] = enemyTeam
  FlagAmount[allyTeam] = FlagAmount[allyTeam]-1
  spSetGameRulesParam("ctf_flags_team"..allyTeam, FlagAmount[allyTeam])
  spSetUnitAlwaysVisible(unitID, true)
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, unitID)
  -- if it's AI make AI run towards nearest command center
  local isAI = select(4,spGetTeamInfo(spGetUnitTeam(unitID)))
  if (isAI) then
    RunToBase(unitID, teamID, enemyTeam)
  end
--   spEcho("Steal flag "..tostring(unitID).." "..tostring(allyTeam).." "..tostring(enemyTeam).." "..tostring(spValidUnitID(unitID)))
end

function ScoreFlag(unitID, allyTeam, enemyTeam)
  FlagAmount[allyTeam] = FlagAmount[allyTeam]+1
  spSetGameRulesParam("ctf_flags_team"..allyTeam, FlagAmount[allyTeam])
  spSetUnitAlwaysVisible(unitID, false)
  spSetGameRulesParam("ctf_unit_stole_team"..FlagCarrier[unitID], 0)
  DefeatTimer[allyTeam] = TIMER_DEFEAT
  spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, DefeatTimer[allyTeam])
  LetThemCallBackup(FlagCarrier[unitID])
--   spEcho("Score flag "..tostring(unitID).." "..tostring(allyTeam).." "..tostring(enemyTeam).." "..tostring(spValidUnitID(unitID)))
  ContestedTeam[FlagCarrier[unitID]] = nil
  FlagCarrier[unitID] = nil
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  if (spValidUnitID(unitID)) then
    --BlackListed[unitID] = -1 -- lol, awesome bug when unit that dies picks flag back up and dies with it
    BlackList(unitID, 10) -- forbid for 10 seconds, by that time unit should be complitely removed from game
    -- smbdy drops flag on death
    if (FlagCarrier[unitID]) then
--       spEcho("Unit destroyed, had flag")
      if (spGetUnitRulesParam(unitID, "wasMorphedTo") ~= nil) then
	TransferFlag(unitID, spGetUnitAllyTeam(unitID), spGetUnitRulesParam(unitID, "wasMorphedTo"), spGetUnitAllyTeam(unitID), FlagCarrier[unitID])
      else
	local x,y,z = spGetUnitPosition(unitID)
	if (InsideMap(x,z) == false) then
	  ReturnFlag(nil, nil, FlagCarrier[unitID]) -- flag outside of map
	else
	  DropFlag(FlagCarrier[unitID], x, y, z)
	end
      end
      FlagCarrier[unitID] = nil
    end
    -- dropped flags return if they die for some reason
    if (DroppedFlags[unitID]) then
      ReturnFlag(nil, nil, DroppedFlags[unitID].allyTeam) -- flag destroyed
      DroppedFlags[flagID] = nil
    end
    -- commander died, pool+1
    if UnitDefs[unitDefID].customParams.commtype and (spGetUnitRulesParam(unitID, "wasMorphedTo") == nil) then
      CommanderPool[teamID]=CommanderPool[teamID]+1
      spSetGameRulesParam("ctf_orbit_pool"..teamID, CommanderPool[teamID])
    end
    -- commander died in battle, if enemy scores flag, this will speedup timer for com dropping for entire team
    if (spValidUnitID(attackerID) and UnitDefs[unitDefID].customParams.commtype and not(spAreTeamsAllied(teamID,attackerTeamID)) and (spGetUnitRulesParam(unitID, "wasMorphedTo") == nil)) and -- this commander was in battle, allow him to respawn!
	(FlagAmount[select(6,spGetTeamInfo(teamID))] < FLAG_AMOUNT_INIT) then
      CommanderSpeedUpTimer[teamID] = true
    end
  end
end

function RemoveCC(unitID)
  local index
  for i=1,#CommandCenters do
    local cc = CommandCenters[i]
    if (cc.id == unitID) then
      index = i
      break
    end
  end
  if (index ~= nil) then
    CommandCenters[index].allyTeam = GaiaAllyTeamID
    spTransferUnit(unitID, GaiaTeamID, false)
  end
end

function StealFlags()
  for i=1,#CommandCenters do
    local cc = CommandCenters[i]
    local allyTeam = cc.allyTeam
    if (GaiaAllyTeamID ~= allyTeam) then
      local x = cc.x
      local y = cc.y
      local z = cc.z
      local unitID
      if (FlagAmount[allyTeam] > 0) and (ContestedTeam[allyTeam] == nil) then
	unitID = GetAnyFlagThief(allyTeam, x, y, z, CAP_RADIUS)
	if ((unitID ~= nil) and (spValidUnitID(unitID))) then
	  StealFlag(unitID, allyTeam, spGetUnitAllyTeam(unitID))
	end
      end
    end
  end
end

function PickFlags()
  -- any flags on the ground?
  for flagID,data in pairs(DroppedFlags) do
    local x = data.x
    local y = data.y
    local z = data.z
    local allyTeam = data.allyTeam
    local unitID
    unitID = GetAnyFlagThief(allyTeam, x, y, z, PICK_RADIUS)
    if ((unitID ~= nil) and (spValidUnitID(unitID))) then
      PickFlag(flagID, unitID, allyTeam, spGetUnitAllyTeam(unitID))
    end
  end
  -- any flags in bases?
end

function ReturnFlags()
  -- any flags on the ground?
  for flagID,data in pairs(DroppedFlags) do
    local x = data.x
    local y = data.y
    local z = data.z
    local allyTeam = data.allyTeam
    local unitID
    unitID = GetAnyAlly(allyTeam, x, y, z, PICK_RADIUS)
    if ((unitID ~= nil) and (spValidUnitID(unitID))) then
      ReturnFlag(flagID, nil, allyTeam)
    end
  end
end

function ScoreFlags()
  for i=1,#CommandCenters do
    local cc = CommandCenters[i]
    local allyTeam = cc.allyTeam
    if (GaiaAllyTeamID ~= allyTeam) then
      local x = cc.x
      local y = cc.y
      local z = cc.z
      local unitID
      unitID = GetAnyFlagCarrier(allyTeam, x, y, z, CAP_RADIUS)
      if (unitID ~= nil) and (spValidUnitID(unitID)) and (ContestedTeam[allyTeam] == nil) then
	ScoreFlag(unitID, allyTeam, spGetUnitAllyTeam(unitID))
      end
    end
  end
end

function IsUnitAllied(unitID,allyTeam)
  return (spGetUnitAllyTeam(unitID) == allyTeam)
end

function GetAnyFlagCarrier(allyTeam, x, y, z, cap_radius) -- BlockListed unit can't return flag, but that's kinda ok
  local units = spGetUnitsInCylinder(x, z, cap_radius)
  for i=1,#units do
    local unitID = units[i]
    local _, y2, _ = spGetUnitPosition(unitID)
    if IsUnitAllied(unitID, allyTeam) and (BlackListed[unitID]==nil) and (FlagCarrier[unitID] ~= nil) and (FlagCarrier[unitID] ~= allyTeam) and zDifference(y,y2) then
      return unitID
    end
  end
  return nil
end

function GetAnyAlly(allyTeam, x, y, z, cap_radius)
  local units = spGetUnitsInCylinder(x, z, cap_radius)
  for i=1,#units do
    local unitID = units[i]
    if (IsUnitAllied(unitID, allyTeam)) then
      local _, y2, _ = spGetUnitPosition(unitID)
      local udefId = spGetUnitDefID(unitID)
      local udef = UnitDefs[udefId]
      if (udef.canMove) and (not(udef.canFly)) and (BlackListed[unitID]==nil) and (not(spGetUnitIsCloaked(unitID))) and zDifference(y,y2) then -- I so imagine rage when smbdy steals with rectors or such
	return unitID
      end
    end
  end
  return nil
end

function GetAnyFlagThief(allyTeam, x, y, z, cap_radius)
  local units = spGetUnitsInCylinder(x, z, cap_radius)
  for i=1,#units do
    local unitID = units[i]
    if ((IsUnitAllied(unitID, allyTeam) == false) and (FlagAmount[spGetUnitAllyTeam(unitID)] ~= nil)) then
      local _, y2, _ = spGetUnitPosition(unitID)
      local udefId = spGetUnitDefID(unitID)
      local udef = UnitDefs[udefId]
      if (udef.canMove) and (not(udef.canFly)) and (BlackListed[unitID]==nil) and (not(spGetUnitIsCloaked(unitID))) and zDifference(y,y2) then -- I so imagine rage when smbdy steals with rectors or such
	return unitID
      end
    end
  end
  return nil
end

function ContestedAlready(allyTeam1, allyTeam2)
  for i,data in pairs(ContestData) do -- FIXME i will find some faster and better way...
    if (data.rival1 == allyTeam1 and data.rival2 == allyTeam2) or
	(data.rival1 == allyTeam2 and data.rival2 == allyTeam1) then
      return i
    end
  end
  return false
end

function InsertContest(allyTeam1, allyTeam2)
  ContestData[#ContestData+1] = {
    rival1 = allyTeam1,
    rival2 = allyTeam2,
    timer = TIMER_TELEPORT_FLAGS,
  }
  return #ContestData
end

function DestroyContest(index)
--   spEcho("Contest destroyed")
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival1,TIMER_TELEPORT_FLAGS)
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival2,TIMER_TELEPORT_FLAGS)
  ContestData[index] = nil
end

function ContestTick(index)
--   spEcho("Tick tack")
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival1,ContestData[index].timer)
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival2,ContestData[index].timer)
  ContestData[index].timer = ContestData[index].timer-1
  return ContestData[index].timer
end

function ReturnStucked() -- TODO make widget know about this, otherwise it's not obvious
  for _,data in pairs(DroppedFlags) do
    ReturnFlagTimer[data.id] = ReturnFlagTimer[data.id] - 1
    if (ReturnFlagTimer[data.id] <= 0) then
      ReturnFlag(data.id, nil, data.allyTeam)
    end
  end
end

function SolveContested()
  for unitID1, allyTeam1 in pairs(FlagCarrier) do
    for unitID2, allyTeam2 in pairs(FlagCarrier) do
      if (unitID1 ~= unitID2) and (allyTeam1 ~= allyTeam2) and (ContestedTeam[allyTeam2] == allyTeam1) and (ContestedTeam[allyTeam1] == allyTeam2) then 
	local index = ContestedAlready(allyTeam1,allyTeam2)
	if index == false then
	  index = InsertContest(allyTeam1, allyTeam2)
	end
      end
    end
  end
  for index,data in pairs(ContestData) do -- FIXME i will find some faster and better way...
    if data then -- FIXME probably not needed to check this
      if (ContestedTeam[data.rival1] ~= nil) and (ContestedTeam[data.rival2] ~= nil) then
	local time = ContestTick(index)+1 -- TODO make this visible to widgets
	if (time <= 0) then
	  TeleportFlag(data.rival1)
	  TeleportFlag(data.rival2)
	  ContestedTeam[data.rival1] = nil
	  ContestedTeam[data.rival2] = nil
	  DestroyContest(index)
	end
      else
	DestroyContest(index)
      end
    end
  end
end

function ContestAnyone(MyAllyTeam)
  for allyTeam,flags in pairs(FlagAmount) do
    if (allyTeam ~= MyAllyTeam) and (ContestedTeam[allyTeam] == MyAllyTeam) then
      return true
    end
  end
  return false
end

function CountDefeat()
  for allyTeam,flags in pairs(FlagAmount) do
    if (flags == 0) and (ContestedTeam[allyTeam] == nil) and (not(ContestAnyone(allyTeam))) then
      if (DefeatTimer[allyTeam] <= 0) then
	-- die :(
	for teamID,_ in pairs(TeamsInAlliance[allyTeam]) do
	  spKillTeam(teamID)
	  spSetTeamRulesParam(teamID, "WasKilled", 1)
	  local units = spGetTeamUnits(teamID)
	  for i = 1, #units do
	    if (spValidUnitID(units[i])) then
	      if (Godmode[units[i]]) then
		-- probably command center
		RemoveCC(units[i]) -- actually makes CC neutral, and disables it
	      else
		if (DroppedFlags[units[i]]) then
		  DroppedFlags[units[i]] = nil
		  spDestroyUnit(units[i], false, true)
		else
		  spDestroyUnit(units[i], true, false)
		end
	      end
	    end
	  end
	end
      end
      DefeatTimer[allyTeam] = DefeatTimer[allyTeam]-1
      spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, DefeatTimer[allyTeam])
    end
  end
end

function CheckForDead()
--   local players = Spring.GetPlayerList()
--   for i=1,#players do
--     local playerID = players[i]
--     local name,active,spec,team,allyTeam,ping = spGetPlayerInfo(playerID)
--     spEcho("___"..tostring(name).." "..tostring(spec).." "..tostring(team).." "..tostring(allyTeam))
--   end
  for playerID,_ in pairs(ActivePlayers) do
    local name, active, spec = spGetPlayerInfo(playerID)
--     spEcho("___"..tostring(name).." "..tostring(spec).." "..tostring(teamID).." "..tostring(select(6,spGetTeamInfo(teamID))))
    local teamID = select(4,spGetPlayerInfo(playerID))
    if name==nil or spec or spGetTeamRulesParam(teamID, "WasKilled") then -- apparently this is old team, "WasKilled") then
      PlayerDied(playerID, teamID)
    end
  end
end

function BlackListTimer(f)
  for unitID,time in pairs(BlackListed) do
    if (time ~= -1) then
      if (time < f) then
	BlackListed[unitID] = nil
      end
    end
  end
end

function gadget:GameFrame (f)
  if not(GameStarted) then
    if DelayedInit ~= nil then -- i so did not want to do this
      if (f%DelayedInit)==0 then
	SpawnCommandCenters()
      end
    end
    return
  end
  if ((f%ME_BONUS_DELAY)==ME_BONUS_DELAY) then
    if (ME_CENTER_LVL < ME_CENTER_UP_MAX) then
      UpgradeCenters()
    end
  end
  if ((f%CTF_ONE_SECOND_FRAME)==0) then
    CheckForDead()
    ---
    -- any enemy unit near any of your command centers takes your flag and contest begins!
    ScoreFlags()
    ReturnFlags()
    PickFlags()
    StealFlags()
    ReturnStucked()
    ---
    SolveContested() -- if teams hold each other flags in units
    Payday() -- give resources for having flags
    CountDefeat() -- if you have 0 flags left and no contested flags either, you are doomed
    OrbitTimer()
    DeliverDrops(f)
    BlackListTimer(f)
  end
end
  
--//------------------ CTF logic code -- END
--//------------------ Core -- BEGIN

function gadget:Initialize()
  if (not modOptions.zkmode) or (tostring(modOptions.zkmode) ~= "ctf") then
    gadgetHandler:RemoveGadget()
  end
end

function gadget:GameStart()
  mapWidth = Game.mapSizeX
  mapHeight = Game.mapSizeZ
  SpawnCommandCenters()
end

--//------------------ Core -- END

else --------------------------------------------------------------------------------------------------- unsycned

function ParseRespawn(cmd, line, words, playerID)
  if (#words == 4) then
    spSendLuaRulesMsg("ctf_respawn".." "..words[1].." "..words[2].." "..words[3])
  end
end

function gadget:Initialize()
  if (not Spring.GetModOptions().zkmode) or (tostring(Spring.GetModOptions().zkmode) ~= "ctf") then
    gadgetHandler:RemoveGadget()
    return
  end
  gadgetHandler:AddChatAction("ctf_respawn", ParseRespawn)
end

end