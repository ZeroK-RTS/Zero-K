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
local versionNum = '1.11'

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
-- versus666,  v1.1 (26oct2010) : Clean up code/corrected typo.
-- quantum,    v1.0             : creation

--REMINDER to do:
-- Disable robotic sounds heard when playing chicken faction.
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Uses the SelectionChanged call-in
-- Replace your LuaUI/widgets.lua with our LuaUI/cawidgets.lua to benefit from
-- it in other mods

local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID     = Spring.GetUnitDefID
local osClock          = os.clock
local spInView         = Spring.IsUnitInView
local PlaySoundFile    = Spring.PlaySoundFile
local spGetUnitHealth  = Spring.GetUnitHealth

local toleranceTime = Spring.GetConfigInt('DoubleClickTime', 300) * 0.001 -- no event to notify us if this changes but not really a big deal

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Audio'
options_order = {
'selectnoisevolume','ordernoisevolume','attacknoisevolume', 'commandSoundCooldown', 'selectSoundCooldown',
}
options = {
	selectnoisevolume = {
		name = 'Selection Volume',
		type = "number",
		value = 1,
		min = 0,
		max = 1,
		step = 0.02,
		simpleMode = true,
		everyMode = true,
	},
	ordernoisevolume = {
		name = 'Command Volume',
		type = "number",
		value = 1,
		min = 0,
		max = 1,
		step = 0.02,
		simpleMode = true,
		everyMode = true,
	},
	attacknoisevolume = {
		name = 'Commander Under Attack Volume',
		type = "number",
		value = 1,
		min = 0,
		max = 1,
		step = 0.02,
		simpleMode = true,
		everyMode = true,
	},
	commandSoundCooldown = {
		name = 'Command Reply Cooldown',
		type = "number",
		value = 0.05,
		min = 0,
		max = 0.5,
		step = 0.005,
	},
	selectSoundCooldown = {
		name = 'Select Reply Cooldown',
		type = "number",
		value = toleranceTime,
		min = 0,
		max = 0.5,
		step = 0.005,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SOUND_DIRNAME = 'Sounds/reply/'
local SOUND_DIRNAME_SHORT = 'reply/'
local LUAUI_DIRNAME = 'LuaUI/'
local SOUNDTABLE_FILENAME = LUAUI_DIRNAME.."Configs/sounds_noises.lua"
local soundTable = VFS.Include(SOUNDTABLE_FILENAME, nil, VFS.RAW_FIRST)
local myPlayerID = Spring.GetMyPlayerID()
local myTeamID = Spring.GetMyTeamID()
local cooldown = {}

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local widgetCMD = {
	[CMD_EMBARK] = true,
	[CMD_DISEMBARK] = true,
	[CMD_TRANSPORTTO] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function playSound(filename, ...)
	local path = SOUND_DIRNAME..filename..".WAV"
	if (VFS.FileExists(path)) then
		PlaySoundFile(SOUND_DIRNAME_SHORT .. filename, ...)
	else
	--Spring.Echo(filename)
		Spring.Echo("<snd_noises.lua>: Error file "..path.." doesn't exist.")
	end
end


local function CoolNoisePlay(category, cooldownTime, volume)
	cooldownTime = cooldownTime or 0
	local t = osClock()
	if ( (not cooldown[category]) or ((t - cooldown[category]) > cooldownTime) ) then
		playSound(category, volume or 1, 'userinterface') -- not using 'unitreply' because only 1 can play at a time, the next cutting off the first
		cooldown[category] = t
	end
end

function widget:SelectionChanged(selection, subselection)
	if subselection then
		return
	end
	if (not selection[1]) then
		return
	end

	local unitDefID = GetUnitDefID(selection[1])
	if not unitDefID then --only make sound when selecting own units
		return
	end

	local sounds = soundTable[unitDefID]
	if not sounds then
		return
	end

	local sound = sounds.select[1]
	if not sound then
		return
	end

	CoolNoisePlay(sound, options.selectSoundCooldown.value, (sounds.select.volume or 1)*options.selectnoisevolume.value)
end

function WG.sounds_gaveOrderToUnit(unitID, isBuild)
	if not unitID then
		return
	end

	local unitDefID = GetUnitDefID(unitID)
	local sounds = soundTable[unitDefID]
	if not sounds then
		return
	end

	if not isBuild then
		if sounds.ok then
			CoolNoisePlay(sounds.ok[1], options.commandSoundCooldown.value, (sounds.ok.volume or 1)*options.ordernoisevolume.value)
		end
	elseif sounds.build then
		CoolNoisePlay(sounds.build[1], options.commandSoundCooldown.value, options.ordernoisevolume.value)
	end
end

local function PlayResponse(unitID, cmdID)
	unitID = unitID or GetSelectedUnits()[1]
	if not unitID then
		return false
	end
	local unitDefID = GetUnitDefID(unitID)
	if not unitDefID then
		return false
	end
	local sounds = soundTable[unitDefID]
	if cmdID and (CMD[cmdID] or widgetCMD[cmdID] or cmdID > 0) then
		if (sounds and sounds.ok) then
			CoolNoisePlay(sounds.ok[1], options.commandSoundCooldown.value, (sounds.ok.volume or 1)*options.ordernoisevolume.value)
		end
	elseif (sounds and sounds.build) then
		CoolNoisePlay(sounds.build[1], options.commandSoundCooldown.value, options.ordernoisevolume.value)
	end
end

function widget:CommandNotify(cmdID)
	local unitID = GetSelectedUnits()[1]
	if (not unitID) then
		return
	end
	PlayResponse(unitID, cmdID)
end

local unitCommandHandled = false
function widget:UnitCommandNotify(unitID, cmdID, cmdParams)
	if unitCommandHandled then
		return
	end
	PlayResponse(unitID, cmdID)
	unitCommandHandled = true
end

function widget:Update()
	unitCommandHandled = false
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage)
	if unitTeam ~= myTeamID or damage < 1 then
		return
	end

	local unitDefID = GetUnitDefID(unitID)
	local sounds = soundTable[unitDefID]
	if not sounds or not sounds.underattack or not sounds.underattack[1] then
		return
	end

	if not sounds.attackonscreen and spInView(unitID) then
		return
	end

	if sounds.attackdelay and WG.ModularCommAPI.IsStarterComm and WG.ModularCommAPI.IsStarterComm(unitID) then
		local health, maxhealth = spGetUnitHealth(unitID)
		CoolNoisePlay(sounds.underattack[1], sounds.attackdelay(health/maxhealth), (sounds.underattack.volume or 1)*options.attacknoisevolume.value)
	else
		CoolNoisePlay(sounds.underattack[1], 40, (sounds.underattack.volume or 1)*options.attacknoisevolume.value)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External Functions

local externalFunctions = {}

function externalFunctions.PlayResponse(unitID, cmdID)
	PlayResponse(unitID, cmdID)
end

function widget:PlayerChanged(playerID)
	if playerID ~= myPlayerID then
		return
	end
	myTeamID = Spring.GetMyTeamID()
end

function widget:Initialize()
	WG.noises = externalFunctions
end

function widget:Shutdown()
	WG.noises = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

