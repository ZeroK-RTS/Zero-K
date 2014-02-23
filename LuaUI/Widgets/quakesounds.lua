function widget:GetInfo()
  return {
    name	= "Quake sounds",
    desc	= "Extra sounds. Extra annoyance guaranteed! v1.0.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -3,
    experimental= false,
    enabled 	= true,
  }
end

-- ATTENTION this widget does not come in a bundle with sounds, because it's unknown whether they are in public domain or not...
-- YOU are required to download them for your own risk and/or amusement. Hence why this widget is auto-disabled should you not have sounds.
-- Example links:
-- 1) easiest way
-- https://mega.co.nz/#!Tpp3HQTa!fCdP1Tm-9srHvhbE5kWAVO0MGgnlsIpAkshiIxowP-E (5.1 MB)
-- Go to your spring folder and create "sounds" directory and unzip "quake" folder there
-- So it's like this: ~/.spring/sounds/quake/female/dominating.wav and you are done, they are all in wav already anyway.

-- 2) a harder way
-- https://forums.alliedmods.net/showthread.php?t=224316 Quake_Sounds_v3.zip (3.12 MB)
-- Go to your spring folder and create "sounds" directory and unzip "quake" folder there and...
-- WARNING CONVERT ALL STEREO MP3/WAV INTO MONO WAV! how to do it? well google...
-- So it's like this: ~/.spring/sounds/quake/female/dominating.wav

------------------------------INTERNAL CONFIG--------------------------------------------------------------------------------

local sound_mode = -1
local sound_volume = 15
local function OptionsChanged() 
  if (sound_mode~= options.sound_mode) then
    sound_mode = options.quake_sound_mode.value
    Spring.SendLuaRulesMsg("quakesounds_mode "..sound_mode)
    sound_volume = options.quake_sound_volume.value
    Spring.SendLuaRulesMsg("quakesounds_volume "..sound_volume)
  end
end

options_path = 'Settings/Audio/Quake Sounds'
options_order = { 
  'quake_sound_mode', 
  'quake_sound_volume', 
}
options = {
  quake_sound_mode = {
    name = 'Quake Mode (voice pref.)',
    desc = '-1 disable, 0 female, 2 male, 1 mixed',
    type = "number", 
    value = 1, 
    min = -1,
    max = 2,
    step = 1,
    OnChange = OptionsChanged,
  },
  quake_sound_volume = {
    name = 'Quake Volume',
    type = "number", 
    value = 15, 
    min = 0,
    max = 100,
    step = 1,
    OnChange = OptionsChanged,
  },
}

function widget:Initialize()
  local path = "sounds/quake/standard/dominating.wav"
  if not(VFS.FileExists(path)) then
    widgetHandler:RemoveWidget() -- autodisable if you don't have sounds
    return
  end
  if (options.quake_sound_mode.value ~= nil) then
    Spring.SendLuaRulesMsg("quakesounds_mode "..options.quake_sound_mode.value)
  end
  if (options.quake_sound_volume.value ~= nil) then
    Spring.SendLuaRulesMsg("quakesounds_volume "..options.quake_sound_volume.value)
  end
end

function widget:GameStart()
  sound_mode = options.quake_sound_mode.value
  Spring.SendLuaRulesMsg("quakesounds_mode "..sound_mode)
  sound_volume = options.quake_sound_volume.value
  Spring.SendLuaRulesMsg("quakesounds_volume "..sound_volume)
end