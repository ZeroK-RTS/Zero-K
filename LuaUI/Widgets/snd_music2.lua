--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:   gui_music.lua
--	brief:  yay music
--	author: cake
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name    = "Music Player v2",
		desc    = "Plays music based on situation",
		author  = "cake, trepan, Smoth, Licho, xponen, Birdulon",
		date    = "Mar 01, 2008, Aug 20 2009, Nov 23 2011, Jul 20 2023",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true -- loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local includedAlbums = {
	denny = {
		dir = "",
		humanName = "Schneidemesser (default)",
	},
	superintendent = {
		dir = "ost23_uf/",
		humanName = "Superintendent",
	}
}
local oldTrackListName = 'denny'

local trackList = {}
local moodPriorityBucketsNonEmpty = {}  -- Generated on album change

options_path = 'Settings/Audio'
options = {
	useIncludedTracks = {
		name = "Use Included Tracks",
		type = 'bool',
		value = true,
		desc = 'Use the tracks included with Zero-K',
		noHotkey = true,
	},
	pausemusic = {
		name = 'Pause Music',
		type = 'bool',
		value = false,
		desc = "Music pauses with game",
		noHotkey = true,
	},
	albumSelection = {
		name = 'Track list',
		type = 'radioButton',
		value = oldTrackListName,
		items = {
			{key = 'denny', name = includedAlbums.denny.humanName},
			{key = 'superintendent', name = includedAlbums.superintendent.humanName},
		},
		OnChange = function(self, value)
			if self.value ~= oldTrackListName and includedAlbums[self.value] and includedAlbums[self.value].tracks then
				oldTrackListName = self.value
				trackList = includedAlbums[self.value].tracks
				moodPriorityBucketsNonEmpty = includedAlbums[self.value].moodPriorityBucketsNonEmpty
				if WG.Music then
					WG.Music.StopTrack()
				end
			end
		end,
	},
}

local LOOP_BUFFER = 0.015 -- if looping track is this close to the end, go ahead and loop
local MUSIC_VOLUME_DEFAULT = 0.25

local loopTrack = ''
local previousTrack = ''
local haltMusic = false
local looping = false
local musicMuted = false
local musicPaused = false

local initialized = false
local gameStarted = Spring.GetGameFrame() > 0
local myTeam = Spring.GetMyTeamID()
local isSpec = Spring.GetSpectatingState() or Spring.IsReplay()
local defeat = false

local spToggleSoundStreamPaused = Spring.PauseSoundStream
local spAreTeamsAllied = Spring.AreTeamsAllied
local spGetUnitRulesParam = Spring.GetUnitRulesParam

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Mood definitions
local musicType = 'briefing'  -- Current mood or 'custom'
local currentMoodPriority = 1000  -- High number to simplify initial usage

-- Mood evaluation period
local UPDATE_PERIOD = 1
local timeframetimer = 0
local timeframetimer_short = 0

-- War Points: keep track of recent combat activity and quantify it
local warPointsIter = 1  -- Position in circular buffer. 1-indexed.
local warPointsSize = 128  -- Size of circular buffer. Sampling is currently hardcoded but might change later.
local dmgPointsFriendly = {}  -- damage received by allied units per time period
local dmgPointsHostile = {}  -- damage received by enemy units per time period
local deathPointsFriendly = {} -- metal costs of destroyed allied units per time period
local deathPointsHostile = {}  -- metal costs of destroyed enemy units per time period
local warPointsRollover = 2000000000  -- Above counters are all modulo this. 2Bil is a round number near 2^31.
local unitExceptions = include("Configs/snd_music_exception.lua")

local peaceThreshold = 5000 --1000 under old death cost binning. This is substantially less important for hysterisis with the new priority system.
local warThreshold = 30000 --5000 under old death cost binning
local war2Threshold = 300000

-- Updated every UPDATE_PERIOD before evaluating mood changes
local friendliesKilled = 0
local hostilesKilled = 0
local totalKilled = 0

local friendlyDmg = 0
local hostileDmg = 0
local totalDmg = 0

local attritionRatio = 1.0

