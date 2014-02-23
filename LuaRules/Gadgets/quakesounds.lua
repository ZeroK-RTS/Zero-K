function gadget:GetInfo()
  return {
    name	= "Death Announcer",
    desc	= "Announces death sounds for units. Quake Sounds widget uses this. v1.0.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -1,
    enabled 	= true,
  }
end

------------------------------INTERNAL CONFIG--------------------------------------------------------------------------------
-- metalwasted can override kills, and kills can override metalwasted limits.
-- if female is false, male voice will be played regardless, if user prefers female.
local sfx_headshot = {
  { kills = 1, damage = 1000, sfx_male = "headshot.wav", msg = "Headshot", sfx_female = "headshot.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 2, damage = 1000, sfx_male = "headshot.wav", msg = "Headshot", sfx_female = "headshot.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 3, damage = 1500, sfx_male = "hattrick.wav", msg = "Hattrick", sfx_female = "headshot.wav", sfx_female_exist = false, sfx_force_male = false, },
  { kills = 5, damage = 2500, sfx_male = "headhunter.wav", msg = "Headhunter", sfx_female = "headshot.wav", sfx_female_exist = false,  sfx_force_male = false, },
}
local sfx_combo = {
  { kills = 2, sfx_male = "doublekill.wav", msg = "Doublekill", sfx_female = "multikill.wav", sfx_female_exist = false, sfx_force_male = false, },
  { kills = 3, sfx_male = "triplekill.wav", msg = "Triplekill", sfx_female = "multikill.wav", sfx_female_exist = false, sfx_force_male = false, },
  { kills = 4, sfx_male = "multikill.wav", msg = "Multikill", sfx_female = "multikill.wav", sfx_female_exist = true, sfx_force_male = false, },
--{ kills = 5, wasted = -1, sfx_male = "combowhore.wav", msg = "Combowhore", sfx_female = "multikill.wav", sfx_female_exist = false, sfx_force_male = false, }, -- personally i don't like this one, so removed
-- maybe put megakill here? and shit all killsounds up one frag requirement?
}
-- this one retains on killers, should you know that unitID killed some units, after sound is played, his kill count is memorized, so if that unit
-- continues to murder more units, the deathtoll is raised rather than restarted every time
local sfx_killsound = {
  { kills = 5, wasted = 600, sfx_male = "dominating.wav", msg = "Dominating", sfx_female = "dominating.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 7, wasted = 1000, sfx_male = "rampage.wav", msg = "Rampage", sfx_female = "rampage.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 10, wasted = 1600, sfx_male = "killingspree.wav", msg = "Killingspree", sfx_female = "killingspree.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 14, wasted = 2400, sfx_male = "monsterkill.wav", msg = "Monsterkill", sfx_female = "monsterkill.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 19, wasted = 3400, sfx_male = "unstoppable.wav", msg = "Unstoppable", sfx_female = "unstoppable.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 26, wasted = 4800, sfx_male = "ultrakill.wav", msg = "Ultrakill", sfx_female = "ultrakill.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 34, wasted = 6400, sfx_male = "godlike.wav", msg = "Godlike", sfx_female = "godlike.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 42, wasted = 8000, sfx_male = "wickedsick.wav", msg = "Wickedsick", sfx_female = "wickedsick.wav", sfx_female_exist = true, sfx_force_male = false, },
  { kills = 51, wasted = 9800, sfx_male = "impressive.wav", msg = "Impressive", sfx_female = "wickedsick.wav", sfx_female_exist = false, sfx_force_male = false, },
  { kills = 61, wasted = 11800, sfx_male = "ludicrouskill.wav", msg = "Ludicrouskill", sfx_female = "holyshit.wav", sfx_female_exist = false, sfx_force_male = false, },
  { kills = 72, wasted = 14000, sfx_male = "holyshit.wav", msg = "Holyshit", sfx_female = "holyshit.wav", sfx_female_exist = true, sfx_force_male = false, },
}
-- when you see first kill, be it by you or by enemy...
local sfx_first_blood = {
  { sfx_male = "firstblood.wav", msg = "Firstblood", sfx_female = "firstblood.wav", sfx_female_exist = true, sfx_force_male = false, },
}
-- you demn team killers
local sfx_teamkill = {
  { sfx_male = "teamkiller.wav", msg = "Teamkiller", sfx_female = "teamkiller.wav", sfx_female_exist = false, sfx_force_male = true, },
}
-- this should be triggered when unit died by explosion
local sfx_bombed = {
  { sfx_male = "perfect.wav", msg = "Perfect", sfx_female = "perfect.wav", sfx_female_exist = false, sfx_force_male = true, },
}
local perfectUnitsDef = {
 [ UnitDefNames['armcybr'].id ] = true,
 [ UnitDefNames['blastwing'].id ] = true,
 [ UnitDefNames['corhurc2'].id ] = true,
 [ UnitDefNames['corroach'].id ] = true,
 [ UnitDefNames['corshad'].id ] = true,
 [ UnitDefNames['corsktl'].id ] = true,
 [ UnitDefNames['logkoda'].id ] = true,
 [ UnitDefNames['puppy'].id ] = true,
 [ UnitDefNames['wolverine_mine'].id ] = true,
 [ UnitDefNames['screamer'].id ] = true,
}
local sfx_selfd = {
  { sfx_male = "humiliation.wav", msg = "Humiliation", sfx_female = "humiliation.wav", sfx_female_exist = true, sfx_force_male = false, },
}
local sfx_melee = {
  { sfx_male = "humiliation.wav", msg = "Humiliation", sfx_female = "bottomfeeder.wav", sfx_female_exist = true, sfx_force_male = false, },
}
-----------------------------------------------------------------------------------------------------------------------------
local modOptions = Spring.GetModOptions()
if (gadgetHandler:IsSyncedCode()) then
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spGetGameFrame	 	= Spring.GetGameFrame
local spPlaySoundFile 		= Spring.PlaySoundFile
local spGetSelectedUnits 	= Spring.GetSelectedUnits
local spGetMyTeamID      	= Spring.GetMyTeamID
local spGetGroundHeight     	= Spring.GetGroundHeight
local spGetPlayerInfo	 	= Spring.GetPlayerInfo

local GaiaTeamID	   	= Spring.GetGaiaTeamID()
local DeathDistance		= 500 -- should be changeable by user via options
local DeathDistanceSQ		= DeathDistance*DeathDistance

local AssistDamage		= {} -- is needed to detect ridiculous damage done to single unit
local AttackedBy		= {} -- is needed to give frags
local UnitFrags			= {}
local DeathMarkers		= {}
local DeathExpire		= 30 -- frames after which DeathMarker is destroyed
local UnitSuicide		= {}
local LastFrag			= {} -- fragcount will drain if unit didn't kill for a while

local CMD_SELFD			= CMD.SELFD

-- local PlaySound			= function(a) spPlaySoundFile(sound_path(a)) end
local ZeroDeath			= true

function gadget:Initialize()
  if (tonumber(modOptions.quakesounds) ~= 1) then
    gadgetHandler:RemoveGadget()
  end
end
-- concept
-- when unit dies it leaves an invisible marker and a deathcount and metalwasted count attached to it
-- any unit that dies near such marker adds to values and shits marker position slightly closer to himself
-- this way units that die in same place add to counter pretty well
-- after 1 second if no additional units die, marker is destroyed and label (and sound if YOU have it) will announce
-- how well the stuff was destroyed, lel
function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  local most_frags = 0
  local most_dmg = 0
  if (attackerID ~= nil) and (UnitFrags[attackerID] == nil) then
    UnitFrags[attackerID] = 0
    LastFrag[attackerID] = spGetGameFrame()
  end
  if (AttackedBy[unitID]) and (AttackedBy[unitID][attackerID]) and not(UnitSuicide[unitID]) then -- suicide shouldn't increase frags though
    for assistantID, _ in pairs(AttackedBy[unitID]) do
      if (UnitFrags[assistantID] ~= nil) then
	if (assistantID ~= attackerID) then
	  UnitFrags[assistantID] = UnitFrags[assistantID] + 1
	  LastFrag[assistantID] = spGetGameFrame()
	  --Spring.Echo("unitid "..assistantID.." has "..UnitFrags[assistantID].." frags (assist)")
	end
	if (UnitFrags[assistantID] > most_frags) then
	  most_frags = UnitFrags[assistantID]
	end
      end
      if (AssistDamage[assistantID] ~= nil) and (AssistDamage[assistantID][unitID]) and (AssistDamage[assistantID][unitID] > most_dmg) then
	most_dmg = AssistDamage[assistantID][unitID]
      end
    end
  end
  if (attackerID ~= nil) and (UnitFrags[attackerID] ~= nil) then
    UnitFrags[attackerID] = UnitFrags[attackerID] + 1
    LastFrag[attackerID] = spGetGameFrame()
    --Spring.Echo("unitid "..attackerID.." has "..UnitFrags[attackerID].." frags")
  end
  if (unitDefID ~= nil ) then
    local ud = UnitDefs[unitDefID]
    if (not ud.customParams.dontcount) and (not spGetUnitRulesParam(unitID, 'wasMorphedTo')) then
      local x,y,z = spGetUnitPosition(unitID)
      if (GaiaTeamID ~= attackerID) and (attackerTeamID ~= nil) and not(select(6,spGetTeamInfo(teamID)) == select(6,spGetTeamInfo(attackerTeamID))) then
	local markerID = GetNearestMarker(x,z) -- Z level is ignored
	if (markerID ~= nil) then
	  DeathMarkers[markerID].kills = DeathMarkers[markerID].kills + 1
	  DeathMarkers[markerID].wasted = DeathMarkers[markerID].wasted + ud.metalCost
	  DeathMarkers[markerID].x = (DeathMarkers[markerID].x+x)/2
	  DeathMarkers[markerID].z = (DeathMarkers[markerID].z+z)/2
	  DeathMarkers[markerID].y = spGetGroundHeight(DeathMarkers[markerID].x,DeathMarkers[markerID].z)
	  DeathMarkers[markerID].time = spGetGameFrame()
	  if (DeathMarkers[markerID].frags < most_frags) then
	    DeathMarkers[markerID].frags = most_frags
	  end
	  if (DeathMarkers[markerID].damage < most_dmg) then
	    DeathMarkers[markerID].damage = most_dmg
	  end
	else
	  DeathMarkers[unitID] = {
	    kills = 1,
	    wasted = 0+ud.metalCost,
	    x = x,
	    y = y,
	    z = z,
	    time = spGetGameFrame(),
	    frags = most_frags,
	    damage = most_dmg,
	  }
	end
      elseif (UnitSuicide[unitID]) or ((attackerID ~= nil) and (attackerID == unitID)) then
	SendToUnsynced("quakesounds_humiliation", x, y, z)
      elseif (attackerTeamID ~= nil) and (select(6,spGetTeamInfo(teamID)) == select(6,spGetTeamInfo(attackerTeamID))) then
	SendToUnsynced("quakesounds_teamkiller", x, y, z)
      elseif (attackerDefID ~= nil) and (UnitDefs[attackerDefID].unitname == "corcan") then
	SendToUnsynced("quakesounds_bottomfeeder", x, y, z)
      elseif (attackerDefID ~= nil) and (perfectUnitsDef[attackerDefID]) then
	SendToUnsynced("quakesounds_perfect", x, y, z)
      end
      -- TODO this one plays regardless... if it's FB
      if (ZeroDeath==true) then
	SendToUnsynced("quakesounds_firstblood", x, y, z)
	ZeroDeath = false
      end
    end
  end
  UnitSuicide[unitID] = nil
  AssistDamage[unitID] = nil
  UnitFrags[unitID] = nil
  AttackedBy[unitID] = nil
  LastFrag[unitID] = nil
end

-- probably no need for predamaged
function gadget:UnitPreDamaged(unitID, unitDefID, teamID, damage, paralyzer, weaponID, attackerID, attackerDefID, attackerTeamID)
  if (unitDefID ~= nil) then
    local ud = UnitDefs[unitDefID]
    if (not ud.customParams.dontcount) and (not spGetUnitRulesParam(unitID, 'wasMorphedTo')) then
      if (GaiaTeamID ~= attackerID) and (attackerTeamID ~= nil) and not(select(6,spGetTeamInfo(teamID)) == select(6,spGetTeamInfo(attackerTeamID))) then
	if (AssistDamage[attackerID] == nil) then
	  AssistDamage[attackerID] = {}
	end
	if (AssistDamage[attackerID][unitID] == nil) then
	  AssistDamage[attackerID][unitID] = 0
	end
	AssistDamage[attackerID][unitID] = AssistDamage[attackerID][unitID] + damage -- should I add paralyzer damage here too?
	if (AttackedBy[unitID] == nil) then
	  AttackedBy[unitID] = {}
	end
	if (AttackedBy[unitID][attackerID] == nil) then
	  AttackedBy[unitID][attackerID] = true -- marking who attacked unit, these units if validID get kills increased
	end
      end
    end
  end
end

function gadget:CommandNotify(commandID, params ,options)
  local unitID = spGetSelectedUnits()[1]
  if (not unitID) then
    return false
  end
  if (commandID == CMD_SELFD) then
    local selectedUnits = spGetSelectedUnits()
    for _, unitID in ipairs(selectedUnits) do
      if (UnitSuicide[unitID]) then
	UnitSuicide[unitID] = nil
      else
	UnitSuicide[unitID] = true
      end
    end
  end
end

function AnnounceCasualties(kills,frags,damage,wasted,x,y,z)
  -- priority:
  -- 1 killsound
  local good_index = nil
  for index,data in ipairs(sfx_killsound) do
    if (data.kills <= frags) or (data.wasted <= wasted) then
      good_index = index
    end
  end
  if (good_index ~= nil) then
    --Spring.Echo("multikill "..sfx_killsound[good_index].kills.." "..sfx_killsound[good_index].wasted)
    SendToUnsynced("quakesounds_multikill", good_index, x, y, z)
    return
  end
  -- 2 combo
  for index,data in ipairs(sfx_combo) do
    if (data.kills <= kills) then
      good_index = index
--       SendToUnsynced("quakesounds_combo", index, x, y, z)
--       PlaySound(data)
--       return
    end
  end
  if (good_index ~= nil) then
    --Spring.Echo("combo "..sfx_combo[good_index].kills)
    SendToUnsynced("quakesounds_combo", good_index, x, y, z)
    return
  end
  -- 3 headshot
  for index,data in ipairs(sfx_headshot) do
    if (data.kills <= frags) or (data.damage <= damage) then
      good_index = index
    end
  end
  if (good_index ~= nil) then
    --Spring.Echo("headshot "..sfx_headshot[good_index].kills.." "..sfx_headshot[good_index].damage)
    SendToUnsynced("quakesounds_headshot", good_index, x, y, z)
    return
  end
  -- so it's not bloodbath?
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
    if (n-30) >= data.time then
      local x = data.x
      local y = data.y
      local z = data.z
      local kills = data.kills
      local wasted = data.wasted
      local frags = data.frags
      local damage = data.damage
      AnnounceCasualties(kills,frags,damage,wasted,x,y,z)
      DeathMarkers[markerID] = nil
    end
  end
  -- every 2 seconds all units that didn't kill for a 30 sec lose one frag...
  -- if it has more than 75 frags, 2 are lost
  -- this is so units may gain dominating and again and again, but glaive will never become ultrakiller
  if (n%60)==1 then
    for index,_ in pairs(UnitFrags) do
      if (UnitFrags[index] > 0) and ((LastFrag[index]+900) < n) then
	UnitFrags[index]=UnitFrags[index]-1
	if (UnitFrags[index] > 75) then
	  UnitFrags[index]=UnitFrags[index]-1
	end
      end
    end
  end
end

function ParseParams(line)
  params={}
  for word in line:gmatch("[^%s]+") do
    params[#params+1]=tonumber(word)
  end
  return params
end

function gadget:RecvLuaMsg(line, playerID)
  if line:find("quakesounds_mode") then
    local params = ParseParams(line)
    if (params ~= nil) and (#params == 1) then
      SendToUnsynced("quakesounds_mode", playerID, params[1])
    end
  elseif line:find("quakesounds_volume") then
    local params = ParseParams(line)
    if (params ~= nil) and (#params == 1) then
      SendToUnsynced("quakesounds_volume", playerID, params[1])
    end
  end
end

-----------------------------------------------------------------------------------------------------------------------------
else
local spGetLocalAllyTeamID = Spring.GetLocalAllyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spIsPosInLos         = Spring.IsPosInLos
local spPlaySoundFile      = Spring.PlaySoundFile
local spGetMyPlayerID	   = Spring.GetMyPlayerID
local spGetGameFrame	   = Spring.GetGameFrame

local last_sfx_played = -100
local sound_mode = {}
local sound_volume = {}
-- -1 means ignore quakestuff, if user dl's sounds in his option menu he can change it to 0,1,2
-- 0 only male sfx
-- 1 female and male sfx
-- only female sfx
-- Dominating!
local function sound_path(sound_mode, sfx)
  local sfx_female_exist = sfx.sfx_female_exist
  local sfx_force_male = sfx.sfx_force_male
  if (sound_mode == 2) then
    return "sounds/quake/standard/"..sfx.sfx_male
  elseif (sound_mode == 1) then
    if (sfx_force_male==true) then
      return "sounds/quake/standard/"..sfx.sfx_male
    elseif (sfx_female_exist==true) then
      return "sounds/quake/female/"..sfx.sfx_female
    else
      return "sounds/quake/standard/"..sfx.sfx_male
    end
  else -- only female
    if (sfx_force_male==true) then
      return "sounds/quake/standard/"..sfx.sfx_male
    elseif (sfx_female_exist==true) then
      return "sounds/quake/female/"..sfx.sfx_female
    else
      return "sounds/quake/female/"..sfx.sfx_female
    end
  end
end

function Firstblood(_, x, y, z)
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  if (last_sfx_played <= spGetGameFrame()-30) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_first_blood[1]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Multikill(_, index, x, y, z) -- ignores sfx played antispam, that's intentional
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_killsound[index]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Combo(_, index, x, y, z) -- ignores sfx played antispam, that's intentional
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_combo[index]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Headshot(_, index, x, y, z) -- ignores sfx played antispam, that's intentional
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_headshot[index]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Humiliation(_, x, y, z)
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  if (last_sfx_played <= spGetGameFrame()-30) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_melee[1]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Teamkiller(_, x, y, z)
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  if (last_sfx_played <= spGetGameFrame()-30) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_teamkill[1]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Bottomfeeder(_, x, y, z)
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  if (last_sfx_played <= spGetGameFrame()-30) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_selfd[1]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function Perfect(_, x, y, z)
  local pref = sound_mode[spGetMyPlayerID()]
  local vol = (sound_volume[spGetMyPlayerID()] or 15)*10
  if (pref == nil) or (pref == -1) then return end
  if (last_sfx_played <= spGetGameFrame()-30) then return end
  local spec = select(2, spGetSpectatingState())
  local myAllyTeam = spGetLocalAllyTeamID()
  if (spec or spIsPosInLos(x, y+30, z, myAllyTeam)) then
    spPlaySoundFile(sound_path(pref, sfx_bombed[1]), vol, x, y, z)
  end
  last_sfx_played = spGetGameFrame()
end
function ChangeMode(_, playerID, mode)
  sound_mode[playerID] = tonumber(mode)
  if (sound_mode[playerID] < -1) then
    sound_mode[playerID] = -1
  elseif (sound_mode[playerID] > 2) then
    sound_mode[playerID] = 2
  end
end
function ChangeVolume(_, playerID, mode)
  sound_volume[playerID] = tonumber(mode)
  if (sound_volume[playerID] < 0) then
    sound_volume[playerID] = 0
  elseif (sound_volume[playerID] > 100) then
    sound_volume[playerID] = 100
  end
end

function gadget:Initialize()
  if (tonumber(modOptions.quakesounds) ~= 1) then
    gadgetHandler:RemoveGadget()
--     return
  end
  gadgetHandler:AddSyncAction("quakesounds_multikill", Multikill)
  gadgetHandler:AddSyncAction("quakesounds_combo", Combo)
  gadgetHandler:AddSyncAction("quakesounds_firstblood", Firstblood)
  gadgetHandler:AddSyncAction("quakesounds_humiliation", Humiliation)
  gadgetHandler:AddSyncAction("quakesounds_teamkiller", Teamkiller)
  gadgetHandler:AddSyncAction("quakesounds_bottomfeeder", Bottomfeeder)
  gadgetHandler:AddSyncAction("quakesounds_perfect", Perfect)
  gadgetHandler:AddSyncAction("quakesounds_headshot", Headshot)
  gadgetHandler:AddSyncAction("quakesounds_mode", ChangeMode)
  gadgetHandler:AddSyncAction("quakesounds_volume", ChangeVolume)
end


function gadget:Shutdown()
  gadgetHandler:RemoveSyncAction("quakesounds_multikill")
  gadgetHandler:RemoveSyncAction("quakesounds_combo")
  gadgetHandler:RemoveSyncAction("quakesounds_firstblood")
  gadgetHandler:RemoveSyncAction("quakesounds_humiliation")
  gadgetHandler:RemoveSyncAction("quakesounds_teamkiller")
  gadgetHandler:RemoveSyncAction("quakesounds_bottomfeeder")
  gadgetHandler:RemoveSyncAction("quakesounds_perfect")
  gadgetHandler:RemoveSyncAction("quakesounds_headshot")
  gadgetHandler:RemoveSyncAction("quakesounds_mode")
  gadgetHandler:RemoveSyncAction("quakesounds_volume")
end

end