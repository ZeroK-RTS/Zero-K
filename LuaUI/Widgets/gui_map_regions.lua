function widget:GetInfo()
	return {
		name      = "Map region view bounds",
		desc      = "Map region selector and cropped world/minimap views",
		author    = "gajop",
		date      = "2026-11",
		license   = "GNU GPL, v2 or later",
		layer     = 10001,
		enabled   = true,
		handler   = true,
	}
end

if not (Engine.FeatureSupport and Engine.FeatureSupport.mapRegionViews) then
	return false
end

local mapRegions = VFS.Include("LuaRules/Gadgets/Include/map_regions.lua")
if not mapRegions then
	return false
end

local regions = mapRegions.regions
local ObjectRegion = mapRegions.ObjectRegion

local activeRegion, ready = 1, false
local cameraStates = {}
local pendingCamera, cameraDrawFrame, selector, regionButtons
local UpdateSelector

-- Own units per region, counted where they were created or received.
local myTeamID = Spring.GetMyTeamID()
local countedRegion = {}
local unitCounts, selectedCounts = {}, {}
for regionID = 1, #regions do
	unitCounts[regionID], selectedCounts[regionID] = 0, 0
end

local function ContainsUnit(unitID)
	local x, _, z = Spring.GetUnitPosition(unitID)
	return mapRegions.ContainsObject(activeRegion, x, z)
end

local function SetRegionView(regionID, cameraState)
	if not regions[regionID] then
		return false
	end
	if ready then
		cameraStates[activeRegion] = Spring.GetCameraState()
	end
	activeRegion = regionID
	local r = regions[regionID]
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
	widgetHandler:MapRegionViewChanged()
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
	UpdateSelector()
	return true
end

options_path = 'Hotkeys/Camera'
options_order = {'cycle_region'}
options = {
	cycle_region = {
		name = 'Cycle map region',
		desc = 'Switch the camera and minimap to the next region of a multi-region map.',
		type = 'button',
		OnChange = function()
			if ready and #regions > 1 then
				SetRegionView(activeRegion % #regions + 1)
			end
		end,
	},
}

--------------------------------------------------------------------------------
-- Selector

function UpdateSelector()
	if not regionButtons then
		return
	end
	for regionID, button in ipairs(regionButtons) do
		local name = regions[regionID].name
		local active = (activeRegion == regionID)
		local caption = (active and "> " or "") .. name .. "  (" .. unitCounts[regionID] .. ")"
		if button.caption ~= caption then
			button:SetCaption(caption)
		end
		button.tooltip = "View " .. name .. ". " .. unitCounts[regionID] .. " of your units here; "
			.. selectedCounts[regionID] .. " selected."
		if button.isActiveRegion ~= active then
			button.isActiveRegion = active
			button.backgroundColor = active and {0.2, 0.42, 0.5, 1} or {0.15, 0.18, 0.2, 1}
			button:Invalidate()
		end
	end
end

local function CreateSelector()
	local Chili = WG.Chili
	if selector or #regions < 2 or not Chili then
		return
	end
	selector = Chili.Window:New({
		parent = Chili.Screen0,
		name = "Map region selector",
		right = 12,
		y = 85,
		width = 240,
		height = 42 + #regions * 36,
		padding = {8, 8, 8, 8},
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
		caption = "Map regions",
		font = {size = 14},
		autosize = false,
	})
	regionButtons = {}
	for regionID, r in ipairs(regions) do
		regionButtons[regionID] = Chili.Button:New({
			parent = selector,
			x = 0,
			y = 22 + (regionID - 1) * 36,
			right = 0,
			height = 32,
			caption = r.name,
			OnClick = {
				function()
					SetRegionView(regionID)
				end,
			},
		})
	end
	UpdateSelector()
end

--------------------------------------------------------------------------------
-- Unit counts

local function AddOwnUnit(unitID)
	local x, _, z = Spring.GetUnitPosition(unitID)
	local regionID = ObjectRegion(x, z)
	if regionID and not countedRegion[unitID] then
		countedRegion[unitID] = regionID
		unitCounts[regionID] = unitCounts[regionID] + 1
		return true
	end
end

local function RemoveOwnUnit(unitID)
	local regionID = countedRegion[unitID]
	if regionID then
		countedRegion[unitID] = nil
		unitCounts[regionID] = unitCounts[regionID] - 1
		return true
	end
end

local function CountOwnUnits()
	countedRegion = {}
	for regionID = 1, #regions do
		unitCounts[regionID] = 0
	end
	for _, unitID in ipairs(Spring.GetTeamUnits(myTeamID) or {}) do
		AddOwnUnit(unitID)
	end
	UpdateSelector()
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID and AddOwnUnit(unitID) then
		UpdateSelector()
	end
end

function widget:UnitDestroyed(unitID)
	if RemoveOwnUnit(unitID) then
		UpdateSelector()
	end
end

function widget:UnitGiven(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID and AddOwnUnit(unitID) then
		UpdateSelector()
	end
end

function widget:UnitTaken(unitID, unitDefID, unitTeam)
	if unitTeam == myTeamID and RemoveOwnUnit(unitID) then
		UpdateSelector()
	end
end

function widget:PlayerChanged()
	if Spring.GetMyTeamID() ~= myTeamID then
		myTeamID = Spring.GetMyTeamID()
		CountOwnUnits()
	end
end

function widget:SelectionChanged(selectedUnits)
	for regionID = 1, #regions do
		selectedCounts[regionID] = 0
	end
	for i = 1, #selectedUnits do
		local x, _, z = Spring.GetUnitPosition(selectedUnits[i])
		local regionID = ObjectRegion(x, z)
		if regionID then
			selectedCounts[regionID] = selectedCounts[regionID] + 1
		end
	end
	UpdateSelector()
end

--------------------------------------------------------------------------------
-- Callins

function widget:Initialize()
	activeRegion = mapRegions.TeamHome(myTeamID) or 1
end

function widget:Update()
	widgetHandler:RemoveWidgetCallIn("Update", widget)
	if not Spring.GetGameRulesParam("map_regions") then
		-- The region gadget is not running, so leave the ordinary view alone.
		widgetHandler:RemoveWidget(widget)
		return
	end
	CreateSelector()
	CountOwnUnits()
	SetRegionView(activeRegion)
	ready = true
end

function widget:DrawWorldPreUnit()
	if pendingCamera and Spring.GetDrawFrame() >= cameraDrawFrame then
		Spring.SetCameraState(pendingCamera, 0)
		pendingCamera = nil
	end
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
	if ready then
		widgetHandler:MapRegionViewChanged()
	end
end
