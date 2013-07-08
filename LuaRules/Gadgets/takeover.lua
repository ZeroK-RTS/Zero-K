local version = "0.0.2 beta" -- i'm so noob in this :p

function gadget:GetInfo()
  return {
    name      = "Takeover",
    desc      = "KoTH remake, instead of instantly winning game for controlling center of the map, capture a unit that will help you crush all enemies... "..version,
    author    = "Tom Fyuri, xponen",
    date      = "Jul 2013",
    license   = "GPL v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--[[ The Takeover draft >
...inspired by detriment hideout and wolas...
1. This is zkmode gamemode.
2. Spawned unit is selected before hand via modoptions. Choices are:
Zeus
Reaper
Goliath
Sumo
Licho
Krow
Penetrator
Crabe
Tactical Silo
Annihilator
Doom's day machine
Fusion
Singularity
Zenith
Rainbow arty
Starlight
Dante
Bantha
Detriment <- default
Reef
Warlord
Tactical sub?
List is subject to change.
Naturally, if center of map is water, and unit is land only, unit will fallback to "detriment", same if players select water unit when center of map is land.
If center of map and unit type are correct, unit will be spawn there.
3. Unit will get EMPed for amount of time correspoding to graceperiod modoption.
  Graceperiod, corresponds to amount of time unit is paralysed for. Default is 90 seconds.
4. Unit may get transfered instantly to team that EMPed unit last or not, if not, use dominatrix to get the unit (may be long if unit is expensive).
  Naturally, if all teams fail to capture unit, it will belong to "noone". So next options:
  a) Any last team to EMP gets unit on graceperiod over. <- default
  b) "Noone" does, but players may take it over with dominatrix.
  c) Unit belongs to players (only if units spawn in player boxes, the center unit is still "noone"'s).
5. Option to make unit spawn:
  a) Center of map. <- default
  b) Player boxes.
  c) Center of map + player boxes.
6) Any transport trying to pick up unit will get EMPed for the same amount of time unit is paralysed for. Until graceperiod is over.

Players may decide to destroy unit instead of capturing it, and it's allright.
The point is: if unit/structure is valuable, control the hill(center) until graceperiod is over, and pwn the other teams.
This is skill based (teamwork) gamemode for fast games.

  Changelog:
0.0.1 beta - First version, not working in multiplayer, working singleplayer.
0.0.2 beta - Recoded voting implementation, getting closer to smooth beta playing...
]]--

-- TODO this is copy paste from halloween, it's only used to simulate unit berserk state, but it needs to be replaced with more sane AI that will try to attack players, but not finish them off!
-- Seed unsynced random number generator.
-- Credits https://github.com/tvo/craig/blob/master/LuaRules/Gadgets/craig/main.lua
if (math.randomseed ~= nil) then
  --local r = Spring.DiffTimers(Spring.GetTimer(), Script.CreateScream())	-- FIXME crashes with "invalid args" error
  math.random()
  --math.randomseed(r)
end

local string_vote_for = 'takeover_vote';
local spSendLuaRulesMsg	    = Spring.SendLuaRulesMsg
local spSendLuaUIMsg	    = Spring.SendLuaUIMsg

--SYNCED-------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
  
local unit_choice = {
      ['scorpion'] = {
	id = 1;
	name = "scorpion";
	type = "scorpion";
	full_name = "Scorpion";
	pic = "unitpics/scorpion.png";
	water_friendly = false;
	votes = 0;
      },
      ['dante'] = {
	id = 2;
	name = "dante";
	type = "dante";
	full_name = "Dante";
	pic = "unitpics/dante.png";
	water_friendly = false;
	votes = 0;
      },
      ['catapult'] = {
	id = 3;
	name = "catapult";
	type = "armraven";
	full_name = "Catapult";
	pic = "unitpics/armraven.png";
	water_friendly = false;
	votes = 0;
      },
      ['bantha'] = {
	id = 4;
	name = "bantha";
	type = "armbanth";
	full_name = "Bantha";
	pic = "unitpics/armbanth.png";
	water_friendly = false;
	votes = 0;
      },
      ['krow'] = {
	id = 5;
	name = "krow";
	type = "corcrw";
	full_name = "Krow";
	pic = "unitpics/corcrw.png";
	water_friendly = false;
	votes = 0;
      },
      ['detriment'] = {
	id = 6;
	name = "detriment";
	type = "armorco";
	full_name = "Detriment";
	pic = "unitpics/armorco.png";
	water_friendly = true;
	votes = 0;
      },
      ['jugglenaut'] = {
	id = 7;
	name = "jugglenaut";
	type = "gorg";
	full_name = "Jugglenaut";
	pic = "unitpics/gorg.png";
	water_friendly = false;
	votes = 0;
      },
}

