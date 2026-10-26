-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Map region view bounds",
		desc = "Map region selector and cropped world/minimap views",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10001,
		enabled = true,
		handler = true,
	}
end

if not (Engine.FeatureSupport and Engine.FeatureSupport.mapRegionViews) then
	return false
end

local mapRegions = VFS.Include("LuaRules/Utilities/map_regions.lua")
if not mapRegions then
	return false
end

local activeRegion, ready = 1, false
local cameraStates = {}
local pendingCamera, cameraDrawFrame, selector, regionButtons
local nextCountsUpdate = 0

local function ContainsUnit(unitID)
	local x, _, z = Spring.GetUnitPosition(unitID)
	return mapRegions.ContainsObject(activeRegion, x, z)
end

local function SetRegionView(regionID, cameraState)
	if not mapRegions.regions[regionID] then
		return false
	end
	if ready then
		cameraStates[activeRegion] = Spring.GetCameraState()
	end
	activeRegion = regionID
	local r = mapRegions.regions[regionID]
	WG.MapRegionView = {
		region = regionID,
		rect = r,
		ContainsUnit = ContainsUnit,
		SetRegion = SetRegionView,
	}
	if WG.DelaySmoothCam then
		WG.DelaySmoothCam(0.5)
	end
	Spring.SetCameraBounds(r.x0, r.z0, r.x1, r.z1)
	Spring.SetMiniMapView(r.x0, r.z0, r.x1, r.z1)
	Spring.SetWorldDrawBounds(r.x0, r.z0, r.x1, r.z1)
	if Engine.FeatureSupport.objectDrawBounds then
		local bounds = mapRegions.objectBounds[regionID]
		Spring.SetObjectDrawBounds(bounds.x0, bounds.z0, bounds.x1, bounds.z1)
	end
	widgetHandler:ParallelWorldShift()
	local x, z = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
	pendingCamera = cameraState
		or cameraStates[regionID]
		or {
			name = "ta",
			mode = 1,
			px = x,
			py = Spring.GetGroundHeight(x, z),
			pz = z,
			height = math.max(r.width, r.height) * 1.17,
			angle = 0.05,
			flipped = 0,
		}
	cameraDrawFrame = Spring.GetDrawFrame() + 1
	return true
end

local function UpdateSelector()
	if not regionButtons then
		return
	end
	local counts, selected = {}, {}
	for regionID in ipairs(mapRegions.regions) do
		counts[regionID], selected[regionID] = 0, 0
	end
	local function CountUnit(unitID, target)
		local x, _, z = Spring.GetUnitPosition(unitID)
		local regionID = mapRegions.ObjectRegion(x, z)
		if regionID then
			target[regionID] = target[regionID] + 1
		end
	end
	for _, unitID in ipairs(Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}) do
		CountUnit(unitID, counts)
	end
	for _, unitID in ipairs(Spring.GetSelectedUnits()) do
		CountUnit(unitID, selected)
	end
	for regionID, button in pairs(regionButtons) do
		local name = mapRegions.regions[regionID].name
		button:SetCaption((activeRegion == regionID and "> " or "") .. name .. "  (" .. counts[regionID] .. ")")
		button.tooltip = "View "
			.. name
			.. ". "
			.. counts[regionID]
			.. " of your units here; "
			.. selected[regionID]
			.. " selected. N cycles regions."
		button.backgroundColor = activeRegion == regionID and { 0.2, 0.42, 0.5, 1 } or { 0.15, 0.18, 0.2, 1 }
		button:Invalidate()
	end
end

local function CreateSelector()
	if selector or #mapRegions.regions < 2 then
		return
	end
	local Chili = WG.Chili
	if not Chili then
		return
	end
	selector = Chili.Window:New({
		parent = Chili.Screen0,
		name = "Map region selector",
		right = 12,
		y = 85,
		width = 240,
		height = 42 + #mapRegions.regions * 36,
		padding = { 8, 8, 8, 8 },
		draggable = false,
		resizable = false,
		dockable = false,
		minimizable = false,
	})
	Chili.Label:New({
		parent = selector,
		x = 2,
		y = 0,
		width = 200,
		height = 20,
		caption = "Map regions  (N)",
		font = { size = 14 },
		autosize = false,
	})
	regionButtons = {}
	for i, r in ipairs(mapRegions.regions) do
		local regionID = i
		regionButtons[i] = Chili.Button:New({
			parent = selector,
			x = 0,
			y = 22 + (i - 1) * 36,
			right = 0,
			height = 32,
			caption = r.name,
			OnClick = {
				function()
					SetRegionView(regionID)
					UpdateSelector()
				end,
			},
		})
	end
	UpdateSelector()
end

function widget:Initialize()
	activeRegion = mapRegions.TeamHome(Spring.GetMyTeamID()) or 1
end

function widget:Update()
	if not ready and Spring.GetGameRulesParam("map_regions") then
		SetRegionView(activeRegion)
		ready = true
	end
	CreateSelector()
	local now = Spring.GetDrawSeconds()
	if now >= nextCountsUpdate then
		nextCountsUpdate = now + 0.25
		UpdateSelector()
	end
end

function widget:DrawWorldPreUnit()
	if pendingCamera and Spring.GetDrawFrame() >= cameraDrawFrame then
		Spring.SetCameraState(pendingCamera, 0)
		pendingCamera = nil
	end
end

function widget:KeyPress(key, mods)
	if key ~= string.byte("n") or mods.ctrl or mods.alt or mods.meta or #mapRegions.regions < 2 then
		return
	end
	SetRegionView(activeRegion % #mapRegions.regions + 1)
	UpdateSelector()
	return true
end

function widget:Shutdown()
	if selector then
		selector:Dispose()
	end
	WG.MapRegionView = nil
	Spring.SetCameraBounds()
	Spring.SetMiniMapView()
	Spring.SetWorldDrawBounds()
	if Engine.FeatureSupport.objectDrawBounds then
		Spring.SetObjectDrawBounds()
	end
end