-- Setters for WG
local function SetWarThreshold(num)
	if num and num >= 0 then
		warThreshold = num
	else
		warThreshold = 5000
	end
end

local function SetPeaceThreshold(num)
	if num and num >= 0 then
		peaceThreshold = num
	else
		peaceThreshold = 1000
	end
end

-- Amend mood-related options here, after we have defined our variables
local optionsPathDynamicMusic = options_path .. '/Dynamic Music'
options.attritionRatioLosing = {
	path = optionsPathDynamicMusic,
	name = 'Attrition Ratio: Losing',
	type = 'number',
	value = 0.4,
	min = 0.1,
	max = 1.0,
	step = 0.05,
	desc = 'Music switches to Losing when recent attrition ratio falls below this value',
	noHotkey = true,
}
options.attritionRatioWinning = {
	path = optionsPathDynamicMusic,
	name = 'Attrition Ratio: Winning',
	type = 'number',
	value = 3.0,
	min = 1.0,
	max = 8.0,
	step = 0.25,
	desc = 'Music switches to Winning when recent attrition ratio rises above this value',
	noHotkey = true,
}
options.warThreshold = {
	path = optionsPathDynamicMusic,
	name = 'War Threshold 1',
	type = 'number',
	value = warThreshold,
	min = 1000,
	max = 100000,
	step = 100,
	desc = 'Music switches to War when recent war points rise above this value',
	noHotkey = true,
	OnChange = function(self, value) SetWarThreshold(value) end,
}
options.war2Threshold = {
	path = optionsPathDynamicMusic,
	name = 'War Threshold 2',
	type = 'number',
	value = war2Threshold,
	min = 20000,
	max = 1000000,
	step = 100,
	desc = 'Music switches to War2 when recent war points rise above this value',
	noHotkey = true,
	OnChange = function (value) war2Threshold = value end,
}

local MOODS = {'peace', 'war', 'war2', 'winning', 'losing', 'briefing', 'victory', 'defeat', 'custom'}
local moodDynamic = {peace=true, war=true, war2=true, winning=true, losing=true}  -- Determines which music moods will change dynamically
setmetatable(moodDynamic, {__index=function(t,k) return false end})  -- Undefined entries return false
local moodEvaluations = {
	peace = function ()
		return (totalDmg + totalKilled) < peaceThreshold
	end,
	war = function ()
		return (totalDmg + totalKilled) >= warThreshold
	end,
	war2 = function ()
		return (totalDmg + totalKilled) >= war2Threshold
	end,
	winning = function ()
		return attritionRatio > options.attritionRatioWinning.value
	end,
	losing = function ()
		return attritionRatio < options.attritionRatioLosing.value
	end,
}
setmetatable(moodEvaluations, {__index = function(t,k) return function() return false end end})  -- Undefined entries return function that returns false

-- Evaluate conditions for each bucket in order.
-- Do not evaluate beyond the bucket of the current mood.
-- When a track ends, reset priority so that later buckets (lower priority moods) can play.
local MOOD_PRIORITY_BUCKETS = {
	--{'briefing', 'victory', 'defeat'},
	{'winning', 'losing'},
	{'war2'},
	{'war'},
	{'peace'},
}

local function CountWarPoints(t, i0, i1, i2)
	-- Double-count the last 15 seconds, i.e. ([i] - [i-15]) + ([i] - [i-60]) == ([i]*2 - [i-15] - [i-60])
	return ((t[i0]*2) - t[i1] - t[i2]) % warPointsRollover
end

