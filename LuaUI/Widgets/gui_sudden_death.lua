function widget:GetInfo()
	return {
		name = "Sudden Death",
		desc = "Draws sudden death circle.",
		author = "GoogleFrog",
		date = "24 Hune 2023",
		license = "GPL v3.0+",
		layer = 0,
		enabled = true
	}
end

options_path = 'Settings/Interface/Map/Sudden Death'
options_order = {"color", "thickness"}
options = {
	color = {
		name = "Sudden death color",
		type = "colors",
		value = {1, 0.2, 0.2, 0.8},
	},
	thickness = {
		name = "Line thickness",
		type = "number",
		value = 7,
		min = 1,
		max = 10,
		step = 0.1,
	},
}

local LEAD_IN_FRAMES = 60*30

local suddenDeathFrame = false
local fadeTimer = false

local spGetCameraState     = Spring.GetCameraState
local spGetGroundHeight    = Spring.GetGroundHeight

local glLineWidth          = gl.LineWidth
local glColor              = gl.Color
local glDrawGroundCircle   = gl.DrawGroundCircle

local function GetCameraHeight()
	local cs = spGetCameraState()
	local gy = spGetGroundHeight(cs.px, cs.pz)
	local testHeight = cs.py - gy
	if cs.name == "ta" then
		testHeight = cs.height - gy
	end
	return testHeight
end

local function GetThicknessFactor()
	local height = GetCameraHeight()
	if height < 200 then
		return 1
	end
	return 200 / (200 + height) + 0.5
end

function widget:Initialize()
	if not Spring.GetGameRulesParam("suddenDeathFrames") then
		widgetHandler:RemoveWidget()
	end
	suddenDeathFrame = Spring.GetGameRulesParam("suddenDeathFrames")
end

function widget:DrawWorldPreUnit()
	if not suddenDeathFrame then
		return
	end
	local frame = Spring.GetGameFrame()
	if frame + LEAD_IN_FRAMES < suddenDeathFrame then
		return
	end
	
	local midRadius = 120 * (1 - (Spring.GetGameRulesParam("suddenDeathProgress") or 0))
	if midRadius < 0 then
		return
	end
	local ox = Spring.GetGameRulesParam("suddenDeathOriginX")
	local oz = Spring.GetGameRulesParam("suddenDeathOriginZ")
	
	local thickness = options.thickness.value * GetThicknessFactor()
	local preProgress = math.min(1, 1 - (suddenDeathFrame - frame) / LEAD_IN_FRAMES)
	local alpha = options.color.value[4] * preProgress
	if fadeTimer then
		local diff = Spring.DiffTimers(Spring.GetTimer(), fadeTimer)
		if diff > 0.75 then
			suddenDeathFrame = false
			return
		end
		alpha = alpha * (0.75 - diff) / 0.75
	end
	
	glLineWidth(thickness)
	glColor(options.color.value[1], options.color.value[2], options.color.value[3], alpha)
	glDrawGroundCircle(ox, 0, oz, midRadius, math.max(12, midRadius))
	if preProgress < 0.97 then
		glDrawGroundCircle(ox, 0, oz, midRadius * preProgress, math.max(12, midRadius))
	elseif preProgress < 1 then
		local prop = (preProgress - 0.97) / 0.03
		prop = (prop < 0.5 and prop*prop*2) or (1 - (-2 * prop + 2) * (-2 * prop + 2) / 2)
		local radiusOne = Spring.GetGameRulesParam("suddenDeathStartDistance")
		local radiusTwo = midRadius * preProgress
		local radiusAverage = prop* radiusOne + (1 - prop) * radiusTwo
		glDrawGroundCircle(ox, 0, oz, radiusAverage, math.max(12, radiusAverage))
	end
	
	if preProgress < 1 then
		return
	end
	local radius = Spring.GetGameRulesParam("suddenDeathRadius")
	if (not radius) or radius < 0 or Spring.IsGUIHidden()then
		return
	end
	glDrawGroundCircle(ox, 0, oz, radius, math.max(12, radius))
	glLineWidth(thickness * 0.5)
end

function widget:GameOver()
	fadeTimer = Spring.GetTimer()
end

