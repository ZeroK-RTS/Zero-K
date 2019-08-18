--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:		gui_music.lua
--	brief:	yay music
--	author:	cake
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name	= "Music Player",
		desc	= "Plays music based on situation",
		author	= "cake, trepan, Smoth, Licho, xponen",
		date	= "Mar 01, 2008, Aug 20 2009, Nov 23 2011",
		license	= "GNU GPL, v2 or later",
		layer	= 0,
		enabled	= true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
}

local unitExceptions = include("Configs/snd_music_exception.lua")

local windows = {}

local warThreshold = 5000
local peaceThreshold = 1000
local PLAYLIST_FILE = 'sounds/music/playlist.lua'
local LOOP_BUFFER = 0.015	-- if looping track is this close to the end, go ahead and loop
local UPDATE_PERIOD = 1

local musicType = 'peace'
local dethklok = {} -- keeps track of the number of doods killed in each time frame
local timeframetimer = 0
local timeframetimer_short = 0
local loopTrack = ''
local previousTrack = ''
local previousTrackType = ''
local newTrackWait = 1000
local numVisibleEnemy = 0
local fadeVol
local curTrack	= "no name"
local songText	= "no name"
local haltMusic = false
local looping = false
local paused = false
local lastTrackTime = -1

local warTracks, peaceTracks, briefingTracks, victoryTracks, defeatTracks

local firstTime = false
local wasPaused = false
local firstFade = true
local initSeed = 0
local initialized = false
local gameStarted = Spring.GetGameFrame() > 0
local gameOver = false

local myTeam = Spring.GetMyTeamID()
local isSpec = Spring.GetSpectatingState() or Spring.IsReplay()
local defeat = false

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
	
	curTrack = trackInit
	loopTrack = trackLoop
	Spring.PlaySoundStream(trackInit, WG.music_volume or 0.5)
	looping = 0.5
end

