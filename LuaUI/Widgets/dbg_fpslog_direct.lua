function widget:GetInfo()
  return {
    name      = "Widget_Fps_Log",
    desc      = "Some random logging",
    author    = "Licho",
    date      = "2013",
    layer     = 0,
    enabled   = true,  --  loaded by default
  }
end

local ACTIVE = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local EXTRA_INITIALIZE_TIME = 30*10
local LOG_START = 30*15
local LOG_END = LOG_START + 30*40
local EXIT_TIME = LOG_END + 30*1

local updateGaps = {}
local frameGaps = {}

local initialized = false
local extraInitialized = false
local dataFilePath = Spring.GetConfigString("benchmark_file_name")
local benchmarkName = Spring.GetConfigString("benchmark_run_name")

local spGetTimer = Spring.GetTimer 
local spDiffTimers = Spring.DiffTimers
local spGetAllUnits = Spring.GetAllUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Processing

local function ProcessGapList(gaps)
	local ranges = {}
	local gapSum = 0
	local gapCount = #gaps
	if gapCount < 1 then
		return
	end
	
	local gapMin, gapMax = gaps[1], gaps[1]
	for i = 1, gapCount do
		gapSum = gapSum + gaps[i]
		gapMin = math.min(gapMin, gaps[i])
		gapMax = math.max(gapMax, gaps[i])
		if gaps[i] > 0 then
			local fps = 1/gaps[i]
			local range = math.min(15, math.max(0, math.floor(fps/3))) + 1
			ranges[range] = (ranges[range] or 0) + 1
		end
	end
	local average = gapSum/gapCount
	
	local variance = 0
	for i = 1, gapCount do
		variance = variance + (average - gaps[i])*(average - gaps[i])
	end
	variance = variance/gapCount
	
	return ranges, average, math.sqrt(variance), gapMin, gapMax
end

local function ProcessAndWriteData()
	local rangeUpdate, averageUpdate, sdevUpdate, minUpdate, maxUpdate = ProcessGapList(updateGaps)
	local rangeFrame, averageFrame, sdevFrame, minFrame, maxFrame = ProcessGapList(frameGaps)
	
	local output = "\n" .. benchmarkName .. "," .. averageUpdate .. "," .. sdevUpdate .. "," .. minUpdate .. "," .. maxUpdate
	for i = 1, 16 do
		output = output .. "," .. (rangeUpdate[i] or 0)
	end
	
	output = output .. "," .. averageFrame .. "," .. sdevFrame .. "," .. minFrame .. "," .. maxFrame
	for i = 1, 16 do
		output = output .. "," .. (rangeFrame[i] or 0)
	end
	
	local units = spGetAllUnits()
	output = output .. "," .. #units
	
	local dataFile = io.open(dataFilePath, "a")
	dataFile:write(output)
	dataFile:close()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Logging

function widget:Update(dt)
	if not ACTIVE then
		return
	end

	local frame = Spring.GetGameFrame() 
	if (frame > 0 and not initialized) or (frame > EXTRA_INITIALIZE_TIME and not extraInitialized) then
		-- Set camera in case different engines have different default locations
		Spring.SetCameraState({
			px = 3072,
			py = 91.71875,
			pz = 3596,
			flipped = -1,
			dx = 0,
			dy = -0.8945,
			dz = -0.4472,
			name = "ta",
			zscale = 0.5,
			height = 3500,
			mode = 1,
		}, 0)
		
		Spring.SendCommands({"specteam 1"})
		Spring.WarpMouse(60, 100)
		
		extraInitialized = initialized
		initialized = true
	end
	
	if frame > LOG_START and frame < LOG_END then
		updateGaps[#updateGaps + 1] = dt
	end
	
	if frame > LOG_END and not debugView then
		Spring.SendCommands("debuginfo profiling")
		Spring.SendCommands("gameinfo")
		Spring.SendCommands("debug")
		debugView = true
	end
	if (frame > EXIT_TIME) then
		ProcessAndWriteData()
		Spring.SendCommands("quitforce")
	end
end

local lastFrameTimer
function widget:GameFrame(frame)
	if not ACTIVE then
		return
	end

	if frame >= LOG_START and frame < LOG_END then
		local newTimer = spGetTimer()
		if lastFrameTimer then
			frameGaps[#frameGaps + 1] = Spring.DiffTimers(newTimer, lastFrameTimer)
		end
		lastFrameTimer = newTimer
	end
end
