
function widget:GetInfo()
  return {
    name      = "Frame Gap Logger",
    desc      = "Logs the time between frames.",
    author    = "Google Frog",
    date      = "10 June, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

local logging = false
local updateLogging = false
local lastTime = false
local gaps = {}

function widget:TextCommand(command)
	if command == "startlog" then
		updateLogging = true
	elseif command == "endlog" then
		updateLogging = false
	end
	if command == "startframelog" then
		logging = true
		lastTime = false
	elseif command == "endframelog" then
		logging = false
	end
end

function widget:Update(dt)
	if updateLogging then
		Spring.Log(widget:GetInfo().name, LOG.WARNING,"Update gap: " ..( dt or "nil"))
		lastTime = thisTime
	end
end

function widget:GameFrame(n)
	if logging then
		local thisTime = Spring.GetTimer()
		if lastTime then
			local ms = Spring.DiffTimers(thisTime, lastTime, true)
			if ms > 40 then
				Spring.Log(widget:GetInfo().name, LOG.WARNING,"Frame gap: " ..( ms or "nil"))
			end
		end
		lastTime = thisTime
	end
end
