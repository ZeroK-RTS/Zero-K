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
options_order = { 'camSpeed'}
options = {
	camSpeed = {
		name = 'Camera Smoothness',
		type = "number", 
		value = 0.25, 
		min = 0,
		max = 1,
		step = 0.01,
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetCameraState          = Spring.GetCameraState
local spSetCameraState          = Spring.SetCameraState
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Update(dt)
	if WG.Cutscene and WG.Cutscene.IsInCutscene() then
		return
	end
	local cs = spGetCameraState()
	spSetCameraState(cs, options.camSpeed.value)
end 