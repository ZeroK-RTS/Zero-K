
function widget:GetInfo()
  return {
    name      = "Frame Gap Logger",
    desc      = "Logs the time between frames.",
    author    = "Google Frog",
    date      = "10 June, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local logging = true
local lastTime = false

function widget:TextCommand(command) 
	if command == "startlog" then
		logging = true
		lastTime = false
	elseif command == "endlog" then
		logging = false
	end
end

function widget:GameFrame(n)
	if logging then
		local thisTime = Spring.GetTimer()
		if lastTime then
			local ms = Spring.DiffTimers(thisTime, lastTime, true)
			if ms > 100 then
				Spring.Log(widget:GetInfo().name, LOG.WARNING,"Frame gap: " ..( ms or "nil"))
			end
		end
		lastTime = thisTime
	end
end