function widget:GetInfo()
  return {
    name	= "Announcer",
    desc	= "Zero-K announcer, reacts to ingame events and notifies players. v1.0.",
    author	= "Tom Fyuri",
    date	= "2014",
    license	= "GPL v2 or later",
    layer	= -1,
    enabled 	= true,
  }
end
-----------------------------------------------------------------------------------------------------------------------------

local random			= math.random

local sound_mode = 1 -- off/on
local LastSpam = -100

local sfx_path = "sounds/announcer/"

local function OptionsChanged() 
  if (sound_mode~= options.sound_mode) then
    sound_mode = options.sound_mode.value
  end
end

options_path = 'Settings/Audio/Announcer'
options_order = { 
  'sound_mode',  
}
options = {
  sound_mode = {
    name = 'Announcer enabled',
    type = 'bool',
    value = true,
    OnChange = OptionsChanged,
  },
}

-----------------------------------------------------------------------------------------------------------------------------

function AnnouncerAirshot(PlayerID, x, y, z)
  if not(options.sound_mode.value) then return true end
  if (PlayerID ~= Spring.GetMyPlayerID()) then return true end
  if (LastSpam+30 >= Spring.GetGameFrame()) then return true end
  Spring.PlaySoundFile(sfx_path.."airshot.wav", 18.0, x, y, z)
  LastSpam = Spring.GetGameFrame()
  return true
end

function AnnouncerAwesome(PlayerID, x, y, z)
  if not(options.sound_mode.value) then return true end
  if (PlayerID ~= Spring.GetMyPlayerID()) then return true end
  if (LastSpam+30 >= Spring.GetGameFrame()) then return true end
  if (random(1,2) == 1) then
    Spring.PlaySoundFile(sfx_path.."awesome"..random(1,2)..".wav", 18.0, x, y, z)
  else
    Spring.PlaySoundFile(sfx_path.."amazing"..random(1,2)..".wav", 18.0, x, y, z)
  end
  LastSpam = Spring.GetGameFrame()
  return true
end

function AnnouncerImpressive(PlayerID, x, y, z)
  if not(options.sound_mode.value) then return true end
  if (PlayerID ~= Spring.GetMyPlayerID()) then return true end
  if (LastSpam+30 >= Spring.GetGameFrame()) then return true end
  if (random(1,2) == 1) then
    Spring.PlaySoundFile(sfx_path.."impressive.wav", 18.0, x, y, z)
  else
    Spring.PlaySoundFile(sfx_path.."amazing"..random(1,2)..".wav", 18.0, x, y, z)
  end
  LastSpam = Spring.GetGameFrame()
  return true
end

function AnnouncerHeadshot(PlayerID, x, y, z)
  if not(options.sound_mode.value) then return true end
  if (PlayerID ~= Spring.GetMyPlayerID()) then return true end
  if (LastSpam+30 >= Spring.GetGameFrame()) then return true end
  Spring.PlaySoundFile(sfx_path.."headshot.wav", 18.0, x, y, z)
  LastSpam = Spring.GetGameFrame()
  return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
  widgetHandler:RegisterGlobal("AnnouncerAirshot", AnnouncerAirshot)
  widgetHandler:RegisterGlobal("AnnouncerAwesome", AnnouncerAwesome)
  widgetHandler:RegisterGlobal("AnnouncerImpressive", AnnouncerImpressive)
  widgetHandler:RegisterGlobal("AnnouncerHeadshot", AnnouncerHeadshot)
end

function widget:Shutdown()
  widgetHandler:DeregisterGlobal("AnnouncerAirshot", AnnouncerAirshot)
  widgetHandler:DeregisterGlobal("AnnouncerAwesome", AnnouncerAwesome)
  widgetHandler:DeregisterGlobal("AnnouncerImpressive", AnnouncerImpressive)
  widgetHandler:DeregisterGlobal("AnnouncerHeadshot", AnnouncerHeadshot)
end
