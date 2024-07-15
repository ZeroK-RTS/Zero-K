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
		author  = "cake, trepan, Smoth, Licho, xponen",
		date    = "Mar 01, 2008, Aug 20 2009, Nov 23 2011",
		license = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true -- loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- see `widget:GameID` below.
-- getting initially same set of tracks during replay
-- continue last album after a reload in case of random option
local seed 
local gameID = Spring.GetGameRulesParam('GameID')
local randomChosen = false
local randomAlbumUseSeed = nil 
local continueAlbum = false
local function SetRandomSeed()
	if seed then
		math.randomseed(seed)
		seed = math.random(1e8)
	end
end

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
local trackListName = 'denny'

local trackList = {
	warTracks       = {},
	peaceTracks     = {},
	briefingTracks  = {},
	victoryTracks   = {},
	defeatTracks    = {},
}

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
		value = trackListName,
		items = {
			{key = 'denny', name = includedAlbums.denny.humanName},
			{key = 'superintendent', name = includedAlbums.superintendent.humanName},
			{key = 'random', name = 'Chosen at random'},
		},
		OnChange = function(self)
			local value = self.value
			if value == 'random' then
				if randomChosen then
					return
				end
				randomChosen = true
				if continueAlbum then
					value = continueAlbum
				else
					if randomAlbumUseSeed then 
						math.randomseed(seed)
					end

					value = trackListName
					local r = math.random(#self.items - 1)

					local item = self.items[r]
					if item.key == 'random' then -- in case the item 'random' is not at last position
						item = self.items[r-1] or self.items[r+1]
					end
					value = item.key
				end
			else
				randomChosen = false
			end
			if value ~= trackListName then
				if includedAlbums[value] and includedAlbums[value].tracks then
					trackListName = value
					trackList = includedAlbums[value].tracks
					if WG.Music then
						WG.Music.StopTrack()
					end
				end
			end

		end,
	},
}

local unitExceptions = include("Configs/snd_music_exception.lua")

local warThreshold = 5000
local peaceThreshold = 1000
local PLAYLIST_FILE = 'sounds/music/playlist.lua'
local LOOP_BUFFER = 0.015 -- if looping track is this close to the end, go ahead and loop
local UPDATE_PERIOD = 1
local MUSIC_VOLUME_DEFAULT = 0.25

local musicType = 'peace'
local dethklok = {} -- keeps track of the number of doods killed in each time frame
local timeframetimer = 0
local timeframetimer_short = 0
local loopTrack = ''
local previousTrack = ''
local previousTrackType = ''
local haltMusic = false
local looping = false
local musicMuted = false
local musicPaused = false

local initialized = false
local gameStarted = Spring.GetGameFrame() > 0
local widgetReloaded = gameStarted

local myTeam = Spring.GetMyTeamID()
local isSpec = Spring.GetSpectatingState() or Spring.IsReplay()
local defeat = false

local spToggleSoundStreamPaused = Spring.PauseSoundStream
local spGetUnitRulesParam = Spring.GetUnitRulesParam

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