local delay_options = {
      {
	id = 1;
	delay = 0;
	votes = 0;
      },
      {
	id = 2;
	delay = 5;
	votes = 0;
      },
      {
	id = 3;
	delay = 10;
	votes = 0;
      },
      {
	id = 4;
	delay = 30;
	votes = 0;
      },
      {
	id = 5;
	delay = 45;
	votes = 0;
      },
      {
	id = 6;
	delay = 60;
	votes = 0;
      },
      {
	id = 7;
	delay = 90;
	votes = 0;
      },
      {
	id = 8;
	delay = 120;
	votes = 0;
      },
      {
	id = 9;
	delay = 150;
	votes = 0;
      },
      {
	id = 10;
	delay = 240;
	votes = 0;
      },
      {
	id = 11;
	delay = 300;
	votes = 0;
      },
      {
	id = 12;
	delay = 450;
	votes = 0;
      },
      {
	id = 13;
	delay = 600;
	votes = 0;
      },
      {
	id = 14;
	delay = 900;
	votes = 0;
      },
      {
	id = 15;
	delay = 1200;
	votes = 0;
      },
      {
	id = 16;
	delay = 1500;
	votes = 0;
      },
      {
	id = 17;
	delay = 1800;
	votes = 0;
      },
      {
	id = 18;
	delay = 3600;
	votes = 0;
      },
      {
	id = 19;
	delay = 7200;
	votes = 0;
      },
      {
	id = 20;
	delay = 9000;
	votes = 0;
      },
}

local string_vote_start = "takeover_vote_start";
local string_vote_end = "takeover_vote_end";
local string_vote_most_popular = "takeover_vote_most_popular";
local string_vote_fallback = "takeover_vote_fallback";
local string_takeover_owner = "takeover_new_owner";
local string_takeover_unit_died = "takeover_unit_dead"
local PollActive = false

local springieName = Spring.GetModOptions().springiename or ''

local VOTE_DEFAULT_CHOICE1 = "detriment";
local VOTE_DEFAULT_CHOICE2 = 900;
local most_voted_option = {};
most_voted_option[0] = VOTE_DEFAULT_CHOICE1;
most_voted_option[1] = VOTE_DEFAULT_CHOICE2;

--local players = {}; -- unsorted
local player_list = {}; -- players who voted

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
--local sin    = math.sin
local random = math.random
local floor  = math.floor
local GaiaTeamID 	    = Spring.GetGaiaTeamID()
local spGetAllUnits         = Spring.GetAllUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitTeam	    = Spring.GetUnitTeam
local spGetTeamUnits 	    = Spring.GetTeamUnits
local spGetUnitHealth	    = Spring.GetUnitHealth
local spTransferUnit        = Spring.TransferUnit
local spGetUnitIsDead	    = Spring.GetUnitIsDead
local spGiveOrderToUnit	    = Spring.GiveOrderToUnit
local spSetTeamResources    = Spring.SetTeamResources
local spGetTeamResources    = Spring.GetTeamResources
local spGetUnitRulesParam   = Spring.GetUnitRulesParam
local spCreateUnit	    = Spring.CreateUnit
local spGetUnitDefID	    = Spring.GetUnitDefID
local spGetGroundHeight     = Spring.GetGroundHeight
local spSetUnitHealth	    = Spring.SetUnitHealth
local SetUnitNoSelect       = Spring.SetUnitNoSelect
local spGetGameFrame	    = Spring.GetGameFrame
--local spGetUnitTransporter  = Spring.GetUnitTransporter
--local spGetUnitBasePosition = Spring.GetUnitBasePosition
local spEcho                = Spring.Echo

