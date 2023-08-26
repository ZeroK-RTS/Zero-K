function widget:GetInfo()
	return {
		name      = "Camera Spline Path",
		desc      = "Implement programmable paths that the camera can follow.",
		author    = "GoogleFrog",
		date      = "25 July 2023",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local currentTime = false
local prevSeconds = false

local pathConfig = {
	startTime = Spring.GetGameSeconds() + 2,
	duration = 7,
	globalEasing = function (x)
		return math.max(0, math.min(1, (x - 0.2) * 1.4))
	end,
	position = {
		spline = true,
		points = {{1500, 400, 1500}, {4500, 1800, 0}, {4000, 900, 4000}},
		easing = function (x)
			if x < 0.5 then
				return 4 * x * x * x
			else
				return 1 - math.pow(-2 * x + 2, 3) / 2
			end
			return x
		end,
	},
	direction = {
		spline = true,
		pointTowards = true,
		points = {{1700, 174, 3000}},
		easing = function (x) return x end,
	},
	fov = {
		spline = true,
		points = {45, 60, 15},
		easing = function (x) return x end,
	}
}

local function SolveSingleDimSpline(points, prog)
	local newPoints
	while #points > 1 do
		newPoints = {}
		for i = 1, #points - 1 do
			newPoints[i] = (1 - prog) * points[i] + prog * points[i + 1]
		end
		points = newPoints
	end
	return points[1]
end


local function SolveSplineDimension(spline, dimension, prog)
	local points = {}
	for i = 1, #spline do
		points[i] = spline[i][dimension]
	end
	return SolveSingleDimSpline(points, prog)
end

local function SolveSpline(spline, prog)
	return {
		SolveSplineDimension(spline, 1, prog),
		SolveSplineDimension(spline, 2, prog),
		SolveSplineDimension(spline, 3, prog),
	}
end

local function TracePath(path, dt)
	if currentTime < path.startTime or currentTime > path.startTime + path.duration then
		if path.active then
			Spring.SendCommands("viewta")
		end
		return
	end
	if not path.initialized then
		Spring.SendCommands("viewrot")
		path.initialized = true
		path.active = true
	end
	local animProp = (currentTime - path.startTime) / path.duration
	animProp = path.globalEasing(animProp)
	
	state = Spring.GetCameraState()
	
	local positionProgress = (pathConfig.position.easing and pathConfig.position.easing(animProp)) or animProp
	local pos = SolveSpline(pathConfig.position.points, positionProgress)
	
	local directionProgress = (pathConfig.direction.easing and pathConfig.direction.easing(animProp)) or animProp
	local dir = SolveSpline(pathConfig.direction.points, directionProgress)
	if pathConfig.direction.pointTowards then
		dir[1] = dir[1] - pos[1]
		dir[2] = dir[2] - pos[2]
		dir[3] = dir[3] - pos[3]
	end
	
	local fovProgress = (pathConfig.fov.easing and pathConfig.fov.easing(animProp)) or animProp
	local fov = SolveSingleDimSpline(pathConfig.fov.points, fovProgress)
	
	state.px = pos[1]
	state.py = pos[2]
	state.pz = pos[3]
	state.dx = dir[1]
	state.dy = dir[2]
	state.dz = dir[3]
	
	state.fov = fov
	
	Spring.SetCameraState(state, 0)
end

function widget:Update(dt)
	if (not currentTime) or (prevSeconds ~= Spring.GetGameSeconds()) then
		currentTime = Spring.GetGameSeconds()
		prevSeconds = currentTime
	end
	
	prevTime = currentTime
	currentTime = currentTime + dt
	TracePath(pathConfig, dt)
end
