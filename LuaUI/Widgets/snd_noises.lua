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
local versionNum = '1.1'

function widget:GetInfo()
  return {
    name      = "Noises",
    desc      = "v".. (versionNum) .." Selection, move and attack warning sounds.",
    author    = "quantum",
    date      = "Oct 24, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end
---- CHANGELOG -----
-- versus666, 		v1.1	(26oct2010)	:	Clean up code/corrected typo.
-- quantum,			v1.0				:	creation

--REMINDER to do:
-- Disable robotic sounds heard when playing chicken faction.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Uses the SelectionChanged call-in
-- Replace your LuaUI/widgets.lua with our LuaUI/cawidgets.lua to benefit from
-- it in other mods

local GetSelectedUnits	= Spring.GetSelectedUnits
local GetUnitDefID		= Spring.GetUnitDefID
local GetGameSeconds	= Spring.GetGameSeconds
local GetUnitHealth		= Spring.GetUnitHealth
local spInView			= Spring.IsUnitInView
local PlaySoundFile		= Spring.PlaySoundFile

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SOUND_DIRNAME = 'Sounds/reply/'
local LUAUI_DIRNAME = 'LuaUI/'
local SOUNDTABLE_FILENAME = LUAUI_DIRNAME.."Configs/sounds_noises.lua"
local soundTable = VFS.Include(SOUNDTABLE_FILENAME, nil, VFS.RAW_FIRST)
local myTeamID
local cooldown = {}
local previousSelection

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function playSound(filename, ...)
	local path = SOUND_DIRNAME..filename..".WAV"
	if (VFS.FileExists(path)) then
		PlaySoundFile(path, ...)
	else
	--Spring.Echo(filename)
		Spring.Echo("<snd_noises.lua>: Error file "..path.." doesn't exist.")
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
	local sounds = soundTable[unitName] or soundTable[default]
	if (CMD[cmdID]) then
		if (sounds and sounds.ok) then
			CoolNoisePlay(sounds.ok[1], 0.5)
		end
	elseif (sounds and sounds.build) then
		CoolNoisePlay(sounds.build, 0.5)
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam)
	if (unitTeam == myTeamID) and (not spInView(unitID)) then
		local unitDefID = GetUnitDefID(unitID)
		local unitName = UnitDefs[unitDefID].name
		local sounds = soundTable[unitName] or soundTable[default]
		if sounds and sounds.underattack then
			CoolNoisePlay(sounds.underattack[1], 40)
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

