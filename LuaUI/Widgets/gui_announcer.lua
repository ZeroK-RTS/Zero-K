function widget:GetInfo()
  return {
    name	= "Announcer",
    desc	= "Zero-K announcer, reacts to ingame events and notifies players. v1.3.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= 1,
    enabled = true, -- it has internal option to enable it, by default it's disabled. look for "announcer_mode".
  }
end
-- TODO
-- Custom config support.
-- Attrition events.
-- Flashing labels. (will do soon)
-----------------------------------------------------------------------------------------------------------------------------
local impressiveKillerUnitsDef = { -- you still have to kill more than 600 metal...
 [ UnitDefNames['armcybr'].id ] = true,
 [ UnitDefNames['corroach'].id ] = true,
 [ UnitDefNames['corshad'].id ] = true,
 [ UnitDefNames['corsktl'].id ] = true,
 [ UnitDefNames['screamer'].id ] = true,
 [ UnitDefNames['corroach'].id ] = true,
 [ UnitDefNames['blastwing'].id ] = true,
--  [ UnitDefNames['tacnuke'].id ] = true, -- TODO this unit does not kill by itself, figure out a way to detect its children's kills
}
local impressiveVictimUnitsDef = { -- or this should die
 [ UnitDefNames['amgeo'].id ] = true,
 [ UnitDefNames['cafus'].id ] = true,
 [ UnitDefNames['chickenq'].id ] = true, -- extreme rare
--  [ UnitDefNames['armcomdgun'].id ] = true, -- too often
--  [ UnitDefNames['scorpion'].id ] = true, -- too often
--  [ UnitDefNames['dante'].id ] = true, -- too often
--  [ UnitDefNames['armraven'].id ] = true, -- too often
 [ UnitDefNames['corcrw'].id ] = true, -- krow
 [ UnitDefNames['funnelweb'].id ] = true,
 [ UnitDefNames['armbanth'].id ] = true,
 [ UnitDefNames['armorco'].id ] = true,
--  [ UnitDefNames['cornukesub'].id ] = true,
 [ UnitDefNames['armcarry'].id ] = true, -- these are not expensive but they are not so often built
 [ UnitDefNames['corbats'].id ] = true, -- these are not expensive but they are not so often built
}
local headshotUnitsDef = { -- or commtype
 [ UnitDefNames['armcomdgun'].id ] = true,
 [ UnitDefNames['scorpion'].id ] = true,
 [ UnitDefNames['dante'].id ] = true,
 [ UnitDefNames['armraven'].id ] = true,
 [ UnitDefNames['corcrw'].id ] = true,
 [ UnitDefNames['funnelweb'].id ] = true,
 [ UnitDefNames['armbanth'].id ] = true,
 [ UnitDefNames['armorco'].id ] = true,
} -- TODO make it so weapons are triggers, but not units themselves...
local aircraft_found = false
local AircraftDef = {
 [ UnitDefNames['armca'].id ] = true,
 [ UnitDefNames['blastwing'].id ] = true,
 [ UnitDefNames['bladew'].id ] = true,
 [ UnitDefNames['armkam'].id ] = true,
 [ UnitDefNames['corape'].id ] = true,
 [ UnitDefNames['armbrawl'].id ] = true,
 [ UnitDefNames['blackdawn'].id ] = true,
 [ UnitDefNames['corcrw'].id ] = true,
 [ UnitDefNames['gunshipaa'].id ] = true,
 [ UnitDefNames['corvalk'].id ] = true,
 [ UnitDefNames['corbtrans'].id ] = true,
 [ UnitDefNames['fighter'].id ] = true,
 [ UnitDefNames['corvamp'].id ] = true,
 [ UnitDefNames['corshad'].id ] = true,
 [ UnitDefNames['corhurc2'].id ] = true,
 [ UnitDefNames['armstiletto_laser'].id ] = true,
 [ UnitDefNames['armcybr'].id ] = true,
 [ UnitDefNames['corawac'].id ] = true,
 [ UnitDefNames['factorygunship'].id ] = true,
 [ UnitDefNames['factoryplane'].id ] = true,
 [ UnitDefNames['factoryplane'].id ] = true,
 [ UnitDefNames['bomberassault'].id ] = true,
 [ UnitDefNames['nebula'].id ] = true,
}
local strider_found = false -- will trigger on any strider, even that was already built
local StriderDef = {
 [ UnitDefNames['armcomdgun'].id ] = true,
 [ UnitDefNames['scorpion'].id ] = true,
 [ UnitDefNames['dante'].id ] = true,
 [ UnitDefNames['armraven'].id ] = true,
 [ UnitDefNames['funnelweb'].id ] = true,
 [ UnitDefNames['armbanth'].id ] = true,
 [ UnitDefNames['armorco'].id ] = true,
 [ UnitDefNames['cornukesub'].id ] = true,
 [ UnitDefNames['armcarry'].id ] = true,
 [ UnitDefNames['corbats'].id ] = true,
 [ UnitDefNames['nebula'].id ] = true,
 [ UnitDefNames['corcrw'].id ] = true,
}
-----------------------------------------------------------------------------------------------------------------------------
local random			= math.random
local spGetUnitDefID		= Spring.GetUnitDefID
local spGetUnitTeam	   	= Spring.GetUnitTeam
local spGetMyAllyTeamID		= Spring.GetMyAllyTeamID
local spGetTeamInfo		= Spring.GetTeamInfo
local spGetGameFrame		= Spring.GetGameFrame
local spGetUnitPosition 	= Spring.GetUnitPosition
local spGetUnitRulesParam	= Spring.GetUnitRulesParam
local spGetGroundHeight     	= Spring.GetGroundHeight
local spGetMyTeamID		= Spring.GetMyTeamID
local spGetTeamResources    	= Spring.GetTeamResources
local spPlaySoundFile		= Spring.PlaySoundFile
local spGetTeamList         	= Spring.GetTeamList
local spGetSelectedUnits 	= Spring.GetSelectedUnits
local spGetMyPlayerID		= Spring.GetMyPlayerID
local spGetPlayerInfo		= Spring.GetPlayerInfo
local spSendLuaRulesMsg		= Spring.SendLuaRulesMsg
local spGetUnitIsDead		= Spring.GetUnitIsDead
local spValidUnitID		= Spring.ValidUnitID
local spGetUnitHeight		= Spring.GetUnitHeight
local spWorldToScreenCoords	= Spring.WorldToScreenCoords
local spIsUnitInView		= Spring.IsUnitInView
local spGetTeamColor		= Spring.GetTeamColor
local spGetSpectatingState	= Spring.GetSpectatingState

