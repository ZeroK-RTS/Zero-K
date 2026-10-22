-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Map region materials",
		desc = "Apply the viewed map region's DNTS, sun and atmosphere",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10000,
		enabled = true,
		handler = true,
	}
end

local mapRegions = VFS.Include("LuaRules/Utilities/map_regions.lua")
if not mapRegions or not mapRegions.profiles then
	return false
end

local profiles = mapRegions.profiles
local appliedRegion, updates, loaded = nil, 0, {}

local function ApplyEnvironment(profile)
	local d = profile.direction
	Spring.SetSunDirection(d[1], d[2], d[3])
	Spring.SetSunLighting(profile.sun)
	Spring.SetAtmosphere(profile.atmosphere)
	if profile.water then
		Spring.SetWaterParams(profile.water)
	end
	-- Keep ZK's graphics options consistent, so changing one slider does not
	-- restore the previous region's entire lighting setup through FullSunUpdate.
	local sunWidget = widgetHandler:FindWidget("Sun and Atmosphere Handler")
	if sunWidget then
		for key, value in pairs(profile.sun) do
			if sunWidget.options[key] then
				sunWidget.options[key].value = value
			end
		end
		for key, value in pairs(profile.atmosphere) do
			if sunWidget.options[key] then
				sunWidget.options[key].value = value
			end
		end
		local length = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
		sunWidget.options.sunDir.value = math.atan2(d[3], d[1])
		sunWidget.options.sunPitch.value = math.asin(d[2] / length)
	end
end

local function ApplyRegionMaterial(regionID)
	local profile = profiles[regionID]
	for _, texture in ipairs(profile.textures) do
		local path = texture[2]
		if not loaded[path] then
			-- SetMapShadingTexture uses named textures that are already loaded.
			local list = gl.CreateList(function()
				assert(gl.Texture(path), "Could not load map region texture " .. path)
				gl.Texture(false)
			end)
			gl.DeleteList(list)
			loaded[path] = true
		end
		assert(
			Spring.SetMapShadingTexture(texture[1], path, texture[3] or 0),
			"Could not set map region texture " .. path
		)
	end
	Spring.SetMapRenderingParams(profile.rendering)
	Spring.SetDrawWater(profile.drawWater ~= false)
	ApplyEnvironment(profile)
	appliedRegion = regionID
	WG.MapRegionMaterial = { region = regionID, profile = profile }
end

function widget:ParallelWorldShift()
	local view = WG.MapRegionView
	if view and view.region and appliedRegion ~= view.region then
		ApplyRegionMaterial(view.region)
	end
end

function widget:Initialize()
	widget:ParallelWorldShift()
end

function widget:Update()
	updates = updates + 1
	-- ZK loads its default overrides on Update 4 and 28. This widget runs
	-- after it; retain the active region during that initial setup as well.
	if updates <= 30 then
		if appliedRegion then
			ApplyEnvironment(profiles[appliedRegion])
		end
	else
		widgetHandler:RemoveWidgetCallIn("Update", widget)
	end
end

function widget:Shutdown()
	for _, texture in ipairs(profiles[1].textures) do
		Spring.SetMapShadingTexture(texture[1], "", texture[3] or 0)
	end
	Spring.SetDrawWater(true)
	WG.MapRegionMaterial = nil
end
