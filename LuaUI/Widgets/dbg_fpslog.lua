function widget:GetInfo()
  return {
    name      = "FPS Log",
    desc      = "Logs FPS at regular intervals and writes to a textfile",
    author    = "knorke, modified by KingRaptor",
    date      = "2011",
    license   = "dfgh",
    layer     = 0,
    enabled   = false  --  loaded by default
  }
end

local GetGameFrame = Spring.GetGameFrame

local PERIOD = 15	-- screenframes

local frames = {}
local loggedi = 0
local gameStart = Spring.GetGameSeconds()>0

local screenFrame = 0
local screenFrameLifetime = 0
local timeInterval = 0

function widget:Update(dt)
	if not gameStart then return end
	screenFrame = screenFrame + 1
	timeInterval = timeInterval + dt
	if screenFrame == PERIOD then
		screenFrameLifetime = screenFrameLifetime + screenFrame
		local time_spend_per_frame = timeInterval / PERIOD
		local fps = 1 / time_spend_per_frame
		frames[loggedi] = {GetGameFrame(), fps}
		loggedi = loggedi + 1
		screenFrame = 0
		timeInterval = 0
	end
end

function widget:GameStart()
	gameStart = true
end

function writeFrames (fn)
	Spring.Echo ("---writing fps---")
	file = io.open (fn, "w")
	if (file== nil) then Spring.Echo ("could not open file for writing!") return end
	for i=1, #frames do
		file:write (frames[i][1] .. "\t" .. frames[i][2] .. "\n")
		--file:write (i*frameStep .. "=" .. frames[i] .. "\n")
	end
	file:flush()
	file:close()
end

function widget:AddConsoleLine(msg, priority)
	if (string.find (msg, "WRITE FPS") ~= nil) then
		writeFrames ("fpslog.txt")
	end
end

function widget:GameOver()
	writeFrames ("fpslog.txt")
end