local modOptions = Spring.GetModOptions()
local waterLevel = modOptions.waterlevel and tonumber(modOptions.waterlevel) or 0
local getMovetype = Spring.Utilities.getMovetype

local GaiaTeamID	   	= Spring.GetGaiaTeamID()
local DeathDistance		= 500
local DeathDistanceSQ		= DeathDistance*DeathDistance

local DeathMarkers		= {}
local DeathExpire		= 30 -- frames after which DeathMarker is destroyed

local myTeamID
local myTeamIDs = {}
local myName = "Player"
local spec

-- basically you are gonna be able to mix any soundpack... i also TODO for myself user defined config ability...
local BASE_VOLUME = 18.0 -- for area sounds
local announcer_mode = 0 -- off/on
local announcer_use_xonotic = 1
local announcer_use_kmar = 1
local announcer_volume = 1.0
local announcer_tauntshow = 9
local announcer_tauntsize = 16
local announcer_tauntdecay = 6

local LastSpam = -100
local LastTaunt = -100

local sfx_path = "sounds/announcer/"

local check_later = {}

local activeTaunts = {}	-- [unitID] = {stuff for tip being displayed}

local glGetTextHeight		= gl.GetTextHeight

-- Chili classes
local Chili
local Window
local TextBox
local Image
local Font
local color2incolor
local incolor2color

