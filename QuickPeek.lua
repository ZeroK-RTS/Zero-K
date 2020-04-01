
function widget:GetInfo()
	return {
		name      = 'Quick peek',
		desc      = 'have a quick look at most recent screen message by pressing CAPSLOCK',
		version   = "1.1",
		author    = 'Jools',
		date      = 'Jan, 2014',
		license   = 'GNU GPL v2',
		layer     = 1,
		enabled   = true,
	}
end

local markFrame = 0
local mx, my, mz
local cx,cy,cz
local TIMEOUT = 7 -- in seconds
local CAMTIME = 0.05 -- in seconds
local Echo = Spring.Echo

function widget:MapDrawCmd(playerID, cmdType, px, py, pz, labeltext)
	if cmdType == "point" or cmdType == "label"  then
		markFrame = Spring.GetGameFrame()
		mx,my,mz = px, py, pz
	end
end

function widget:KeyPress(key, mods, isRepeat)
	if key == 301 and (not isRepeat) and markFrame and (not cx) then
		cx,cy,cz = Spring.GetCameraPosition()
		Spring.SetCameraTarget(mx, my, mz)
		return true
	end
	return false
end

function widget:KeyRelease(key) 
	if key  == 301 and cx then
		Spring.SetCameraTarget(cx,cy,cz,CAMTIME)
		cx,cy,cz = nil,nil,nil
		return true
	end
	
	return false
end

function widget:GameFrame(frame)
	if markFrame and frame > markFrame + TIMEOUT*30 then
		markFrame = nil
	end
end

	
	