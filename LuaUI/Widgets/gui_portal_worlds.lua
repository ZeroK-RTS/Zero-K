-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Portal view bounds",
		desc = "Map region selector and cropped world/minimap views",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10001,
		enabled = true,
	}
end

if not (Engine.FeatureSupport and Engine.FeatureSupport.mapRegionViews) then
	return false
end

local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
if not world then
	return false
end

local active, generation, ready = 1, 0, false
local cameraStates = {}
local pendingCamera, cameraDrawFrame, selector, systemButtons
local nextCountsUpdate = 0

local function ContainsUnit(id)
	local x, _, z = Spring.GetUnitPosition(id)
	return world.ContainsObject(active, x, z)
end

local function View(region, cameraState)
	if not world.regions[region] then
		return false
	end
	if ready then
		cameraStates[active] = Spring.GetCameraState()
	end
	active = region
	generation = generation + 1
	local r = world.regions[region]
	WG.PortalWorldView = {
		generation = generation,
		region = region,
		rect = r,
		ContainsUnit = ContainsUnit,
		SetRegion = View,
	}
	if WG.DelaySmoothCam then
		WG.DelaySmoothCam(0.5)
	end
	Spring.SetCameraBounds(r.x0, r.z0, r.x1, r.z1)
	Spring.SetMiniMapView(r.x0, r.z0, r.x1, r.z1)
	Spring.SetWorldDrawBounds(r.x0, r.z0, r.x1, r.z1)
	if Engine.FeatureSupport.objectDrawBounds then
		local bounds = world.objectBounds[region]
		Spring.SetObjectDrawBounds(bounds.x0, bounds.z0, bounds.x1, bounds.z1)
	end
	local x, z = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
	pendingCamera = cameraState
		or cameraStates[region]
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
	if not systemButtons then
		return
	end
	local counts, selected = {}, {}
	for i in ipairs(world.regions) do
		counts[i], selected[i] = 0, 0
	end
	local function Count(id, target)
		local x, _, z = Spring.GetUnitPosition(id)
		local region = world.ObjectRegion(x, z)
		if region then
			target[region] = target[region] + 1
		end
	end
	for _, id in ipairs(Spring.GetTeamUnits(Spring.GetMyTeamID()) or {}) do
		Count(id, counts)
	end
	for _, id in ipairs(Spring.GetSelectedUnits()) do
		Count(id, selected)
	end
	for i, button in pairs(systemButtons) do
		local name = world.regions[i].name
		button:SetCaption((active == i and "> " or "") .. name .. "  (" .. counts[i] .. ")")
		button.tooltip = "View "
			.. name
			.. ". "
			.. counts[i]
			.. " of your units here; "
			.. selected[i]
			.. " selected. N cycles maps."
		button.backgroundColor = active == i and { 0.2, 0.42, 0.5, 1 } or { 0.15, 0.18, 0.2, 1 }
		button:Invalidate()
	end
end

local function CreateSelector()
	if selector or #world.regions < 2 then
		return
	end
	local Chili = WG.Chili
	if not Chili then
		return
	end
	selector = Chili.Window:New({
		parent = Chili.Screen0,
		name = "System selector",
		right = 12,
		y = 85,
		width = 240,
		height = 42 + #world.regions * 36,
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
	systemButtons = {}
	for i, r in ipairs(world.regions) do
		local region = i
		systemButtons[i] = Chili.Button:New({
			parent = selector,
			x = 0,
			y = 22 + (i - 1) * 36,
			right = 0,
			height = 32,
			caption = r.name,
			OnClick = {
				function()
					View(region)
					UpdateSelector()
				end,
			},
		})
	end
	UpdateSelector()
end

function widget:Initialize()
	active = world.TeamHome(Spring.GetMyTeamID()) or 1
end

function widget:Update()
	if not ready and Spring.GetGameRulesParam("portal_regions") then
		View(active)
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
	if key ~= string.byte("n") or mods.ctrl or mods.alt or mods.meta or #world.regions < 2 then
		return
	end
	View(active % #world.regions + 1)
	UpdateSelector()
	return true
end

function widget:Shutdown()
	if selector then
		selector:Dispose()
	end
	WG.PortalWorldView = nil
	Spring.SetCameraBounds()
	Spring.SetMiniMapView()
	Spring.SetWorldDrawBounds()
	if Engine.FeatureSupport.objectDrawBounds then
		Spring.SetObjectDrawBounds()
	end
end