local function TickWarPoints()
	-- Run this even if the current mood is not dynamic.
	-- XX: consider Spring.GetTeamStatsHistory(teamID, startTime, endTime) to pick out our three times instead
	local iLast = ((warPointsIter-16) % warPointsSize) + 1  -- Look back 15 periods.
	local iLast2 = ((warPointsIter-61) % warPointsSize) + 1  -- Look back 60 periods.

	-- Update variables for mood evaluations
	friendliesKilled = CountWarPoints(deathPointsFriendly, warPointsIter, iLast, iLast2)
	hostilesKilled = CountWarPoints(deathPointsHostile, warPointsIter, iLast, iLast2)
	totalKilled = friendliesKilled + hostilesKilled
	friendlyDmg = CountWarPoints(dmgPointsFriendly, warPointsIter, iLast, iLast2)
	hostileDmg = CountWarPoints(dmgPointsHostile, warPointsIter, iLast, iLast2)
	totalDmg = friendlyDmg + hostileDmg
	attritionRatio = (hostilesKilled+1)/(friendliesKilled+1)  -- 1 metal is virtually nothing in the ratio, but this simplifies edge cases

	-- Spring.Echo('WAR POINTS: '..totalKilled..', '..totalDmg..'; RATIO '..attritionRatio)

	-- Roll to next index in the circular buffers, continue cumulative sum
	local iNext = (warPointsIter % warPointsSize) + 1
	dmgPointsFriendly[iNext] = dmgPointsFriendly[warPointsIter] % warPointsRollover
	dmgPointsHostile[iNext] = dmgPointsHostile[warPointsIter] % warPointsRollover
	deathPointsFriendly[iNext] = deathPointsFriendly[warPointsIter] % warPointsRollover
	deathPointsHostile[iNext] = deathPointsHostile[warPointsIter] % warPointsRollover
	warPointsIter = iNext
end

local function EvaluateMood()
	-- Only run this if current mood is dynamic. Sets currentMoodPriority and returns what the next mood should be.
	for priority, moods in ipairs(moodPriorityBucketsNonEmpty) do
		if priority > currentMoodPriority then break end
		for _, mood in ipairs(moods) do
			if moodEvaluations[mood]() then
				currentMoodPriority = priority
				return mood
			end
		end
	end
	return nil  -- Don't forget to handle this
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetMusicType()
	return musicType
end

local function StartLoopingTrack(trackInit, trackLoop)
	if not (VFS.FileExists(trackInit) and VFS.FileExists(trackLoop)) then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, "Missing one or both tracks for looping")
	end
	haltMusic = true
	Spring.StopSoundStream()
	musicType = 'custom'
	
	loopTrack = trackLoop
	Spring.PlaySoundStream(trackInit, WG.music_volume or MUSIC_VOLUME_DEFAULT)
	looping = 0.5
end

local function StartTrackDynamic()
	haltMusic = false
	looping = false
	Spring.StopSoundStream()
	WG.music_start_volume = WG.music_volume
	local newTrack = previousTrack

	if musicType == 'custom' then
		musicType = 'peace'
	end
	if #moodPriorityBucketsNonEmpty == 0 then
		Spring.Echo('No dynamic music folders (e.g. peace, war, war2) exist in this collection ("'.. options.albumSelection.value ..'"), no music started')
		return
	end
	if (not gameStarted) then
		musicType = 'briefing'
	end

	local tracks = trackList[musicType]
	local trackCount = #tracks
	if trackCount == 0 then
		Spring.Echo('No music tracks exist in this collection for "'..musicType..'", no music started')
		return
	elseif trackCount == 1 then  -- Don't bother avoiding repetition
		newTrack = tracks[1]
	else  -- Demand a new track
		local rand = math.random(1, trackCount)
		newTrack = tracks[rand]
		if newTrack == previousTrack then
			-- Second random call feels wasteful, but it saves some bookkeeping and we're down from 10 calls on the old widget
			local rand2 = math.random(1, trackCount-1)
			if rand2 >= rand then
				rand2 = rand2 + 1
			end
			newTrack = tracks[rand2]
		end
	end

	Spring.PlaySoundStream(newTrack, WG.music_volume or MUSIC_VOLUME_DEFAULT)
	previousTrack = newTrack -- Slight misnomer, it's the most recently played track (is still playing in this case)
end

local function StartTrack(track)
	if not track then
		StartTrackDynamic()
		return
	end

	haltMusic = false
	looping = false
	Spring.StopSoundStream()
	WG.music_start_volume = WG.music_volume

	musicType = 'custom'
	Spring.PlaySoundStream(track, WG.music_volume or MUSIC_VOLUME_DEFAULT)
	previousTrack = track -- Slight misnomer, it's the most recently played track (is still playing in this case)
