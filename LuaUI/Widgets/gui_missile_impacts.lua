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

local END_FADE_TIME = 12
local START_FADE_TIME = 8

options_order = {"alpha", "thickness"}
options = {
	alpha = {
		name = "Line opacity",
		type = "number",
		value = 0.6,
		min = 0,
		max = 1,
		step = 0.01,
	},
	thickness = {
		name = "Line thickness",
		type = "number",
		value = 3,
		min = 1,
		max = 10,
		step = 0.1,
	},
}
local trackedMissiles = include("LuaRules/Configs/tracked_missiles.lua")
for id, data in pairs(trackedMissiles) do
	data.radius = data.radiusOverride or math.floor(WeaponDefs[id].damageAreaOfEffect * (data.radiusMult or 1))
	local name = data.humanName
	local key = name .. " Color"
	local function OnChange(self)
		data.color = self.value
	end
	options_order[#options_order + 1] = key
	options[key] = {
		name = "Allied " .. name .. " target color",
		type = "colors",
		value = data.color,
		OnChange = OnChange
	}
end

options_path = 'Settings/Interface/Missile Warnings'

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
local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local points = IterableMap.New()

function widget:MissileFired(proID, proOwnerID, weaponDefID, impactX, impactY, impactZ, impactFrame, targetID)
	local currentFrame = Spring.GetGameFrame()
	impactFrame = math.max(currentFrame + 5, impactFrame)
	IterableMap.Add(points, proID, {
		ix = impactX,
		iy = impactY,
		iz = impactZ,
		impactFrame = impactFrame,
		fireFrame = currentFrame,
		dieFrame = impactFrame + END_FADE_TIME,
		weaponDefID = weaponDefID,
		targetID = targetID,
	})
end

function widget:MissileDestroyed(proID)
	local proData = IterableMap.Get(points, proID)
	if proData then
		proData.dieFrame = math.min(Spring.GetGameFrame() + END_FADE_TIME, proData.dieFrame)
		proData.isDead = true
	end
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

local function GetThicknessFactor()
	local height = GetCameraHeight()
	if height < 1000 then
		return 1
	end
	return 1000 / (1000 + height) + 0.5
end

local function DrawPoint(proID, data, index, curFrame)
	if curFrame >= data.dieFrame then
		return true
	end
	local weaponDefConfig = trackedMissiles[data.weaponDefID]
	local r,g,b = unpack(weaponDefConfig.color)
	local radius = weaponDefConfig.radius
	local fadeIn = weaponDefConfig.fadeIn
	local impactProportion = (curFrame - data.impactFrame) / (data.fireFrame - data.impactFrame)
	
	if data.targetID and not data.isDead then
		local x, y, z = Spring.GetUnitPosition(data.targetID)
		if x and y and z then
			data.ix, data.iy, data.iz = x, y, z
		end
	end
	
	local innerAlpha = max(0.1, min(1, (fadeIn - impactProportion)/fadeIn)) * options.alpha.value
	local outerAlpha = options.alpha.value
	if curFrame + END_FADE_TIME > data.dieFrame then
		outerAlpha = outerAlpha * math.sqrt((data.dieFrame - curFrame) / END_FADE_TIME)
	end
	
	if curFrame < data.fireFrame + START_FADE_TIME then
		local prop = math.sqrt((curFrame - data.fireFrame) / START_FADE_TIME)
		innerAlpha = innerAlpha * prop
		outerAlpha = outerAlpha * prop
	end
	
	glLineWidth(options.thickness.value * GetThicknessFactor())
	if curFrame < data.impactFrame then
		glColor(r, g, b, innerAlpha)
		glDrawGroundCircle(data.ix, data.iy, data.iz, math.max(2, radius * impactProportion), 8 + radius * impactProportion)
	end
	
	glColor(r, g, b, outerAlpha)
	glDrawGroundCircle(data.ix, data.iy, data.iz, radius, (data.targetID and radius) or math.ceil(8 + radius * 0.4))
end

function widget:DrawWorldPreUnit()
	if IterableMap.IsEmpty(points) or Spring.IsGUIHidden() then
		return
	end
	local curFrame = Spring.GetGameFrame()
	IterableMap.Apply(points, DrawPoint, curFrame)
end
