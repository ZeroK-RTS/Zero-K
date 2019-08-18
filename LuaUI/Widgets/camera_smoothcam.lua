local versionNumber = "0.5"

function widget:GetInfo()
	return {
		name      = "SmoothCam",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Moves camera smoothly",
		author    = "very_bad_soldier",
		date      = "August, 8, 2010",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		handler   = true,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
----------------------------Configuration---------------------------------------
options_path = 'Settings/Camera'
options_order = { 'camSpeed', 'tiltZoom'}
options = {
	camSpeed = {
		name = 'Camera Smoothness',
		type = "number",
		value = 0.30,
		min = 0,
		max = 1,
		step = 0.01,
		simpleMode = true,
		everyMode = true,
	},
	tiltZoom = {
		name = 'Tilt Zoom',
		type = "number",
		value = 0,
		min = 0,
		max = 1,
		step = 0.01,
		advanced = true,
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetCameraState          = Spring.GetCameraState
local spSetCameraState          = Spring.SetCameraState
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local newHeight = 0
local maxCameraHeight = 0.7*math.max(Game.mapX, Game.mapY)*625

local smoothCamDelay
function WG.DelaySmoothCam(seconds)
	smoothCamDelay = math.max(smoothCamDelay or 0, seconds)
end

function widget:Update(dt)
	if (WG.Cutscene and WG.Cutscene.IsInCutscene()) or WG.COFC_Enabled then
		return
	end
	if smoothCamDelay then
		smoothCamDelay = smoothCamDelay - dt
		if smoothCamDelay < 0 then
			smoothCamDelay = false
		else
			return
		end
	end
	local state = spGetCameraState()
	if state.mode ~= 1 then
		-- Only apply to default camera.
		return
	end
	if options.tiltZoom.value ~= 0 then
		if math.abs(state.height - newHeight) > 50 then
			newHeight = newHeight + (state.height - newHeight)*0.18
		end
		local heightScale = math.max(0, math.min(1, (maxCameraHeight - newHeight)/maxCameraHeight))
		state.angle = math.pi * options.tiltZoom.value * heightScale
	end
	spSetCameraState(state, options.camSpeed.value)
end