local function StartTrack(track)
	if not trackList.peaceTracks then
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
		newTrack = track -- play specified track
		musicType = 'custom'
	else
		local tries = 0
		repeat
			if (not gameStarted) then
				if (#trackList.briefingTracks == 0) then
					return
				end
				SetRandomSeed()
				newTrack = trackList.briefingTracks[math.random(1, #trackList.briefingTracks)]
				musicType = "briefing"
			elseif musicType == 'peace' then
				if (#trackList.peaceTracks == 0) then
					return
				end
				SetRandomSeed()
				newTrack = trackList.peaceTracks[math.random(1, #trackList.peaceTracks)]
			elseif musicType == 'war' then
				if (#trackList.warTracks == 0) then
					return
				end
				SetRandomSeed()
				newTrack = trackList.warTracks[math.random(1, #trackList.warTracks)]
			end
			tries = tries + 1
		until newTrack ~= previousTrack or tries >= 10
	end
	previousTrack = newTrack
	Spring.PlaySoundStream(newTrack,WG.music_volume or MUSIC_VOLUME_DEFAULT)
	
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
	if not initialized then
		initialized = true
		-- these are here to give epicmenu time to set the values properly
		-- (else it's always default at startup)
		
		local vfsMode = (options.useIncludedTracks.value and VFS.RAW_FIRST) or VFS.RAW
		for name, data in pairs(includedAlbums) do
			local dir = 'sounds/music/' .. data.dir
			data.tracks = {
				warTracks       = VFS.DirList(dir .. 'war/', '*.ogg', vfsMode),
				peaceTracks     = VFS.DirList(dir .. 'peace/', '*.ogg', vfsMode),
				briefingTracks  = VFS.DirList(dir .. 'briefing/', '*.ogg', vfsMode),
				victoryTracks   = VFS.DirList(dir .. 'victory/', '*.ogg', vfsMode),
				defeatTracks    = VFS.DirList(dir .. 'defeat/', '*.ogg', vfsMode),
			}
		end
		if gameID then
			-- update the tracklistName case: reload, random chosen at start
			widget:GameID(gameID)
		else
			math.randomseed(os.clock()* 100)
		end
		trackList = includedAlbums[trackListName].tracks
	elseif randomAlbumUseSeed == nil then
		-- case replay: widget:gameID() hasn't been triggered yet
		randomAlbumUseSeed = false
		continueAlbum = false
	end
	
	timeframetimer_short = timeframetimer_short + dt
	if timeframetimer_short > 0.03 then
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = tonumber( ("%.2f"):format(playedTime) )
		if looping then
			if looping == 0.5 then
				looping = 1
			elseif playedTime >= totalTime - LOOP_BUFFER then
				Spring.StopSoundStream()
				Spring.PlaySoundStream(loopTrack,WG.music_volume or MUSIC_VOLUME_DEFAULT)
			end
		end
		timeframetimer_short = 0
	end
	if not musicMuted and WG.music_volume == 0 then
		Spring.StopSoundStream()
		musicMuted = true
		musicPaused = false
	elseif musicMuted and WG.music_volume > 0 then
		musicMuted = false
	end
	timeframetimer = timeframetimer + dt
	if (timeframetimer > UPDATE_PERIOD) then -- every second
		timeframetimer = 0
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
		
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = math.floor(playedTime)
		totalTime = math.floor(totalTime)
		local _, _, paused = Spring.GetGameSpeed()
		if ( previousTrackType == "peace" and musicType == 'war' )
		 or (playedTime >= totalTime)	-- both zero means track stopped
		 and not(haltMusic or looping) then
			previousTrackType = musicType
			if not musicMuted and not (paused and options.pausemusic.value) then -- prevents music player from starting again until it is not muted and not "paused" (see: pausemusic option).
				StartTrack()
			end
		end
		if not musicPaused and totalTime > 0 and paused and options.pausemusic.value then -- game got paused with the pausemusic option enabled, so pause the music stream.
			spToggleSoundStreamPaused()
			musicPaused = true
		end
		if musicPaused and (not paused or not options.pausemusic.value) then -- user disabled pausemusic option or game gets unpaused so unpause the music.
			spToggleSoundStreamPaused()
			musicPaused = false
		end
	end
end
function widget:GameID(id)
	-- Idempotence issue:
	-- -when on replay we can't know the id until player connect, meanwhile the briefing track (if any) is playing and is not following the randomseed sequence
	-- -when not on replay the GameID trigger after first round of Update
	-- In any case option.OnChange got triggered before
	gameID = id
	seed = tonumber('0x' .. id)
	-- when number given is too big, the resulting sequence is the same / when difference between numbers is too small, the resulting number is the same
	while seed > 1e8 do
		seed = seed^0.8
	end
	if options.albumSelection.value == 'random' then
		if Spring.GetSoundStreamTime() < 0.5 then -- we don't change current album if a briefing track has started
			randomChosen = false
			randomAlbumUseSeed = true
			options.albumSelection:OnChange()
		end
	end
	randomAlbumUseSeed = false
	continueAlbum = false
end
function widget:GameStart()
	if not gameStarted then
		gameStarted = true
		previousTrackType = musicType
		musicType = "peace"
		if Spring.GetSoundStreamTime() > 0 then -- if there's a briefing track playing, stop it and start peace track.
			Spring.StopSoundStream()
		end
	end
end

-- Safety of a heisenbug. (Running game through chobby)
-- see: https://github.com/ZeroK-RTS/Zero-K/commit/0d2398cbc7c05eabda9f25dc3eeb56363793164e#diff-55f47403c24513e47b4350a108deb5f0)
function widget:GameFrame()
	widget:GameStart()
	widgetHandler:RemoveCallIn('GameFrame')
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if unitExceptions[unitDefID] then
		return
	end
	
	if (damage < 1.5) then return end
	
	if (UnitDefs[unitDefID] == nil) then return end
		
	if paralyzer then
		return
	else
		dethklok[1] = dethklok[1] + damage
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitExceptions[unitDefID] then
		return
	end
	if spGetUnitRulesParam(unitID, "wasMorphedTo") then
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
	dethklok[1] = dethklok[1] + unitWorth
end

function widget:TeamDied(team)
	if team == myTeam and not isSpec then
		defeat = true
	end
end

local function PlayGameOverMusic(gameWon)
	local track
	if gameWon then
		if #trackList.victoryTracks <= 0 then
			return
		end
		SetRandomSeed()
		track = trackList.victoryTracks[math.random(1, #trackList.victoryTracks)]
		musicType = "victory"
	else
		if #trackList.defeatTracks <= 0 then
			return
		end
		SetRandomSeed()
		track = trackList.defeatTracks[math.random(1, #trackList.defeatTracks)]
		musicType = "defeat"
	end
	looping = false
	Spring.StopSoundStream()
	Spring.PlaySoundStream(track,WG.music_volume or MUSIC_VOLUME_DEFAULT)
	WG.music_start_volume = WG.music_volume
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
	
	for i = 1, 30, 1 do
		dethklok[i]=0
	end
end

function widget:Shutdown()
	Spring.StopSoundStream()
	WG.Music = nil
end
-- save up current album to be continued in case of /luaui reload or simple widget reload
function widget:GetConfigData()
	return {currentGameAlbum = {gameID = gameID, trackListName =  trackListName}}
end
function widget:SetConfigData(data)
	if not gameID then -- no reload occurred (or replay case before user connect), nothing to do
		return
	end
	local current = data.currentGameAlbum
	if current and current.gameID == gameID then
		continueAlbum = current.trackListName
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