local spGetPlayerList	    = Spring.GetPlayerList
local spGetTeamList	    = Spring.GetTeamList
local spGetTeamInfo	    = Spring.GetTeamInfo
local spGetPlayerInfo	    = Spring.GetPlayerInfo

local CMD_RECLAIM	= CMD.RECLAIM
local CMD_LOAD_UNITS	= CMD.LOAD_UNITS

local TheUnit
local TheUnitIsChained	= true
local DelayInFrames
local TimeLeftInSeconds

local function DelayIntoID(delay)
	for _,a in ipairs(delay_options) do
	  if (a.delay == delay) then
	    return a.id
	  end
	end
end
local function UpdateVote()
	-- recalculate most popular option, quite easy, build a table of most wanted option
	local most_unit_votes = 0
	for _,unit in pairs(unit_choice) do
	  if (unit.votes > most_unit_votes) then most_unit_votes = unit.votes end
	end
	local most_units = {}
	for _,unit in pairs(unit_choice) do
	   if (unit.votes == most_unit_votes) then
	      most_units[#most_units+1] = unit.name;
-- 	      spEcho(most_units[#most_units].." "..most_unit_votes)
	   end
	end
	
	local most_delay_votes = 0
	for _,de in ipairs(delay_options) do
	  if (de.votes > most_delay_votes) then most_delay_votes = de.votes end
	end
	local most_delays = {}
	for _,de in ipairs(delay_options) do
	   if (de.votes == most_delay_votes) then
	      most_delays[#most_delays+1] = de.delay
	   end
	end
	
	if (most_unit_votes > 0) then
	  most_voted_option[0] = most_units[random(1,#most_units)]
	else
	  most_voted_option[0] = VOTE_DEFAULT_CHOICE1
	end
	if (most_delay_votes > 0) then
	  most_voted_option[1] = most_delays[random(1,#most_delays)]
	else
	  most_voted_option[1] = VOTE_DEFAULT_CHOICE2
	end
	spSendLuaUIMsg(string_vote_most_popular.." "..most_voted_option[0].." "..most_unit_votes.." "..most_voted_option[1].." "..most_delay_votes) -- genius lol
	--spEcho(most_voted_option[0].." "..most_voted_option[1])
end

local function GetVotes(playerID, name, line)
	--spEcho("YOU VOTED: "..line)
	if line==string_vote_for then return false end
	words={}
	for word in line:gmatch("[^%s]+") do words[#words+1]=word end
	if (#words ~= 3) then return false end
 	--spEcho("[debug] Takeover: "..name.." voted for "..words[2].." "..words[3])
	-- find player by name... oh my
	local new = true
	local id = -1
	for i=1,#player_list do
	  if (player_list[i].playerID == playerID) then
	    new = false;
	    id = i;
	    break;
	  end
	end
	if new then
	  player_list[#player_list+1] = {
	    name = name;
	    playerID = playerID;
	    voted = false; choice = {};
	  };
	  player_list[#player_list].choice[0] = VOTE_DEFAULT_CHOICE1;
	  player_list[#player_list].choice[1] = VOTE_DEFAULT_CHOICE2;
	  id = #player_list;
	end
	--for i=1,#player_list do
-- 	if (player_list[id].name == name) then
	if (id > -1) then -- safety check
	  if (unit_choice[words[2]] ~= nil) then
	      if (player_list[id].voted) then
		  unit_choice[player_list[id].choice[0]].votes = unit_choice[player_list[id].choice[0]].votes-1
	      end
	      unit_choice[words[2]].votes = unit_choice[words[2]].votes+1
	      player_list[id].choice[0] = words[2]
-- 		spEcho(words[2].." "..unit_choice[words[2]].votes)
	  end
	  local delay = tonumber(words[3])
	  if (delay ~= nil) then
	      if (player_list[id].voted) then
		  delay_options[DelayIntoID(player_list[id].choice[1])].votes = delay_options[DelayIntoID(player_list[id].choice[1])].votes-1
	      end
	      delay_options[DelayIntoID(delay)].votes = delay_options[DelayIntoID(delay)].votes+1
	      player_list[id].choice[1] = delay
	  end
	  -- TODO detection if invalid choice is done above, but instead of putting default values, need to tell abuser to vote again
	  if not player_list[id].voted then
	    player_list[id].voted = true
	  end
	  --end -- if player name isn't on sorted list, it's spectator or someone else? ignore anyway
	end
	UpdateVote()
end

function gadget:Initialize()
    if(modOptions.zkmode ~= "takeover") then
	gadgetHandler:RemoveGadget()
    end
--    gadgetHandler:AddChatAction(string_vote_for, ParseVote, " : sends vote's preferences to players and gadget...")
    PollActive = true
--    spEcho(string_vote_start)
    spSendLuaUIMsg(string_vote_start)
end

local function Paralyze(unitID, frameCount) -- credits and fame to xponen
    local health, maxHealth, paralyzeDamage = spGetUnitHealth(unitID)
    local second = math.abs(frameCount*(1/30)) --because each frame took 1/30 second
    second = second-1-1/16 --because at 0% it took 1 second to recover, and paralyze is in slow update (1/16)
    --Note: ZK use
    --paralyzeAtMaxHealth=true, and
    --unitParalysisDeclineScale=40
    local paralyze = maxHealth+maxHealth*second/40 --a full health of paralyzepoints represent 1 second of paralyze, additional health/40 paralyzepoints represent +1 second of paralyze. Reference: modrules.lua, Unit.cpp(spring).
    spSetUnitHealth(unitID, { paralyze = paralyze })
end

function gadget:GameStart()
    DelayInFrames = 30*most_voted_option[1];
    PollActive = false
    -- TODO write awesome code to detect if it's land/water/etc, terraform place, be able to put structures and so on
    local x,z
    local xmin,xmax
    local zmin,zmax
    xmin = floor(Game.mapSizeX/2 - 80)
    zmin = floor(Game.mapSizeZ/2 - 80)
    xmax = floor(Game.mapSizeX/2 + 80)
    zmax = floor(Game.mapSizeZ/2 + 80)
    for i=1,random(1,10) do -- adding slightly more random spawn position
      x = random(xmin,xmax)
      z = random(zmin,zmax)
    end
    if (spGetGroundHeight(x,z) <= waterLevel) and not (unit_choice[most_voted_option[0]].water_friendly) then
      most_voted_option[0] = "detriment"; -- TODO basically i don't want land type units in water
      --spEcho(takeover_error_fallback)
      spSendLuaUIMsg(string_vote_fallback)
    end
    TheUnit = spCreateUnit(unit_choice[most_voted_option[0]].type,x,spGetGroundHeight(x,z)+200,z,"n",GaiaTeamID)
    if (TheUnit ~= nil) then
      SetUnitNoSelect(TheUnit,true)
      TheUnitIsChained = true
      Paralyze(TheUnit, most_voted_option[1]*30) -- +16 seconds haha
    end
    spSendLuaUIMsg(string_vote_end.." "..most_voted_option[0].." "..most_voted_option[1]) -- this will force all vote windows to close if they aren't yet
    -- TODO also rewrite string above into luamsg
    -- TODO make it so timer in widgets and in gadgets are showing same number (or +- 1-2 seconds) somehow...
    TimeLeftInSeconds = most_voted_option[1]
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeam)
    if (TheUnit ~= nil) and (TheUnit == unitID) and (paralyzer) and (TheUnitIsChained) then
	spSendLuaUIMsg(string_takeover_owner.." "..attackerTeam)
	spTransferUnit(TheUnit, attackerTeam, false)
    end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
  if (unitID == TheUnit) then
    spSendLuaUIMsg(string_takeover_unit_died)
    TheUnit = nil
    gadgetHandler:RemoveGadget() -- my job here is done, no need to keep it working
  end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
  if (TheUnit ~= nil) and (unitID == TheUnit) and (TheUnitIsChained) and (TimeLeftInSeconds>0) then
      Paralyze(transportID,TimeLeftInSeconds*30)
  end
end

-- idk what are these used for and how, my guess it's a filter so only "true" listen commands are processed by allowcommand &/or commandfallback
function gadget:AllowCommand_GetWantedCommand()
        return {[CMD.RECLAIM] = true, [CMD.LOAD_UNITS] = true}
end

function gadget:AllowCommand_GetWantedUnitDefID()
        return true
end

-- TODO FIXME i need some help figuring out how to block area load units command (exclude TheUnit from picking up) help wanted!
function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions) --, fromSynced)
  -- you shall not use the dormant unit
  if (TheUnit ~= nil) then
    if (unitID == TheUnit) and (TheUnitIsChained) then --and (cmdID == CMD.SELFD) then
      return false
    end
    if ((cmdID == CMD_RECLAIM) or (cmdID == CMD_LOAD_UNITS)) and (#cmdParams == 1) and (cmdParams[1] == TheUnit) then -- you shall not reclaim me or touch me      
      return false
    end
  end
  return true
end

function gadget:GameFrame (f)
    if (f >= DelayInFrames) then
	TheUnitIsChained = false;
	if (TheUnit ~= nil) then
	    SetUnitNoSelect(TheUnit,false)
	    if (spGetUnitTeam(TheUnit) == GaiaTeamID) then
		  spGiveOrderToUnit(TheUnit,CMD.REPEAT,{1},{})
		  spGiveOrderToUnit(TheUnit,CMD.MOVE_STATE,{2},{})
		  local xmin,xmax
		  local zmin,zmax
		  xmin = floor(Game.mapSizeX/2 - Game.mapSizeX/6)
		  zmin = floor(Game.mapSizeZ/2 - Game.mapSizeZ/6)
		  xmax = floor(Game.mapSizeX/2 + Game.mapSizeX/6)
		  zmax = floor(Game.mapSizeZ/2 + Game.mapSizeZ/6)
		  for i=1,random(1,10) do
		    x = random(xmin,xmax)
		    z = random(zmin,zmax)
		    spGiveOrderToUnit(TheUnit,CMD.INSERT,{-1,CMD.FIGHT,CMD.OPT_SHIFT,x,0,z},{"alt"});
		  end
	    end
	end
	gadgetHandler:RemoveGadget() -- my job here is done, no need to keep it working
    end
    if ((f%30)==0) and (TimeLeftInSeconds > 0) then
      TimeLeftInSeconds = TimeLeftInSeconds - 1 
    end
end

-- local function ParseVote(cmd, line, words, playerID)
--     if (#words == 2) then
-- 	local myName = Spring.GetPlayerInfo(playerID)
-- 	local str = myName.." takeover_vote "..words[1].." "..words[2]
-- 	if str:find(string_vote_for) then
-- 		GetVotes(str)
-- 	end
--     end
-- end

function gadget:RecvLuaMsg(line, playerID)
    --spEcho(playerID)
    if line:find(string_vote_for) and PollActive then
	local name, _, spectator = spGetPlayerInfo(playerID)
	--spEcho(name.." "..tostring(spectator))
	if not spectator then
	  GetVotes(playerID, name, line)
	end
    end
end

else
  
local function ParseVoteB(cmd, line, words, playerID)
    if (#words == 2) then
	local str = string_vote_for.." "..words[1].." "..words[2]
	spSendLuaRulesMsg(str)
    end
end
  
function gadget:Initialize()
    gadgetHandler:AddChatAction(string_vote_for, ParseVoteB, " : sends vote's preferences to players and gadget...")
end

end