local function StartTrack(track)
	if not peaceTracks then
		Spring.Echo("Missing peaceTracks file, no music started")
		return
	end

	haltMusic = false
	looping = false
	Spring.StopSoundStream()
	
	local newTrack = previousTrack
	if musicType == 'custom' then
		previousTrackType = "peace"
		musicType = "peace"
	end
	if track then
		newTrack = track	-- play specified track
		musicType = 'custom'
	else
		local tries = 0
		repeat
			if (not gameStarted) then
				if (#briefingTracks == 0) then return end
				newTrack = briefingTracks[math.random(1, #briefingTracks)]
				musicType = "briefing"
			elseif musicType == 'peace' then
				if (#peaceTracks == 0) then return end
				newTrack = peaceTracks[math.random(1, #peaceTracks)]
			elseif musicType == 'war' then
				if (#warTracks == 0) then return end
				newTrack = warTracks[math.random(1, #warTracks)]
			end
			tries = tries + 1
		until newTrack ~= previousTrack or tries >= 10
	end
	-- for key, val in pairs(oggInfo) do
		-- Spring.Echo(key, val)
	-- end
	firstFade = false
	previousTrack = newTrack
	
	-- if (oggInfo.comments.TITLE and oggInfo.comments.TITLE) then
		-- Spring.Echo("Song changed to: " .. oggInfo.comments.TITLE .. " By: " .. oggInfo.comments.ARTIST)
	-- else
		-- Spring.Echo("Song changed but unable to get the artist and title info")
	-- end
	curTrack = newTrack
	Spring.PlaySoundStream(newTrack,WG.music_volume or 0.5)
	
	WG.music_start_volume = WG.music_volume
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

function widget:Update(dt)
	if gameOver then
		return
	end
	if not initialized then
		math.randomseed(os.clock()* 100)
		initialized=true
		-- these are here to give epicmenu time to set the values properly
		-- (else it's always default at startup)
		if VFS.FileExists(PLAYLIST_FILE, VFS.RAW_FIRST) then
			local tracks = VFS.Include(PLAYLIST_FILE, nil, VFS.RAW_FIRST)
			warTracks = tracks.war
			peaceTracks = tracks.peace
			briefingTracks = tracks.briefing
			victoryTracks = tracks.victory
			defeatTracks = tracks.defeat
		end
		
		local vfsMode = (options.useIncludedTracks.value and VFS.RAW_FIRST) or VFS.RAW
		warTracks	= warTracks or VFS.DirList('sounds/music/war/', '*.ogg', vfsMode)
		peaceTracks	= peaceTracks or VFS.DirList('sounds/music/peace/', '*.ogg', vfsMode)
		briefingTracks  = briefingTracks or VFS.DirList('sounds/music/briefing/', '*.ogg', vfsMode)
		victoryTracks	= victoryTracks or VFS.DirList('sounds/music/victory/', '*.ogg', vfsMode)
		defeatTracks	= defeatTracks or VFS.DirList('sounds/music/defeat/', '*.ogg', vfsMode)
	end
	
	timeframetimer_short = timeframetimer_short + dt
	if timeframetimer_short > 0.03 then
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = tonumber( ("%.2f"):format(playedTime) )
		paused = (playedTime == lastTrackTime)
		lastTrackTime = playedTime
		if looping then
			if looping == 0.5 then
				looping = 1
			elseif playedTime >= totalTime - LOOP_BUFFER then
				Spring.StopSoundStream()
				Spring.PlaySoundStream(loopTrack,WG.music_volume or 0.5)
			end
		end
		timeframetimer_short = 0
	end
	
	timeframetimer = timeframetimer + dt
	if (timeframetimer > UPDATE_PERIOD) then	-- every second
		timeframetimer = 0
		newTrackWait = newTrackWait + 1
		local PlayerTeam = Spring.GetMyTeamID()
		numVisibleEnemy = 0
		local doods = Spring.GetVisibleUnits()
		for i=1,#doods do
			if (Spring.IsUnitAllied(doods[i]) ~= true) then
				numVisibleEnemy = numVisibleEnemy + 1
			end
		end
			
		local totalKilled = 0
		for i = 1, 10, 1 do --calculate the first half of the table (1-15)
			totalKilled = totalKilled + (dethklok[i] * 2)
		end
		
		for i = 11, 20, 1 do -- calculate the second half of the table (16-45)
			totalKilled = totalKilled + dethklok[i]
		end
		
		for i = 20, 1, -1 do -- shift value(s) to the end of table
			dethklok[i+1] = dethklok[i]
		end
		dethklok[1] = 0 -- empty the first row
		
		if (musicType == 'war' or musicType == 'peace') then
			if (totalKilled >= warThreshold) then
				musicType = 'war'
			elseif (totalKilled <= peaceThreshold) then
				musicType = 'peace'
			end
		end
		
		if (not firstTime) then
			StartTrack()
			firstTime = true -- pop this cherry
		end
		
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = math.floor(playedTime)
		totalTime = math.floor(totalTime)
		--Spring.Echo(playedTime, totalTime)
		
		--Spring.Echo(playedTime, totalTime, newTrackWait)
		
		--if((totalTime - playedTime) <= 6 and (totalTime >= 1) ) then
			--Spring.Echo("time left:", (totalTime - playedTime))
			--Spring.Echo("volume:", (totalTime - playedTime)/6)
			--if ((totalTime - playedTime)/6 >= 0) then
			--	Spring.SetSoundStreamVolume((totalTime - playedTime)/6)
			--else
			--	Spring.SetSoundStreamVolume(0.1)
			--end
		--elseif(playedTime <= 5 )then--and not firstFade
			--Spring.Echo("time playing:", playedTime)
			--Spring.Echo("volume:", playedTime/5)
			--Spring.SetSoundStreamVolume( playedTime/5)
		--end
		--Spring.Echo(previousTrackType, musicType)
		if ( previousTrackType == "peace" and musicType == 'war' )
		 or (playedTime >= totalTime)	-- both zero means track stopped
		 and not(haltMusic or looping) then
			previousTrackType = musicType
			StartTrack()
			
			--Spring.Echo("Track: " .. newTrack)
			newTrackWait = 0
		end
		local _, _, paused = Spring.GetGameSpeed()
		if (paused ~= wasPaused) and options.pausemusic.value then
			Spring.PauseSoundStream()
			wasPaused = paused
		end
	end
end

function widget:GameStart()
	if not gameStarted then
		gameStarted = true
		previousTrackType = musicType
		musicType = "peace"
		StartTrack()
	end
	
	--Spring.Echo("Track: " .. newTrack)
	newTrackWait = 0
end

-- Safety of a heisenbug
function widget:GameFrame()
	widget:GameStart()
	widgetHandler:RemoveCallIn('GameFrame')
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if unitExceptions[unitDefID] then
		return
	end
	
	if (damage < 1.5) then return end
	local PlayerTeam = Spring.GetMyTeamID()
	
	if (UnitDefs[unitDefID] == nil) then return end
		
	if paralyzer then
		return
	else
		if (teamID == PlayerTeam) then
			damage = damage * 1.5
		end
		local multifactor = 1
		if (numVisibleEnemy > 3) then
			multifactor = math.log(numVisibleEnemy)
		end
		dethklok[1] = dethklok[1] + (damage * multifactor);
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitExceptions[unitDefID] then
		return
	end
	local unitWorth = 50
	if (UnitDefs[unitDefID].metalCost > 500) then
		unitWorth = 200
	end
	if (UnitDefs[unitDefID].metalCost > 1000) then
		unitWorth = 300
	end
	if (UnitDefs[unitDefID].metalCost > 3000) then
		unitWorth = 500
	end
	if (UnitDefs[unitDefID].metalCost > 8000) then
		unitWorth = 700
	end
	if (teamID == PlayerTeam) then
		unitWorth = unitWorth * 1.5
	end
	local multifactor = 1
	if (numVisibleEnemy > 3) then
		multifactor = math.log(numVisibleEnemy)
	end
	dethklok[1] = dethklok[1] + (unitWorth*multifactor);
end

function widget:TeamDied(team)
	if team == myTeam and not isSpec then
		defeat = true
	end
end

local function PlayGameOverMusic(gameWon)
	local track
	if gameWon then
		if #victoryTracks <= 0 then return end
		track = victoryTracks[math.random(1, #victoryTracks)]
		musicType = "victory"
	else
		if #defeatTracks <= 0 then return end
		track = defeatTracks[math.random(1, #defeatTracks)]
		musicType = "defeat"
	end
	looping = false
	Spring.StopSoundStream()
	Spring.PlaySoundStream(track,WG.music_volume or 0.5)
	WG.music_start_volume = WG.music_volume
end

function widget:GameOver()
	PlayGameOverMusic(not defeat)
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

	-- Spring.Echo(math.random(), math.random())
	-- Spring.Echo(os.clock())
 
	-- for TrackName,TrackDef in pairs(peaceTracks) do
		-- Spring.Echo("Track: " .. TrackDef)
	-- end
	--math.randomseed(os.clock()* 101.01)--lurker wants you to burn in hell rgn
	-- for i=1,20 do Spring.Echo(math.random()) end
	
	for i = 1, 30, 1 do
		dethklok[i]=0
	end
end

function widget:Shutdown()
	Spring.StopSoundStream()
	WG.Music = nil
	
	for i=1,#windows do
		(windows[i]):Dispose()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
