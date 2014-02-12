local version = "0.0.3"

function gadget:GetInfo()
  return {
    name      = "Capture The Flag",
    desc      = "CTF original game mode. Capture the flags! Version "..version,
    author    = "Tom Fyuri",
    date      = "Feb 2014",
    license   = "GPL v2 or later",
    layer     = 1,
    enabled   = false
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
5. If you lose all flags (enemy scores your last flag), you have 3 minutes to redeem your team by scoring 1 flag. If you fail to do so, you will lose the game.
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
- Having 0 flags will result in defeat within 3 minutes (it's okay if last flag is stolen though).
- Having many players in single team will result in multiple flag bases.
- You can capture only 1 flag at a time. If 2 teams control each other flags for 120 secs, flags are teleported back. -- TODO make it more complex if multiple teams control each other flags
- Walking over your own team's flag will teleport it back to the base.
- Walking over your enemy's flag will pick it up, bring it to your own base!
- Contested flags do not count towards bonus income!
- There can only be one single stolen&contested flag at a time!

  immediate TODO:
- Fix, improve and finalize CC spawn position system (almost done, it should support ffa and very small maps when it's done, and any amount of teams).
- Transfer and drop flag buttons.
- Detect if players resign.
- Rewrite widget (it only shows 2 teams, yet gadget supports more, almost).
- Multi-contest resolution (when multiple teams are stuck because they stealed each other flags).
- Some more endgame content (either superunit or turn CCs into superweapons for last team standing, so they finish other teams in spectacular way).
- Search and destroy last bugs and release this is 0.1 or smth.

  Changelog:
9 February 2014 - 0.0.1 beta	- First version. 
10 February 2014 - 0.0.2	- Second version with water support and few bug fixes.
11 February 2014 - 0.0.3	- Income lowered by 2. Bug fixes. CC spawn logic changed. Backup commanders are stackable. And lots of bug fixes. ]]--
  
-- NOTE: code is largely based on abandoned takeover game mode, it just doesn't have anything ingame voting related...

-- TODO FIXME write good randomizer... unless spring will pick some randomseed on it's own...
if (math.randomseed ~= nil) then
  --local r = Spring.DiffTimers(Spring.GetTimer(), Script.CreateScream())	-- FIXME crashes with "invalid args" error
  math.random()
  --math.randomseed(r)
end

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

local spGetPlayerInfo	    = Spring.GetPlayerInfo
local spGetAllyTeamList	    = Spring.GetAllyTeamList

local FlagCarrier = {} -- unitID has allyTeam's flag
local DroppedFlags = {} -- functions almost same as CC, expect if you pick your own flag it's teleported to CC instead of being picked up
local CommandCenters = {} -- arraylist centers
local FlagAmount = {} -- number per allyteam, essentially score
local ContestedTeam = {} -- if team's flag stolen it gets into this array
local ContestedTimer = {}
local ContestData = {} -- holds a tables with opposing allyTeams and timer...
local DefeatTimer = {} -- every second you have 0 flags you are doomed :D
-- if both teams are in this array a timer is set to teleport their flags to bases in 120 sec
local CallBackup = {} -- per team, holds lvl of commander player may call in (respawn)
local CommChoice = {} -- players can change commchoice ingame...
local OrbitDrop = {} -- delayed delivering...
local BlackList = {} -- per unitid.. i put here transported units and unblacklist on unloading/death
local CommanderPool = {} -- maximum amount of commanders per player
local CommanderTickets = {} -- amount of tickets per player
local CommanderTimer = {} -- timer starts to go down if player has less commanders than his pool allows, timer resets (and comm ticket is given) if enemy scores your team's flag
local CommanderSpeedUpTimer = {} -- by teamID, if enemy team scores, it will allow to call in backup comm much sooner
local Godmode = {} -- unitid... only CCs are dropped here, flags are not though
local ActivePlayers = {} -- players that are not killed
local PlayersInTeam = {} -- allyteam...
local PlayersPerTeam

-- local CMD_ATTACK	= CMD.ATTACK

local CopyTable = Spring.Utilities.CopyTable

-- rules
local TIMER_DEFEAT = 180 -- time in seconds when you lose because you have 0 flags left.
local TIMER_TELEPORT_FLAGS = 120 -- time in seconds if 2 teams hold each other flags - flags teleport back to bases
local PICK_RADIUS = 75
local PICK_RADIUS_SQ = PICK_RADIUS*PICK_RADIUS
local CAP_RADIUS = 250
local CAP_RADIUS_SQ = CAP_RADIUS*CAP_RADIUS
local DENY_DROP_RADIUS = 400 -- dont comdrop on enemy carrier... no fun
local DENY_DROP_RADIUS_SQ = DENY_DROP_RADIUS*DENY_DROP_RADIUS
local MAX_Z_DIFFERENCE = 75 -- no capturing from space lol
local FLAG_AMOUNT_INIT = 3
local ME_BONUS = function(i) return ((1.4^(1+i)+(1.5+(i*1.5)))-2.9)/2 end --[[
for every flag your team owns from 0 to 6 - your own income, examples:
flags 	1 second	1 minute
0	0.0		0.0
1	1.03		61.8
2	2.172		130.32
3	3.4708		208.248
4	4.98912		299.3472
5	6.814768	408.88608
6	9.0706752	544.240512
4 vs 2 - ~169 per minute advantage, your enemy respawns with 1lvl coms. -- +2.815m&e income per player seems fair to counter this with respawning few commanders.
5 vs 1 - ~347 per minute advantage, your enemy respawns with 2lvl coms. -- +5.785m&e income per player seems fair to counter this with respawning few commanders being lvl2.
6 vs 0 - ~544 per minute advantage, your enemy respawns with 3lvl coms and have 3 minutes to grab 1 flag before auto-resign.
this makes this entirely worthwhile to capture flags. because even by losing single flag you make your own position less favorable in the long run.
no matter what you do command center is indestructible, yet gives constant bonus income. ]]-- 
local ME_BONUS_C = {} -- this one fills in automatically from function above on gamestart, it's income per TEAM, NOT PER PLAYER!
local ME_BONUS_MULT = 1.0 -- tweaking?
local ME_BONUS_DELAY = 1920 -- 1 minute, this will be multiplied by player amount, so every DELAY minutes centres upgrade
local ME_CENTER_UP_MAX = 3 -- 3 upgrades max
local ME_CENTER_BONUS_INIT = 0.5 -- for every level the bonus is halved... read below ME_CENTER_CURRENT_BONUS
local ME_CENTER_INIT_LVL = 0
local ME_CENTER_LVL = ME_CENTER_INIT_LVL
local ME_CENTER_CURRENT_BONUS = 1 -- this get's changed to 1.5 1.75 and 1.875...
local COM_DROP_DELAY = 3 -- in seconds
local COM_DROP_TIMER = 300 -- 1 free ticket per 5 minutes
local CTF_ONE_SECOND_FRAME = 30 -- frames per second
-- NOTE maybe it's better to simply make centers behave like mexes so you may connect them to OD grid...

local energy_mult = 1.0 -- why not obey them too
local metal_mult = 1.0

local GameStarted = false

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

function FindClosest(ex,ey,cx,cy)
  local closest_index = 0
  local closest_dist = nil
  for index=1,#ex do
    local dist = disSQ(ex[index],ey[index],cx,cy)
    if (closest_dist == nil) or (dist < closest_dist) then
      closest_index = index
      closest_dist = dist
    end
  end
  return ex[closest_index],ey[closest_index],closest_index
end

function MakeGoodIndex(index,min,max)
  while (index<min) do
    index=index+max
  end
  while (index > max) do
    index=index-max
  end
  return index
end

function DetermineSpawns(SpawnBoxes)
  local CentreSpawns,player_num,allyTeam_num
  allyTeam_num = #SpawnBoxes
  player_num = 0
  players_per_team = 0
  for _,data in ipairs(SpawnBoxes) do
    player_num = player_num + data.player_count
    if (player_num > players_per_team) then
      players_per_team = player_num
    end
  end
  -- now figure out if map is narrow, if it is too narrow spawn only 1 CC, otherwise draw ellipse inside spring map and figure out fair coordinates to spawn centers
  -- this allows to support 2 & 4 teams just fine, though i won't put any limit for team number
  local cc_count = 1
  local narrow = false
  if ((mapWidth/5) > mapHeight) or ((mapHeight/5) > mapWidth) or (mapHeight < 400) or (mapWidth < 400) then
    narrow = true -- only 1 CC per allyteam, otherwise depending on player count
  end
  local X1=200
  local Y1=200
  local X2=mapWidth-200
  local Y2=mapHeight-200
  if ((mapWidth >= 1800) and (mapHeight >= 1800)) or ((mapWidth/3 >= 600) and (mapHeight/3 >= 600) and ((mapWidth+mapHeight)/2) >= 1800) then
    -- we can afford to do so!
    X1 = mapWidth*0.25
    Y1 = mapHeight*0.25
    X2 = mapWidth*0.75
    Y2 = mapHeight*0.75
  end
  local RX = (X2 - X1) / 2
  local RY = (Y2 - Y1) / 2
  local CX = (X2 + X1) / 2
  local CY = (Y2 + Y1) / 2
  local ex = {}; local ey = {}
  local angle = 0
  local step = 30 -- this makes 14 coordinates
  if (allyTeam_num > 4) then
    step = 10 + allyTeam_num * 3
  end
  while (angle < 360) do
    ex[#ex+1] = CX + cos(angle) * RX
    ey[#ey+1] = CY + sin(angle) * RY
    angle = angle + step
  end
  -- basically the most interesting thing in a way... determine the most closest ex,ey to spawn center, this one should be "base" while
  -- farsest to "base" should be extra centers, mark all 3, and remove "extra" ones depending on how many there should be (cc_count) param
  CentreSpawns = {}
  -- TODO more checks so that centers dont spawn too near each other
  local coord_per_team = floor(step/allyTeam_num/2) -- 30/8 = 3, that means we can have more 3 CCs, how? by select prev,next,prev-1,next+1 coord for each team :)
  local index
  if not(narrow) then
    index = MakeGoodIndex(5+coord_per_team, 1, #ex)
    if (disSQ(ex[1],ey[1],ex[index],ey[index]) < (550^2)) then
      narrow = true
    end
    index = MakeGoodIndex((-8+(1-coord_per_team)), 1, #ex)
    if (disSQ(ex[1],ey[1],ex[index],ey[index]) < (550^2)) then
      narrow = true
    end
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
  local cx,cy,cx2,cy2,cx3,cy3
  for _,spawn in ipairs(SpawnBoxes) do
    cx,cy,index = FindClosest(ex, ey, spawn.centerx, spawn.centerz)
    if (coord_per_team >= 2) then
      index = MakeGoodIndex(4+index+coord_per_team, 1, #ex)
      cx2 = ex[index]
      cy2 = ey[index]
      index = MakeGoodIndex((-8+(index-coord_per_team)), 1, #ex) -- god.. i will totally not understand how it works pretty soon
      cx3 = ex[index]
      cy3 = ey[index]
      -- we have 3 CCs, now depending on how many we actually need...
      if (cc_count == 1) then
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx, z = cy, allyTeam = spawn.allyTeam
	}
      elseif (cc_count == 2) then
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx2, z = cy2, allyTeam = spawn.allyTeam
	}
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx3, z = cy3, allyTeam = spawn.allyTeam
	}
      else
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx, z = cy, allyTeam = spawn.allyTeam
	}
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx2, z = cy2, allyTeam = spawn.allyTeam
	}
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx3, z = cy3, allyTeam = spawn.allyTeam
	}
      end
    elseif (coord_per_team == 1) then
      if (cc_count == 1) then
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx, z = cy, allyTeam = spawn.allyTeam
	}
      elseif (cc_count == 2) then
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx2, z = cy2, allyTeam = spawn.allyTeam
	}
	CentreSpawns[#CentreSpawns+1] = {
	  x = cx3, z = cy3, allyTeam = spawn.allyTeam
	}
      end
    else
      CentreSpawns[#CentreSpawns+1] = {
	x = cx, z = cy, allyTeam = spawn.allyTeam
      }
    end
  end
  -- TODO detect if mex position is inside CC, if yes shift CC slightly
  return CentreSpawns,players_per_team,player_num,allyTeam_num
