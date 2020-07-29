function widget:GetInfo()
	return {
		name = "Missile Impact Points",
		desc = "Mark missile impact areas and ETAs from allies.",
		author = "esainane",
		date = "2020-07",
		license = "GPL v3.0+",
		layer = 0,
		enabled = true
	}
end

options = {}
local trackedMissiles = include("LuaRules/Configs/tracked_missiles.lua")
for id,data in pairs(trackedMissiles) do
	data.radius = WeaponDefs[id].damageAreaOfEffect
	local name = data.humanName
	local key = name .. " Color"
	local function OnChange()
		trackedMissiles.color = options[key].color
	end
	options[key] = {
		name = "Color for " .. name .. " impact points",
		type = "colors",
		value = data.color,
		OnChange = OnChange
	}
	OnChange()
end

options_path = 'Settings/Interface/Missile Impact Warnings'

local spGetCameraState     = Spring.GetCameraState
local spGetGroundHeight    = Spring.GetGroundHeight

local glLineWidth          = gl.LineWidth
local glColor              = gl.Color
local glDrawGroundCircle   = gl.DrawGroundCircle
local glPopMatrix          = gl.PopMatrix
local glPushMatrix         = gl.PushMatrix
local glTranslate          = gl.Translate

local max = math.max
local min = math.min

-- id -> {x,y,z,impactFrame,weaponDefID}
local points = {}

function widget:MissileFired(proID, proOwnerID, weaponDefID, impactX, impactY, impactZ, impactFrame)
	points[proID] = {impactX,impactY,impactZ,impactFrame,weaponDefID}
end

function widget:MissileDestroyed(proID)
	points[proID] = nil
end

local function GetCameraHeight()
	local cs = spGetCameraState()
	local gy = spGetGroundHeight(cs.px, cs.pz)
	local testHeight = cs.py - gy
	if cs.name == "ta" then
		testHeight = cs.height - gy
	end
	return testHeight
end

local curFrame = -1

function widget:DrawWorldPreUnit()
	-- Red shrinking circles for impact points
	for i,data in pairs(points) do
		local x,y,z,impactFrame,weaponDefID = unpack(data)
		local weaponDefConfig = trackedMissiles[weaponDefID]
		local r,g,b = unpack(weaponDefConfig.color)
		local radius = weaponDefConfig.radius
		local fadeIn = weaponDefConfig.fadeIn
		local extra_radius = (impactFrame - curFrame) * (radius+3700) / 5000
		if extra_radius >= 0 then
			glLineWidth(max(1.0,38/(4+GetCameraHeight()/800)))
			-- faded features first
			glPushMatrix()
			glTranslate(x, y, z)
			local fadeAlpha = max(0.1,min(1,(fadeIn-extra_radius)/fadeIn))
			glColor(r,g,b,fadeAlpha)
			-- a ground circle, fading in closer to impact time, that approaches the fixed circle as impact time approaches
			glDrawGroundCircle(0, 0, 0, radius+extra_radius, radius+extra_radius)
			glColor(r,g,b,1)
			-- a ground circle, fixed in visibility, that shows the area of effect
			glDrawGroundCircle(0, 0, 0, radius, radius)
			glPopMatrix()
		end
	end
end

function widget:GameFrame(n)
	curFrame = n
	for i,v in ipairs(points) do
		if v[4] < n then
			points[i] = points[#points]
			points[#points] = nil
		end
	end
end

function widget:Initialize()
	for k,v in pairs(options) do
		v.OnChange()
	end
end
