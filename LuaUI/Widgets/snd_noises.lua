-- $Id: snd_noises.lua 3171 2008-11-06 09:06:29Z det $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    snd_chatterbox.lua
--  brief:   annoys sounds
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Noises",
    desc      = "Selection, move and attack warning sounds.",
    author    = "quantum",
    date      = "Oct 24, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Uses the SelectionChanged call-in
-- Replace your LuaUI/widgets.lua with our LuaUI/cawidgets.lua to benefit from
-- it in other mods


local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID     = Spring.GetUnitDefID
local GetGameSeconds   = Spring.GetGameSeconds
local GetUnitHealth    = Spring.GetUnitHealth

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local SOUND_DIRNAME = 'Sounds/reply/'
local LUAUI_DIRNAME = 'LuaUI/'
local SOUNDTABLE_FILENAME = LUAUI_DIRNAME.."Widgets/noises/sounds.lua"
local soundTable = VFS.Include(SOUNDTABLE_FILENAME, nil, VFS.RAW_FIRST)
local myTeamID
local cooldown = {}
local previousSelection

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function playSound(filename, ...)
  local path = SOUND_DIRNAME..filename..".WAV"
  if (VFS.FileExists(path)) then
    Spring.PlaySoundFile(path, ...)
  else
	--Spring.Echo(filename)
    print("Error: file "..path.." doest not exist.")
  end
end


local function CoolNoisePlay(category, cooldownTime) 
  cooldownTime = cooldownTime or 0
  local t = GetGameSeconds()
  if ( (not cooldown[category]) or ((t - cooldown[category]) > cooldownTime) ) then
    playSound(category)
    cooldown[category] = t
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  local _, _, spec, team = Spring.GetPlayerInfo(Spring.GetMyPlayerID()) 
  myTeamID = team
  WG.noises = true
end


function widget:Shutdown()
  WG.noises = nil
end


function widget:SelectionChanged(selection)
  if (not selection[1]) then
    return
  end
  local unitName = UnitDefs[GetUnitDefID(selection[1])].name
  if (unitName and soundTable[unitName]) then
    local sound = soundTable[unitName].select[1]
    if (sound) then
      CoolNoisePlay(string.upper(sound), 0.5)
    end
  end
end


function widget:CommandNotify(cmdID)
  local unitID = GetSelectedUnits()[1]
  if (not unitID) then
    return
  end
  local unitDefID = GetUnitDefID(unitID)
  local unitName = UnitDefs[unitDefID].name
  local sounds = soundTable[unitName]
  if (CMD[cmdID]) then
    if (sounds and sounds.ok) then
      CoolNoisePlay(sounds.ok[1], 0.5)
    end
  elseif (sounds and sounds.build) then
    CoolNoisePlay(sounds.build, 0.5)
  end
end


function widget:UnitDamaged(unitID, unitDefID, unitTeam)
  if (unitTeam == myTeamID) then
    
    if (UnitDefs[unitDefID].isCommander) then
      health, maxHealth = GetUnitHealth(unitID)
      if health/maxHealth < 0.5 then
        CoolNoisePlay("warning2", 2)
      else
        CoolNoisePlay("warning1", 2)
      end
    end
  
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