end

function SpawnCommandCenters()
  local SpawnBoxes = {} -- TODO this code needs rewrite
  for _,allyTeam in ipairs(spGetAllyTeamList()) do
    local x1, z1, x2, z2 = spGetAllyTeamStartBox(allyTeam)
    if x1 then
      local width = abs(x2-x1)
      local height = abs(z2-z1)
      if (width < mapWidth) or (height < mapHeight) then
	SpawnBoxes[#SpawnBoxes+1] = {
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
  
  local CentreSpawns,PlayersPerTeam,player_num,allyTeam_num = DetermineSpawns(SpawnBoxes)
  
  if (CentreSpawns == nil) then
    gadgetHandler:RemoveGadget()
    return
  end
  
  for _,a in ipairs(SpawnBoxes) do
    DefeatTimer[a.allyTeam] = TIMER_DEFEAT
    FlagAmount[a.allyTeam] = FLAG_AMOUNT_INIT
    PlayersInTeam[a.allyTeam] = {}
    spSetGameRulesParam("ctf_contest_time_team"..a.allyTeam,TIMER_TELEPORT_FLAGS)
    spSetGameRulesParam("ctf_flags_team"..a.allyTeam, FLAG_AMOUNT_INIT)
    spSetGameRulesParam("ctf_defeat_time_team"..a.allyTeam, TIMER_DEFEAT)
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
  
  -- TODO disperse CCs amongst players, rather than giving all to single player
  for _,data in ipairs(CentreSpawns) do
    local y = spGetGroundHeight(data.x, data.z)
    if (y < waterLevel) then
      y = waterLevel end
    CommandCenters[#CommandCenters+1] = { id = spCreateUnit("ctf_center", data.x, y, data.z, ToFacing(data.x, data.z), GetTeamFromAlly(data.allyTeam).team), allyTeam = data.allyTeam, x = data.x, y = y, z = data.z }
    spSetUnitAlwaysVisible(CommandCenters[#CommandCenters].id, true)
    Godmode[CommandCenters[#CommandCenters].id] = true
    UnStuckGuys(data.x, data.z, 130)
  end
  local max_flags = #SpawnBoxes * FLAG_AMOUNT_INIT
  for ip=0, max_flags do
    ME_BONUS_C[ip] = ME_BONUS(ip) * ME_BONUS_MULT * PlayersPerTeam
  end
  ME_BONUS_DELAY = ME_BONUS_DELAY * player_num
  
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
      ActivePlayers[teamID] = allyTeam
      PlayersInTeam[allyTeam][#PlayersInTeam[allyTeam]+1] = teamID
    end
  end
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

function GetTeamFromAlly(allyTeam) -- thanks game_lagmonitor.lua
  local teams = spGetTeamList(allyTeam)
  local highestRank = 0
  local candidatesForTake = {}
  local target
  -- look for active people to give units to, including AIs
  for i=1,#teams do
	  local leader = select(2, spGetTeamInfo(teams[i]))
	  local name, active, spectator, _, _, _, _, _, _, customKeys = spGetPlayerInfo(leader)
	  if active and not spectator and not spGetTeamRulesParam(teams[i], "WasKilled") then -- only consider giving to someone in position to take!
		  candidatesForTake[#candidatesForTake+1] = {name = name, team = teams[i], rank = ((tonumber(customKeys.elo) or 0))}
	  end
  end

  -- pick highest rank
  for i=1,#candidatesForTake do
	  local player = candidatesForTake[i]
	  if player.rank > highestRank then
		  highestRank = player.rank
		  target = player
	  end
  end

  -- no rank info? pick at random
  if not target and #candidatesForTake > 0 then
	  target = candidatesForTake[math.random(1,#candidatesForTake)]
  end

  return target
end

--//------------------ Code to determine command center spawn positions and teleport stucked commanders away -- END
--//------------------ Misc code -- BEGIN

function Payday()
  local income,teams
  local candidatesForTake
  for allyTeam,flags in pairs(FlagAmount) do
    if (flags > 0) then
      income = ME_BONUS_C[FlagAmount[allyTeam]] * ME_CENTER_CURRENT_BONUS
      spSetGameRulesParam("ctf_income_team"..allyTeam, floor(income*metal_mult*100))
      local inc = income/#PlayersInTeam[allyTeam]
      for _,teamID in pairs(PlayersInTeam[allyTeam]) do
	spAddTeamResource(teamID, "m", inc*metal_mult)
	spAddTeamResource(teamID, "e", inc*energy_mult)
      end
    end
  end
end

function UpgradeCenters()
  ME_CENTER_LVL = ME_CENTER_LVL + 1
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

-- function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions) --, fromSynced)
--   -- you shall not use the dormant unit
--   for i=1,#CommandCenters do
--     local cc = CommandCenters[i]
--     local ccID = cc.id
--     if (CMD_ATTACK == cmdID) and (#cmdParams == 1) and (cmdParams[1] == ccID) then -- you shall not reclaim me or touch me      
--       return false
--     end
--   end
--   return true
-- end

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
      y = y, z = z, facing = ToFacing(x,z), teamID = teamID }
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
    if (data) and (data.at <= f) then
      local unitID = GG.DropUnit(data.startUnit, data.x, data.y, data.z, data.facing, data.teamID)
      if (unitID) then
	Spring.SpawnCEG("teleport_in", data.x, data.y, data.z)
	OrbitDrop[i] = nil
      end -- else give ability again, com drop failed... FIXME
    end
  end
end

function PlayerDied(teamID, allyTeam)
  -- basically if team dies or player resigns, give his pool and tickets to other alive players
  -- so if it's 2 vs 5 in the end, the team of 2 guys will probably have 3 and 2 commanders lol
  -- and they will be able to call in as many!
  local pool_to_give = CommanderPool[teamID]
  local tickets_to_give = CommanderTickets[teamID]
  Spring.Echo("teamID "..teamID.." died having "..pool_to_give.." commanders and "..tickets_to_give.." tickets")
  CommanderPool[teamID]=0
  CommanderTickets[teamID]=0
  CommanderTimer[teamID]=COM_DROP_TIMER
  spSetGameRulesParam("ctf_orbit_pool"..teamID, 0)
  spSetGameRulesParam("ctf_orbit_tickets"..teamID, 0)
  spSetGameRulesParam("ctf_orbit_timer"..teamID, COM_DROP_TIMER)
  local teams = spGetTeamList(ActivePlayers[teamID])
  ActivePlayers[teamID] = nil
  for i=1,#PlayersInTeam[allyTeam] do
    if (PlayersInTeam[allyTeam][i] == teamID) then
      PlayersInTeam[allyTeam][i] = nil
      break
    end
  end
  if (pool_to_give == 0) and (tickets_to_give == 0) then return end -- job well done
  local highestRank = 0
  local highestPool = 0
  local candidatesForTake = {}
  for i=1,#teams do
    local leader = select(2, spGetTeamInfo(teams[i]))
    local name, active, spectator, _, _, _, _, _, _, customKeys = spGetPlayerInfo(leader)
    if active and not spectator and not spGetTeamRulesParam(teams[i], "WasKilled") then -- only consider giving to someone in position to take!
      candidatesForTake[#candidatesForTake+1] = {team = teams[i], rank = ((tonumber(customKeys.elo) or 0)), pool = CommanderPool[teamID], tickets = CommanderTickets[teamID]}
      if ((tonumber(customKeys.elo) or 0)) > highestRank then
	highestRank = rank
      end
      if (CommanderPool[teams[i]] > highestPool) then
	highestPool = CommanderPool[teams[i]]
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
  for _,teamID in pairs(PlayersInTeam[allyTeam]) do
    if (CommanderSpeedUpTimer[teamID]) then -- if you suicided com you get no extra :)
      CommanderTimer[teamID] = 3 -- or maybe 1.. or 0?
    end
  end
end

function OrbitTimer()
  for allyTeam,flags in pairs(FlagAmount) do
    for _,teamID in pairs(PlayersInTeam[allyTeam]) do
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
  BlackList[unitID] = false
end

function gadget:UnitLoaded(unitID)
  BlackList[unitID] = true
end

function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

--//------------------ Misc code -- BEGIN
--//------------------ CTF logic code -- BEGIN

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
  -- now restore score
  FlagAmount[TargetAllyTeam] = FlagAmount[TargetAllyTeam]+1
  spSetGameRulesParam("ctf_flags_team"..TargetAllyTeam, FlagAmount[TargetAllyTeam])
  -- done
end

function ReturnFlag(flagID, unitID, allyTeam)      
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
  
--   Spring.Echo("error team "..allyTeam.." returns it's flag!")
--   Spring.Echo("error team "..allyTeam.." flags: "..FlagAmount[allyTeam])
  
  if (flagID) then
    DroppedFlags[flagID] = nil
    spDestroyUnit(flagID, false, true)
  end
end

function DropFlag(allyTeam, x, y, z)
  local y = spGetGroundHeight(x,z)
  if (y < waterLevel) then
    y = waterLevel end
  local flagID = spCreateUnit("ctf_flag", x, y, z, ToFacing(x,z), GetTeamFromAlly(allyTeam).team) -- FIXME i think better would be to make it to rely on some var instead of func
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, flagID)
  DroppedFlags[flagID] = { allyTeam = allyTeam, x = x, y = y, z = z, id = flagID }
  spSetUnitAlwaysVisible(flagID, true)
end

function PickFlag(flagID, unitID, allyTeam, enemyTeam)
  FlagCarrier[unitID] = allyTeam
  ContestedTeam[allyTeam] = enemyTeam
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, unitID)
  spSetUnitAlwaysVisible(unitID, true)
  
--   Spring.Echo("error team "..enemyTeam.." picks "..allyTeam.." flag!")
  
  DroppedFlags[flagID] = nil
  spDestroyUnit(flagID, false, true)
end

function StealFlag(unitID, allyTeam, enemyTeam)
  FlagCarrier[unitID] = allyTeam
  ContestedTeam[allyTeam] = enemyTeam
  FlagAmount[allyTeam] = FlagAmount[allyTeam]-1
  spSetGameRulesParam("ctf_flags_team"..allyTeam, FlagAmount[allyTeam])
  spSetUnitAlwaysVisible(unitID, true)
  spSetGameRulesParam("ctf_unit_stole_team"..allyTeam, unitID)
  
--   Spring.Echo("error team "..enemyTeam.." steals "..allyTeam.." flag!")
--   Spring.Echo("error team "..enemyTeam.." flags: "..FlagAmount[enemyTeam])
--   Spring.Echo("error team "..allyTeam.." flags: "..FlagAmount[allyTeam])
end

function ScoreFlag(unitID, allyTeam, enemyTeam)
  FlagAmount[allyTeam] = FlagAmount[allyTeam]+1
  spSetGameRulesParam("ctf_flags_team"..allyTeam, FlagAmount[allyTeam])
  spSetUnitAlwaysVisible(unitID, false)
  spSetGameRulesParam("ctf_unit_stole_team"..FlagCarrier[unitID], 0)
  DefeatTimer[allyTeam] = TIMER_DEFEAT
  spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, DefeatTimer[allyTeam])
  LetThemCallBackup(FlagCarrier[unitID])
  
--   Spring.Echo("error team "..allyTeam.." scores "..FlagCarrier[unitID].." flag!")
--   Spring.Echo("error team "..allyTeam.." flags: "..FlagAmount[enemyTeam])
--   Spring.Echo("error team "..FlagCarrier[unitID].." flags: "..FlagAmount[FlagCarrier[unitID]])
  
  ContestedTeam[FlagCarrier[unitID]] = nil
  FlagCarrier[unitID] = nil
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  if (spValidUnitID(unitID)) then
    if (FlagCarrier[unitID]) then
      BlackList[unitID] = true -- lol, awesome bug when unit that dies picks flag back up and dies with it
      if (spGetUnitRulesParam(unitID, "wasMorphedTo") ~= nil) then
	TransferFlag(unitID, spGetUnitAllyTeam(unitID), spGetUnitRulesParam(unitID, "wasMorphedTo"), spGetUnitAllyTeam(unitID), FlagCarrier[unitID])
      else
	local x,y,z = spGetUnitPosition(unitID)
	if (InsideMap(x,z) == false) then
	  ReturnFlag(nil, nil, allyTeam) -- flag outside of map
	else
	  DropFlag(FlagCarrier[unitID], x, y, z)
	end
      end
      FlagCarrier[unitID] = nil
    end
    if (DroppedFlags[unitID]) then
      ReturnFlag(nil, nil, DroppedFlags[unitID].allyTeam) -- flag destroyed
      DroppedFlags[flagID] = nil
    end
    if UnitDefs[unitDefID].customParams.commtype and (spGetUnitRulesParam(unitID, "wasMorphedTo") == nil) then
      CommanderPool[teamID]=CommanderPool[teamID]+1
      spSetGameRulesParam("ctf_orbit_pool"..teamID, CommanderPool[teamID])
    end
    if (spValidUnitID(attackerID) and UnitDefs[unitDefID].customParams.commtype and not(spAreTeamsAllied(teamID,attackerTeamID)) and (spGetUnitRulesParam(unitID, "wasMorphedTo") == nil)) and -- this commander was in battle, allow him to respawn!
	(FlagAmount[select(6,spGetTeamInfo(teamID))] < FLAG_AMOUNT_INIT) then
      CommanderSpeedUpTimer[teamID] = true
    end
  end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
  if (BlackList[unitID]) then
    BlackList[unitID] = false -- FIXME probably not needed, in 91 at least
  end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
  if (BlackList[unitID]) then
    BlackList[unitID] = false -- FIXME probably not needed, in 91 at least
  end
end

function StealScoreFlags()
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
    unitID = GetAnyAlly(allyTeam, x, y, z, PICK_RADIUS)
    if ((unitID ~= nil) and (spValidUnitID(unitID))) then
      ReturnFlag(flagID, nil, allyTeam)
    end
  end
  -- any flags in bases?
  for i=1,#CommandCenters do
    local cc = CommandCenters[i]
    local allyTeam = cc.allyTeam
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
    unitID = GetAnyFlagCarrier(allyTeam, x, y, z, CAP_RADIUS)
    if (unitID ~= nil) and (spValidUnitID(unitID)) and (ContestedTeam[allyTeam] == nil) then
      ScoreFlag(unitID, allyTeam, spGetUnitAllyTeam(unitID))
    end
  end
end

function IsUnitAllied(unitID,allyTeam)
  return (spGetUnitAllyTeam(unitID) == allyTeam)
end

function GetAnyFlagCarrier(allyTeam, x, y, z, cap_radius)
  local units = spGetUnitsInCylinder(x, z, cap_radius)
  for i=1,#units do
    local unitID = units[i]
    local _, y2, _ = spGetUnitPosition(unitID)
    if IsUnitAllied(unitID, allyTeam) and (not(BlackList[unitID])) and (FlagCarrier[unitID] ~= nil) and (FlagCarrier[unitID] ~= allyTeam) and zDifference(y,y2) then
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
      if (udef.canMove) and (not(udef.canFly)) and (not(BlackList[unitID])) and (not(spGetUnitIsCloaked(unitID))) and zDifference(y,y2) then -- I so imagine rage when smbdy steals with rectors or such
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
      if (udef.canMove) and (not(udef.canFly)) and (not(BlackList[unitID])) and (not(spGetUnitIsCloaked(unitID))) and zDifference(y,y2) then -- I so imagine rage when smbdy steals with rectors or such
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
--   Spring.Echo("Contest destroyed")
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival1,TIMER_TELEPORT_FLAGS)
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival2,TIMER_TELEPORT_FLAGS)
  ContestData[index] = nil
end

function ContestTick(index)
--   Spring.Echo("Tick tack")
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival1,ContestData[index].timer)
  spSetGameRulesParam("ctf_contest_time_team"..ContestData[index].rival2,ContestData[index].timer)
  ContestData[index].timer = ContestData[index].timer-1
  return ContestData[index].timer
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
	for _,teamID in pairs(PlayersInTeam[allyTeam]) do
	  Spring.KillTeam(teamID)
	  Spring.SetTeamRulesParam(teamID, "WasKilled", 1)
	end
      end
      DefeatTimer[allyTeam] = DefeatTimer[allyTeam]-1
      spSetGameRulesParam("ctf_defeat_time_team"..allyTeam, DefeatTimer[allyTeam])
    end
  end
end

function CheckForDead()
  for allyTeam,flags in pairs(FlagAmount) do
    for _,teamID in pairs(PlayersInTeam[allyTeam]) do
      --local name, active, spectator = select(3,spGetPlayerInfo(select(2, spGetTeamInfo(teamID))))
      if  spGetTeamRulesParam(teamID, "WasKilled") then
	PlayerDied(teamID, allyTeam)
      end
    end
  end
end

function gadget:GameFrame (f)
  if not(GameStarted) then return end
  if ((f%ME_BONUS_DELAY)==0) then
    if (ME_CENTER_LVL < ME_CENTER_UP_MAX) then
      UpgradeCenters()
    end
  end
  if ((f%CTF_ONE_SECOND_FRAME)==0) then
    CheckForDead()
    Payday() -- give resources for having flags
    StealScoreFlags() -- any enemy unit near any of your command centers takes your flag and contest begins!
    -- any friendly unit carrying flag near your commander center scores!
    SolveContested() -- if teams hold each other flags in units
    CountDefeat() -- if you have 0 flags left and no contested flags either, you are doomed
    OrbitTimer()
    DeliverDrops(f)
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
  GameStarted = true
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