-- Chili instances
local screen0

local font = "LuaUI/Fonts/komtxt__.ttf" -- I would change the font...

local gameframe = -100

local function InitSoundTable()
	return {
		-- killing (sphree) sounds
		airshot = {}, -- airshot sounds.
		headshot = {}, -- headshot sounds.
		highcost_kill = {}, -- killing or death of highcost structure/unit.
		multikill_generic = {}, -- this features multikill/combo of any kind, because we don't have sounds for "ultrakill/rampage/etc"...
		-- situational sounds, i will code more events as i get my hands on more sounds...
		airplanes = {}, -- is played only once, when it's the first time you see enemy aircraft (drones not count).
		estall = {}, -- is played when you stall energy, is played once, until you generate more energy.
		strider = {}, -- is played only once, when it's the first time you see enemy strider.
		mexcess = {}, -- is played when your entire team excess metal, is played once, until your team starts to use metal.
		enemy_overpowered = {}, -- is played only once, when your team is having much more firepower than any other enemy.
		commander_lost = {}, -- is played when your commander is dead.
	}
end
local asounds = InitSoundTable()
local function LoadXonoticSounds()
	asounds.airshot[#asounds.airshot+1] = "airshot.wav"
	asounds.headshot[#asounds.headshot+1] = "headshot.wav"
	asounds.highcost_kill[#asounds.highcost_kill+1] = "impressive.wav"
	asounds.highcost_kill[#asounds.highcost_kill+1] = "amazing1.wav"
	asounds.highcost_kill[#asounds.highcost_kill+1] = "amazing2.wav"
	asounds.multikill_generic[#asounds.multikill_generic+1] = "awesome1.wav"
	asounds.multikill_generic[#asounds.multikill_generic+1] = "awesome2.wav"
	asounds.multikill_generic[#asounds.multikill_generic+1] = "amazing1.wav"
	asounds.multikill_generic[#asounds.multikill_generic+1] = "amazing2.wav"
end
local function LoadKmarSounds()
	asounds.headshot[#asounds.headshot+1] = "kmar/headshot1.wav"
	asounds.headshot[#asounds.headshot+1] = "kmar/headshot2.wav"
	asounds.headshot[#asounds.headshot+1] = "kmar/headshot3.wav"
	asounds.commander_lost[#asounds.commander_lost+1] = "kmar/commander_lost1.wav"
	asounds.commander_lost[#asounds.commander_lost+1] = "kmar/commander_lost2.wav"
	asounds.estall[#asounds.estall+1] = "kmar/estall1.wav"
	asounds.estall[#asounds.estall+1] = "kmar/estall2.wav"
	asounds.airplanes[#asounds.airplanes+1] = "kmar/airplanes1.wav"
	asounds.airplanes[#asounds.airplanes+1] = "kmar/airplanes2.wav"
	asounds.mexcess[#asounds.mexcess+1] = "kmar/mexcess1.wav"
	asounds.mexcess[#asounds.mexcess+1] = "kmar/mexcess2.wav"
	asounds.strider[#asounds.strider+1] = "kmar/strider.wav"
end
local function ReloadSounds()
	asounds = InitSoundTable()
	if (announcer_use_xonotic) then -- are tables sent by address, not by var in lua?
		LoadXonoticSounds()
	end
	if (announcer_use_kmar) then
		LoadKmarSounds()
	end
end
local function OptionsChanged()
  if (announcer_mode ~= options.announcer_mode) then
    announcer_mode = options.announcer_mode.value
  end
  if (announcer_use_xonotic ~= options.announcer_use_xonotic) then
    announcer_use_xonotic = options.announcer_use_xonotic.value
  end
  if (announcer_use_kmar ~= options.announcer_use_kmar) then
    announcer_use_kmar = options.announcer_use_kmar.value
  end
  if (announcer_volume ~= options.announcer_volume) then
    announcer_volume = options.announcer_volume.value
  end
  if (announcer_tauntshow ~= options.announcer_tauntshow) then
    announcer_tauntshow = options.announcer_tauntshow.value
  end
  if (announcer_tauntdecay ~= options.announcer_tauntdecay) then
    announcer_tauntdecay = options.announcer_tauntdecay.value
  end
  if (announcer_tauntsize ~= options.announcer_tauntsize) then
    announcer_tauntsize = options.announcer_tauntsize.value
  end
  ReloadSounds()
end

options_path = 'Settings/Misc/Announcer' -- don't know where to put it!
options_order = { 
  'announcer_mode',
  'announcer_volume',
  'announcer_use_xonotic',
  'announcer_use_kmar',
  'announcer_tauntshow',
  'announcer_tauntdecay',
  'announcer_tauntsize',
}
options = {
  announcer_mode = {
    name = 'Announcer sounds enabled',
    type = 'bool',
    value = false,
    OnChange = OptionsChanged,
  },
  announcer_volume = { -- it obeys global volume
    name = 'Announcer Volume',
    type = "number", 
    value = 1.0, 
    min = 0,
    max = 1,
    step = 0.02,
  },
  announcer_use_xonotic = {
    name = 'Use Xonotic sounds',
    type = 'bool',
    value = true,
    OnChange = OptionsChanged,
  },
  announcer_use_kmar = {
    name = 'Use Kmar sounds',
    type = 'bool',
    value = true,
    OnChange = OptionsChanged,
  },
--   announcer_use_custom = { -- TODO
--     name = 'User-made sound defines',
--     type = 'bool',
--     value = true,
--     OnChange = OptionsChanged,
--   },
  announcer_tauntshow = {
    name = 'Enable taunts (u: or /u chatcmd)',
    type = 'bool',
    value = true,
    OnChange = OptionsChanged,
  },
  announcer_tauntdecay = { -- it obeys global volume
    name = 'Taunt text lifespan',
    type = "number", 
    value = 9, 
    min = 1,
    max = 20,
    step = 1,
  },
  announcer_tauntsize = { -- it obeys global volume
    name = 'Taunt font size',
    type = "number", 
    value = 16, 
    min = 6,
    max = 46,
    step = 1,
  },
}

-- local function LoadCustomConfig() -- TODO
-- 	local default_config = LUAUI_DIRNAME .. 'Configs/' .. confdata.default_source_file
-- 	local file_return = VFS.FileExists(default_config, VFS.ZIP) and VFS.Include(default_config, nil, VFS.ZIP) or {keybinds={},date=0}
-- 	if (file_return ~= nil) then -- try to parse it
-- 	end
-- end

-----------------------------------------------------------------------------------------------------------------------------

local function disSQ(x1,y1,x2,y2)
  return (x1 - x2)^2 + (y1 - y2)^2
end

local function AnnouncerAirshot(x, y, z)
  if not(announcer_mode) or (announcer_volume == 0) then return end
  if (LastSpam+30 >= gameframe) then return end
  if (#asounds.airshot > 0) then
    local sound_file = asounds.airshot[random(1,#asounds.airshot)]
    spPlaySoundFile(sfx_path..sound_file, BASE_VOLUME * announcer_volume, x, y, z)
    LastSpam = gameframe
  end
end

local function AnnouncerAwesome(x, y, z) -- multikill
  if not(announcer_mode) or (announcer_volume == 0) then return end
  if (LastSpam+30 >= gameframe) then return end
  if (#asounds.multikill_generic > 0) then
    local sound_file = asounds.multikill_generic[random(1,#asounds.multikill_generic)]
    spPlaySoundFile(sfx_path..sound_file, BASE_VOLUME * announcer_volume, x, y, z)
    LastSpam = gameframe
  end
end

local function AnnouncerImpressive(x, y, z) -- heavycost kill/death
  if not(announcer_mode) or (announcer_volume == 0) then return end
  if (LastSpam+30 >= gameframe) then return end
  if (#asounds.highcost_kill > 0) then
    local sound_file = asounds.highcost_kill[random(1,#asounds.highcost_kill)]
    spPlaySoundFile(sfx_path..sound_file, BASE_VOLUME * announcer_volume, x, y, z)
    LastSpam = gameframe
  end
end

local function AnnouncerHeadshot(x, y, z)
  if not(announcer_mode) or (announcer_volume == 0) then return end
  if (LastSpam+30 >= gameframe) then return end
  if (#asounds.headshot > 0) then
    local sound_file = asounds.headshot[random(1,#asounds.headshot)]
    spPlaySoundFile(sfx_path..sound_file, BASE_VOLUME * announcer_volume, x, y, z)
    LastSpam = gameframe
  end
end

local function AnnounceComDeath()
  if not(announcer_mode) or (announcer_volume == 0) then return end
--   if (LastSpam+30 >= gameframe) then return end -- rare event, it's your own commander after all
  if (#asounds.commander_lost > 0) then
    local sound_file = asounds.commander_lost[random(1,#asounds.commander_lost)]
    spPlaySoundFile(sfx_path..sound_file, announcer_volume)
    LastSpam = gameframe
  end
end

local function AnnounceAircraft()
  if not(announcer_mode) or (announcer_volume == 0) then return end
--   if (LastSpam+30 >= gameframe) then return end -- ignore limit, always play, because it's one-time
  if (#asounds.airplanes > 0) then
    local sound_file = asounds.airplanes[random(1,#asounds.airplanes)]
    spPlaySoundFile(sfx_path..sound_file, announcer_volume)
    LastSpam = gameframe
  end
end

local function AnnounceStrider()
  if not(announcer_mode) or (announcer_volume == 0) then return end
--   if (LastSpam+30 >= gameframe) then return end -- ignore limit, always play, because it's one-time
  if (#asounds.strider > 0) then
    local sound_file = asounds.strider[random(1,#asounds.strider)]
    spPlaySoundFile(sfx_path..sound_file, announcer_volume)
    LastSpam = gameframe
  end
end

local function AnnounceMexcess()
  if not(announcer_mode) or (announcer_volume == 0) then return end
--   if (LastSpam+30 >= gameframe) then return end -- hopefully not spammy
  if (#asounds.mexcess > 0) then
    local sound_file = asounds.mexcess[random(1,#asounds.mexcess)]
    spPlaySoundFile(sfx_path..sound_file, announcer_volume)
    LastSpam = gameframe
  end
end

local function AnnounceEstall()
  if not(announcer_mode) or (announcer_volume == 0) then return end
--   if (LastSpam+30 >= gameframe) then return end -- hopefully not spammy
  if (#asounds.estall > 0) then
    local sound_file = asounds.estall[random(1,#asounds.estall)]
    spPlaySoundFile(sfx_path..sound_file, announcer_volume)
    LastSpam = gameframe
  end
end

local function GetNearestMarker(x,z)
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

local function spGetGroundHeight2(x,z)
  local y = spGetGroundHeight(x,z)
  if (y < waterLevel) then
    return waterLevel
  end
  return y
end

local function CheckUnitType(unitID, unitDefID)
  if (AircraftDef[unitDefID]) and not(aircraft_found) then
    aircraft_found = true
    AnnounceAircraft()
  end
  if (StriderDef[unitDefID]) and not(strider_found) then
    strider_found = true
    AnnounceStrider()
  end
end

local function DisposeTaunt(unitID)
	if activeTaunts[unitID] and activeTaunts[unitID].img then
		activeTaunts[unitID].img:Dispose()
	end
	activeTaunts[unitID] = nil
end

local function UnitDead(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
  DisposeTaunt(unitID)
  if (unitDefID ~= nil ) then
    local ud = UnitDefs[unitDefID]
    if (not ud.customParams.dontcount) and (not spGetUnitRulesParam(unitID, 'wasMorphedTo')) then
      local x,y,z = spGetUnitPosition(unitID)
      if (GaiaTeamID ~= attackerID) then -- and (attackerTeamID ~= nil) then
	local markerID = GetNearestMarker(x,z) -- Z level is ignored
	if (markerID ~= nil) then
	  DeathMarkers[markerID].kills = DeathMarkers[markerID].kills + 1
	  -- TODO nanoframes metalcost should be scaled by their health
	  DeathMarkers[markerID].wasted = DeathMarkers[markerID].wasted + ud.metalCost
	  DeathMarkers[markerID].x = (DeathMarkers[markerID].x+x)/2
	  DeathMarkers[markerID].z = (DeathMarkers[markerID].z+z)/2
	  DeathMarkers[markerID].y = spGetGroundHeight2(DeathMarkers[markerID].x,DeathMarkers[markerID].z)
	  DeathMarkers[markerID].time = gameframe
	  DeathMarkers[markerID].teams[teamID] = true
	  if (attackerTeamID ~= nil) then
	    DeathMarkers[markerID].teams[attackerTeamID] = true
	  end
	else
	  DeathMarkers[unitID] = {
	    kills = 1,
	    wasted = 0+ud.metalCost,
	    x = x,
	    y = y,
	    z = z,
	    time = gameframe,
	    teams = {}
	  }
	  DeathMarkers[unitID].teams[teamID] = true
	  if (attackerTeamID ~= nil) then
	    DeathMarkers[unitID].teams[attackerTeamID] = true
	  end
	end
	if (attackerTeamID == nil) or (select(6,spGetTeamInfo(teamID)) ~= select(6,spGetTeamInfo(attackerTeamID))) then
	  if (attackerDefID ~= nil) then
	    if ((impressiveKillerUnitsDef[attackerDefID]) and ((ud.metalCost >= 600) or ud.customParams.commtype)) or (impressiveVictimUnitsDef[unitDefID]) then
	      AnnouncerImpressive(x, y, z)
	    end
	    if (ud.customParams.commtype or headshotUnitsDef[unitDefID]) or (((attackerDefID~=nil) and headshotUnitsDef[attackerDefID]) and (ud.metalCost >= 1200) and (ud.canMove)) then
	      AnnouncerHeadshot(x, y, z)
	    end
	    if (ud.customParams.commtype) and (teamID == myTeamID) then
	      AnnounceComDeath()
	    end
	  end
	  if (x ~= nil) then
	    local groundHeight = spGetGroundHeight2(x,z)
	    if (not(ud.canFly) and ((y-40) >= groundHeight)) then -- 40 diff is just above defender
	      AnnouncerAirshot(x, y, z)
	    end
	  end
	end
      end
    end
  end
end

function widget:UnitEnteredLos(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if (unitDefID == nil) then
		check_later[unitID] = true
	else
		CheckUnitType(unitID, unitDefID)
	end
end

local function AlliesHaveFullM()
	for teamID, _ in pairs(myTeamIDs) do
		local mCur, mMax, mPull, mInc, _, _, _, _ = spGetTeamResources(teamID, "metal")
		if (mInc) and (mMax > 0) then -- TODO it crashes here if i don't check for nil when i use cheat stuff
			if (mCur+(mInc*3)) < mMax then return false end
		end
	end
	return true
end

local once = true
local function CheckResources()
	local WeAreExcessingMetal = AlliesHaveFullM()
	if WeAreExcessingMetal and not(metal_excess) then
		metal_excess = true
		AnnounceMexcess()
	elseif not(WeAreExcessingMetal) and metal_excess then
		metal_excess = false
	end
	local eCur, eMax, ePull, eInc, _, _, _, _ = spGetTeamResources(myTeamID, "energy")
	if (eCur) and (eMax > 0) then -- TODO it crashes here if i don't check for nil when i use cheat stuff
		local NotEnoughEnergy = ((eCur+eInc) <= 1)
		if NotEnoughEnergy and not(energy_stall) then
			energy_stall = true
			AnnounceEstall()
		elseif not(NotEnoughEnergy) and energy_stall then
			energy_stall = false
		end
	end
end

function widget:GameFrame(n)
  gameframe = n
  for markerID, data in pairs(DeathMarkers) do
    if (n-45) >= data.time then
      local x = data.x
      local y = data.y
      local z = data.z
      local kills = data.kills
      local wasted = data.wasted
      if ((kills >= 10) and (wasted >= 900)) or (wasted >= 6200) then -- hard to get in the begining 'ey?
	for teamID, _ in pairs(data.teams) do
	  AnnouncerAwesome(x, y, z)
	end
      end
      DeathMarkers[markerID] = nil
    end
    if (myTeamID ~= spGetMyTeamID()) then
      myTeamID = spGetMyTeamID()
    end
  end
  if (n%32)==0 then
    if spec ~= spGetSpectatingState() then
	  spec = spGetSpectatingState()
    end
    if spec==false then
      for unitID,_ in pairs(check_later) do
	  local unitDefID = spGetUnitDefID()
	  if (unitDefID ~= nil) then
	    check_later[unitID] = nil
	    CheckUnitType(unitID, unitDefID)
	  end
      end
      CheckResources()
    end
  end
end

local function AnnouncerUnitDestroyed(PlayerID, unitID, attackerID)
--   Spring.Echo("got event: "..tostring(unitID).." died by "..tostring(attackerID))
  local unitDefID = spGetUnitDefID(unitID)
  local teamID = spGetUnitTeam(unitID)
  local attackerDefID, attackerTeamID
  if (attackerID ~= nil) then
    attackerDefID = spGetUnitDefID(attackerID)
    attackerTeamID = spGetUnitTeam(attackerID)
  end
  UnitDead(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
end

local function GetNiceUnit(units) -- TODO it needs to select unit that is 1) movable 2) closest to the center of group, but i'm too lazy right now
  if (#units > 100) then return units[1] end
  for i=1,#units do
    local unitID = units[i]
    local unitDefID = spGetUnitDefID(unitID)
    if getMovetype(UnitDefs[unitDefID]) ~= false then
      return unitID
    end
  end
  return units[1]
end

function trim(s)
 return s:find'^%s*$' and '' or s:match'^%s*(.*%S)'
end

local function TryTaunt(msg)
  if (msg ~= "") then
    msg = trim(msg)
    local units = spGetSelectedUnits()
    if (#units > 0) then
      spSendLuaRulesMsg("unit_taunt "..GetNiceUnit(units).." "..msg)
    end
  end
end

function widget:TextCommand(command)
  local cmd = command:sub(1,2)
  if cmd == "u " then
    local msg = command:sub(3)
    TryTaunt(msg)
  end
end
    
function widget:AddConsoleMessage(msg) -- I'm too lazy to detect specsay, and why would you "secretly" unit taunt? you have /u already ^
  if (msg ~= nil) then
    local allies = (msg.msgtype == "player_to_allies")
    local msg = msg.text
    if msg:find("<"..myName.."> u:") then
      if (LastTaunt+10 >= gameframe) then return end
      TryTaunt(msg:sub(6+#myName))
      LastTaunt = gameframe
    elseif (allies) then
      msg = msg:sub(12+#myName)
      local index = msg:find("u:")
      if index then
	msg = msg:sub(index+2)
	if (LastTaunt+10 >= gameframe) then return end
	TryTaunt(msg)
	LastTaunt = gameframe
      end
    end
  end
end

local function GetTauntDimensions(unitID, str, height, invert)
	local textHeight, _, numLines = glGetTextHeight(str)
	textHeight = textHeight*announcer_tauntsize*numLines
	local textWidth = gl.GetTextWidth(str)*announcer_tauntsize

	local ux, uy, uz = spGetUnitPosition(unitID)
	uy = uy + height
	local x,y,z = spWorldToScreenCoords(ux, uy, uz)
	if not invert then
		y = screen0.height - y
	end
	
	return textWidth, textHeight, x, y, height
end

function widget:Update(dt)
	-- chili code
	for unitID, tipData in pairs(activeTaunts) do
		if spIsUnitInView(unitID) then
			local textWidth, textHeight, x, y = GetTauntDimensions(unitID, tipData.str, tipData.height)
			
			local img = tipData.img
			if img.hidden then
				screen0:AddChild(img)
				img.hidden = false
			end
			
			--img.x = x - (textWidth+8)/2
			--img.y = y - textHeight - 4 - announcer_tauntsize
			--img:Invalidate()
			
			img:SetPos(x - (textWidth+8)/2, y - textHeight - 4 - announcer_tauntsize)
		elseif not tipData.img.hidden then
			screen0:RemoveChild(tipData.img)
			tipData.img.hidden = true
		end
		if tipData.expire < gameframe then
			DisposeTaunt(unitID)
		end
	end
end

-- cheers to KingRaptor for unit_clippy.lua widget, got inspired!
local function unitTaunt(PlayerID, unitID, text)
	if spGetUnitIsDead(unitID) or not(spValidUnitID(unitID)) or not(unitID) then
		return
	end
	DisposeTaunt(unitID)
	
	local height = spGetUnitHeight(unitID)
	if not height then return end
	
	local textWidth, textHeight, x, y = GetTauntDimensions(unitID, text, height)

	local img = Image:New {
		width = textWidth + 4,
		height = textHeight + 4 + announcer_tauntsize,
		x = x - (textWidth+8)/2;
		y = y - textHeight - 4 - announcer_tauntsize;
		keepAspect = false,
		color = {0.7,0.7,0.7,0.4},
		file = "LuaUI/Images/speechbubble.png";
		parent = screen0;
	}
	local teamcolor = {Spring.GetTeamColor(spGetUnitTeam(unitID))} or {1,1,1,1}
	local textBox = TextBox:New{
		parent  = img;
		text    = text,
		height	= textHeight,
		width   = textWidth,
		x = 4,
		y = 4,
		valign  = "center";
		align   = "left";
		font    = {
			font   = font;
			size   = announcer_tauntsize;
			color  = teamcolor;
			outlineColor  = {0,0,0,0},
		},
	}
	
	activeTaunts[unitID] = {str = text, expire = gameframe + 32*announcer_tauntdecay, height = height, img = img, textBox = textBox}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:RegisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
  widgetHandler:RegisterGlobal("unitTaunt", unitTaunt)
  local myAllyTeam = spGetMyAllyTeamID()
  for _,t in pairs(spGetTeamList()) do
	  if myAllyTeam == select(6,spGetTeamInfo(t)) then
		  myTeamIDs[t] = true
	  end
  end
  myTeamID=spGetMyTeamID()
  myName = select(1,spGetPlayerInfo(spGetMyPlayerID()))
  if (options.announcer_mode) then announcer_mode = options.announcer_mode.value end
  if (options.announcer_use_xonotic) then announcer_use_xonotic = options.announcer_use_xonotic.value end
  if (options.announcer_use_kmar) then announcer_use_kmar = options.announcer_use_kmar.value end
  if (options.announcer_volume) then announcer_volume = options.announcer_volume.value end
  if (options.announcer_tauntdecay) then announcer_tauntdecay = options.announcer_tauntdecay.value end
  if (options.announcer_tauntshow) then announcer_tauntshow = options.announcer_tauntshow.value end
  if (options.announcer_tauntsize) then announcer_tauntsize = options.announcer_tauntsize.value end
  Chili = WG.Chili
  TextBox = Chili.TextBox
  Image = Chili.Image
  Font = Chili.Font
  screen0 = Chili.Screen0
  color2incolor = Chili.color2incolor
  incolor2color = Chili.incolor2color
end

function widget:Shutdown()
  widgetHandler:DeregisterGlobal("unitDiedInLos", AnnouncerUnitDestroyed)
  widgetHandler:DeregisterGlobal("unitTaunt", unitTaunt)
end
