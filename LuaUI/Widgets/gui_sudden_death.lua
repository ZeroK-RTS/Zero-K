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
		value = 8,
		min = 1,
		max = 10,
		step = 0.1,
	},
}

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
end

function widget:DrawWorldPreUnit()
	local radius = Spring.GetGameRulesParam("suddenDeathRadius")
	if (not radius) or radius < 0 or Spring.IsGUIHidden()then
		return
	end
	local ox = Spring.GetGameRulesParam("suddenDeathOriginX")
	local oz = Spring.GetGameRulesParam("suddenDeathOriginZ")
	
	local thickness = options.thickness.value * GetThicknessFactor()
	glLineWidth(thickness)
	glColor(options.color.value[1], options.color.value[2], options.color.value[3], options.color.value[4])
	glDrawGroundCircle(ox, 0, oz, radius, math.max(12, radius))
	glLineWidth(thickness * 0.5)
	
	local midRadius = 150 * (1 - Spring.GetGameRulesParam("suddenDeathProgress"))
	glDrawGroundCircle(ox, 0, oz, midRadius, math.max(12, midRadius))
end