end

local function StopTrack(noContinue)
	looping = false
	Spring.StopSoundStream()
	if noContinue then
		haltMusic = true
	else
		haltMusic = false
		StartTrack()
	end
end

local function LateInitialize()
	initialized = true
	math.randomseed(os.clock()* 100)

	local vfsMode = (options.useIncludedTracks.value and VFS.RAW_FIRST) or VFS.RAW
	for name, data in pairs(includedAlbums) do
		local dir = 'sounds/music/' .. data.dir
		local t = {}
		data.tracks = {}
		-- Load tracks from each mood folder
		for _, mood in ipairs(MOODS) do
			local moodDir = dir .. mood .. '/'
			Spring.Echo('Scanning for .ogg files in ' .. moodDir)
			data.tracks[mood] = VFS.DirList(moodDir, '*.ogg', vfsMode)
		end
		-- Filter out MOOD_PRIORITY_BUCKETS to only have moods we have tracks for
		for priority, moods in ipairs(MOOD_PRIORITY_BUCKETS) do
			local bucket = {}
			for _, mood in ipairs(moods) do
				if #data.tracks[mood] > 0 then
					bucket[#bucket+1] = mood
				end
			end
			if #bucket > 0 then
				t[#t+1] = bucket
			end
		end
		data.moodPriorityBucketsNonEmpty = t
	end

	local album = includedAlbums[options.albumSelection.value]
	trackList = album.tracks
	moodPriorityBucketsNonEmpty = album.moodPriorityBucketsNonEmpty

	if Spring.GetGameSeconds() > 1 then
		gameStarted = true
		musicType = EvaluateMood() or 'peace'
		StartTrackDynamic()
	end
end

function widget:Update(dt)
	if not initialized then
		-- these are here to give epicmenu time to set the values properly
		-- (else it's always default at startup)
		LateInitialize()
	end

	-- Operations as fast as possible (framerate?)
	if not musicMuted and WG.music_volume == 0 then
		Spring.StopSoundStream()
		musicMuted = true
		musicPaused = false
	elseif musicMuted and WG.music_volume > 0 then
		musicMuted = false
	end

	-- 33Hz operations
	timeframetimer_short = timeframetimer_short + dt
	if timeframetimer_short > 0.03 then
		timeframetimer_short = 0
		local _, _, paused = Spring.GetGameSpeed()
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = tonumber( ("%.2f"):format(playedTime) )  -- TODO: Investigate why this is doing number->string->number to quantize to hundreths of a second

		-- Maintain loop track
		if looping then
			if looping == 0.5 then
				looping = 1
			elseif playedTime >= totalTime - LOOP_BUFFER then  -- This doesn't look like quantizing playedTime would help at all
				Spring.StopSoundStream()
				Spring.PlaySoundStream(loopTrack, WG.music_volume or MUSIC_VOLUME_DEFAULT)
			end
		end

		-- Pause logic
		if not musicPaused and totalTime > 0 and paused and options.pausemusic.value then -- game got paused with the pausemusic option enabled, so pause the music stream.
			spToggleSoundStreamPaused()
			musicPaused = true
		end
		if musicPaused and (not paused or not options.pausemusic.value) then -- user disabled pausemusic option or game gets unpaused so unpause the music.
			spToggleSoundStreamPaused()
			musicPaused = false
		end
	end

	-- 1Hz operations
	timeframetimer = timeframetimer + dt
	if (timeframetimer > UPDATE_PERIOD) then -- every second
		timeframetimer = 0
		local _, _, paused = Spring.GetGameSpeed()
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		local isTrackFinished = (playedTime >= (totalTime-0.1))  -- Previous widget floored both, I've added a 100ms fudge factor for now
		local inhibit = haltMusic or musicMuted or (paused and options.pausemusic.value)  -- prevents music player from starting again until it is not muted and not "paused" (see: pausemusic option).
		local shouldPlayTrack = isTrackFinished and not inhibit

		if isTrackFinished then
			currentMoodPriority = 1000  -- High number to simplify initial usage
		end

		if not paused then
			TickWarPoints()

			-- if not moodDynamic[musicType] then
			-- 	Spring.Echo('Mood is not dynamic, skipping eval')
			-- elseif inhibit then
			-- 	Spring.Echo('inhibit, skipping eval')
			-- end

			if not inhibit and moodDynamic[musicType] then
				local currentPriority = currentMoodPriority
				local newMood = EvaluateMood()
				if newMood and (newMood ~= musicType) then
					Spring.Echo('Music mood has been re-evaluated from '..musicType..' to '..newMood)
					musicType = newMood
					if currentPriority >= currentMoodPriority then  -- Lower number is more urgent
						-- The situation has escalated (peace->war->war2) or swung (winning<->losing), or no track is playing, so play!
						shouldPlayTrack = true
					end
				end
			end
		end

		if shouldPlayTrack then
			StartTrackDynamic()
		end
	end
end

function widget:GameStart()
	if not gameStarted then
		gameStarted = true
		musicType = EvaluateMood() or 'peace'
		StartTrackDynamic()
	end
end

-- Safety of a heisenbug. (Running game through chobby)
-- see: https://github.com/ZeroK-RTS/Zero-K/commit/0d2398cbc7c05eabda9f25dc3eeb56363793164e#diff-55f47403c24513e47b4350a108deb5f0)
function widget:GameFrame()
	widget:GameStart()
	widgetHandler:RemoveCallIn('GameFrame')
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	-- XX: maybe scale by unit hp/cost?
	-- XX: if ^, then this may be replaceable with calls to engine graphs for Damage Dealt and Damage Received
	if unitExceptions[unitDefID] then return end
	if (UnitDefs[unitDefID] == nil) then return end
	if paralyzer then return end

	if spAreTeamsAllied(unitTeam or 0, myTeam) then
		dmgPointsFriendly[warPointsIter] = dmgPointsFriendly[warPointsIter] + damage
	else
		dmgPointsHostile[warPointsIter] = dmgPointsHostile[warPointsIter] + damage
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	-- XX: this may be replaceable with calls to engine graphs for Value Killed and Value Lost
	if unitExceptions[unitDefID] then return end
	if spGetUnitRulesParam(unitID, "wasMorphedTo") then return end
	local unitCost = UnitDefs[unitDefID].metalCost  -- TODO: replace this with actual unit cost

	if spAreTeamsAllied(teamID or 0, myTeam) then
		deathPointsFriendly[warPointsIter] = deathPointsFriendly[warPointsIter] + unitCost
	else
		deathPointsHostile[warPointsIter] = deathPointsHostile[warPointsIter] + unitCost
	end
end

function widget:TeamDied(team)
	if team == myTeam and not isSpec then
		defeat = true
	end
end

local function PlayGameOverMusic(gameWon)
	if gameWon then
		musicType = 'victory'
	else
		musicType = 'defeat'
	end
	if #trackList[musicType] > 0 then
		WG.music_start_volume = WG.music_volume
		StartTrackDynamic()
	end
end

function widget:GameOver()
	PlayGameOverMusic(not defeat)
	widgetHandler:RemoveCallIn('Update') -- stop music player on game over.
end

function widget:Initialize()
	WG.Music = WG.Music or {}
	WG.Music.StartTrack = StartTrack
	WG.Music.StartLoopingTrack = StartLoopingTrack
	WG.Music.StopTrack = StopTrack
	WG.Music.SetWarThreshold = SetWarThreshold
	WG.Music.SetPeaceThreshold = SetPeaceThreshold
	WG.Music.GetMusicType = GetMusicType
	WG.Music.PlayGameOverMusic = PlayGameOverMusic

	for i=1,warPointsSize do
		dmgPointsFriendly[i] = 0
		dmgPointsHostile[i] = 0
		deathPointsFriendly[i] = 0
		deathPointsHostile[i] = 0
	end
end

function widget:Shutdown()
	Spring.StopSoundStream()
	WG.Music = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
