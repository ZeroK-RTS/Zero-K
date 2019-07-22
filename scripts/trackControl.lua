-- TODO: CACHE INCLUDE FILE
local wheels
local smallSpeed
local smallAccel
local smallDecel
local largeSpeed
local largeAccel
local largeDecel
local tracks
local trackCount
local signal
local trackPeriod

local currentTrack = 1
local isMoving = false

function InitiailizeTrackControl(intData)
	wheels = intData.wheels or {large = {}, small = {}}
	smallSpeed = intData.smallSpeed or math.rad(360)
	smallAccel = intData.smallAccel or math.rad(50)
	smallDecel = intData.smallDecel or math.rad(100)
	largeSpeed = intData.largeSpeed or math.rad(360)
	largeAccel = intData.largeAccel or math.rad(50)
	largeDecel = intData.largeDecel or math.rad(100)
	tracks = intData.tracks or {}
	signal = intData.signal
	trackPeriod = intData.trackPeriod
	
	trackCount = #tracks
	for i = 2, trackCount do
		Hide(tracks[i])
	end
end

function TrackControlStartMoving()
	isMoving = true
	Signal(signal)
	SetSignalMask(signal)

	for i = 1, #wheels.small do
		Spin (wheels.small[i], x_axis, smallSpeed, smallAccel)
	end
	for i = 1, #wheels.large do
		Spin (wheels.large[i], x_axis, largeSpeed, largeDecel)
	end
	
	while isMoving do
		Hide(tracks[currentTrack])
		currentTrack = (currentTrack == trackCount) and 1 or (currentTrack + 1)
		Show(tracks[currentTrack])
		Sleep(trackPeriod)
	end

	for i = 1, #wheels.small do
		StopSpin (wheels.small[i], x_axis, smallDecel)
	end
	for i = 1, #wheels.large do
		StopSpin (wheels.large[i], x_axis, largeDecel)
	end
end

function TrackControlStopMoving()
	isMoving = false
end
