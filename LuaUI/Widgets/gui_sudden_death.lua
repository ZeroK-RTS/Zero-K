function widget:GetInfo()
	return {
		name = "Sudden Death",
		desc = "Draws sudden death circle.",
		author = "GoogleFrog",
		date = "24 June 2023",
		license = "GPL v2.0+",
		layer = 0,
		enabled = true
	}
end

options_path = 'Settings/Interface/Map/Sudden Death'
options_order = {"color", "mid_color", "thickness"}
options = {
	color = {
		name = "Sudden death color",
		type = "colors",
		value = {1, 0.2, 0.2, 0.8},
	},
	mid_color = {
		name = "Middle ring color",
		type = "colors",
		value = {0.2, 1, 0.2, 0.6},
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
local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local suddenDeathFrame = false
local fadeTimer = false

local spGetCameraState     = Spring.GetCameraState
local spGetGroundHeight    = Spring.GetGroundHeight

local GetMiniMapFlipped = Spring.Utilities.IsMinimapFlipped

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


function widget:DrawInMiniMap(minimapX, minimapY)
	local radius = Spring.GetGameRulesParam("suddenDeathRadius")
	if (not radius) or radius < 0 or Spring.IsGUIHidden()then
		return
	end
	local ox = Spring.GetGameRulesParam("suddenDeathOriginX")
	local oz = Spring.GetGameRulesParam("suddenDeathOriginZ")
	
	gl.PushMatrix()

	glLineWidth(3)
	glColor(options.color.value[1], options.color.value[2], options.color.value[3], alpha)
	
	if GetMiniMapFlipped() then
		gl.Translate(minimapY, 0, 0)
		gl.Scale(-minimapX/mapX, minimapY/mapZ, 1)
	else
		gl.Translate(0, minimapY, 0)
		gl.Scale(minimapX/mapX, -minimapY/mapZ, 1)
	end
	
	gl.Utilities.DrawCircle(ox, oz, radius)

	glLineWidth(1)
	glColor(1, 1, 1, 1)

	gl.PopMatrix()
end

function widget:DrawWorldPreUnit()
	if not suddenDeathFrame then
		return
	end
	local frame = Spring.GetGameFrame()
	if frame + LEAD_IN_FRAMES < suddenDeathFrame then
		return
	end
	
	local shrinkProgress = (Spring.GetGameRulesParam("suddenDeathProgress") or 0)
	local midRadius = 120 * (1 - shrinkProgress)
	if midRadius < 0 then
		return
	end
	local ox = Spring.GetGameRulesParam("suddenDeathOriginX")
	local oz = Spring.GetGameRulesParam("suddenDeathOriginZ")
	
	local thickness = options.thickness.value * GetThicknessFactor()
	local preProgress = math.min(1, 1 - (suddenDeathFrame - frame) / LEAD_IN_FRAMES)
	local alpha =  preProgress
	if fadeTimer then
		local diff = Spring.DiffTimers(Spring.GetTimer(), fadeTimer)
		if diff > 0.75 then
			suddenDeathFrame = false
			return
		end
		alpha = alpha * (0.75 - diff) / 0.75
	end
	
	glLineWidth(thickness * 0.6)
	glColor(
		shrinkProgress * options.color.value[1] + (1 - shrinkProgress) * options.mid_color.value[1],
		shrinkProgress * options.color.value[2] + (1 - shrinkProgress) * options.mid_color.value[2],
		shrinkProgress * options.color.value[3] + (1 - shrinkProgress) * options.mid_color.value[3],
		shrinkProgress * options.color.value[4] + (1 - shrinkProgress) * options.mid_color.value[4] * alpha)
	
	glDrawGroundCircle(ox, 0, oz, midRadius, math.max(24, midRadius))
	if preProgress < 0.97 then
		glDrawGroundCircle(ox, 0, oz, midRadius * preProgress, math.max(12, midRadius))
	elseif preProgress < 1 then
		local prop = (preProgress - 0.97) / 0.03
		prop = (prop < 0.5 and prop*prop*2) or (1 - (-2 * prop + 2) * (-2 * prop + 2) / 2)
		local colorProp = math.sqrt((prop > 0 and prop) or 0)
		
		local radiusOne = Spring.GetGameRulesParam("suddenDeathStartDistance")
		local radiusTwo = midRadius * preProgress
		local radiusAverage = prop * radiusOne + (1 - prop) * radiusTwo
		
		glLineWidth(thickness * (0.4*prop + 0.6))
		glColor(
			colorProp * options.color.value[1] + (1 - colorProp) * options.mid_color.value[1],
			colorProp * options.color.value[2] + (1 - colorProp) * options.mid_color.value[2],
			colorProp * options.color.value[3] + (1 - colorProp) * options.mid_color.value[3],
			colorProp * options.color.value[4] + (1 - colorProp) * options.mid_color.value[4] * alpha)
		
		glDrawGroundCircle(ox, 0, oz, radiusAverage, math.max(24, radiusAverage))
	end
	
	if preProgress < 1 then
		return
	end
	local radius = Spring.GetGameRulesParam("suddenDeathRadius")
	if (not radius) or radius < 0 or Spring.IsGUIHidden()then
		return
	end
	
	glLineWidth(thickness)
	glColor(options.color.value[1], options.color.value[2], options.color.value[3], options.color.value[4] * alpha)
	
	glDrawGroundCircle(ox, 0, oz, radius, math.max(24, radius))
	
	glLineWidth(1)
	glColor(1, 1, 1, 1)
end

function widget:GameOver()
	fadeTimer = Spring.GetTimer()
end

