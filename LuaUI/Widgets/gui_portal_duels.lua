-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Portal view bounds",
		desc = "Connected-map selector and cropped world/minimap views",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10001,
		enabled = true,
	}
end
if not (Engine.FeatureSupport and Engine.FeatureSupport.mapRegionViews) then
	return false
end
local options = Spring.GetModOptions()
if not options.zk_duels or options.zk_duels == "baseline" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
if not world then
	return false
end
local active, origin, generation, ready = 1, 1, 0, false
local cameraStates = {}
local pendingCamera, cameraDrawFrame, selector, systemButtons, selectorKey
local nextCountsUpdate = 0
local function IsOpen(edge)
	return Spring.GetGameRulesParam("zkduels_e" .. edge .. "_open") == 1
end
local function Accessible(region)
	return region == origin or world.Route(origin, region, IsOpen) ~= nil
end
local function ContainsUnit(id)
	local x, _, z = Spring.GetUnitPosition(id)
	return world.Region(x, z) == active
end
local function View(region, cameraState)
	if not world.regions[region] or not Accessible(region) then
		return false
	end
	if ready then
		cameraStates[active] = Spring.GetCameraState()
	end
	active = region
	generation = generation + 1
	local r = world.regions[region]
	WG.PortalWorldView = { generation = generation, region = region, rect = r, ContainsUnit = ContainsUnit }
	if WG.DelaySmoothCam then
		WG.DelaySmoothCam(0.5)
	end
	Spring.SetCameraBounds(r.x0, r.z0, r.x1, r.z1)
	Spring.SetMiniMapView(r.x0, r.z0, r.x1, r.z1)
	Spring.SetWorldDrawBounds(r.x0, r.z0, r.x1, r.z1)
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
		local region = world.Region(x, z)
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
			.. " selected. N cycles connected maps."
		button.backgroundColor = active == i and { 0.2, 0.42, 0.5, 1 } or { 0.15, 0.18, 0.2, 1 }
		button:Invalidate()
	end
end
local function RefreshSelector()
	local accessible = {}
	for i in ipairs(world.regions) do
		if Accessible(i) then
			accessible[#accessible + 1] = i
		end
	end
	local key = table.concat(accessible, ",")
	if key == selectorKey then
		return
	end
	if selector then
		selector:Dispose()
		selector, systemButtons = nil, nil
	end
	if #accessible < 2 then
		selectorKey = key
		return
	end
	local Chili = WG.Chili
	if not Chili then
		return
	end
	selectorKey = key
	selector = Chili.Window:New({
		parent = Chili.Screen0,
		name = "System selector",
		right = 12,
		y = 85,
		width = 240,
		height = 42 + #accessible * 36,
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
		caption = "Connected maps  (N)",
		font = { size = 14 },
		autosize = false,
	})
	systemButtons = {}
	for position, i in ipairs(accessible) do
		local region = i
		systemButtons[i] = Chili.Button:New({
			parent = selector,
			x = 0,
			y = 22 + (position - 1) * 36,
			right = 0,
			height = 32,
			caption = world.regions[i].name,
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
	WG.PortalDuelsView = View
	origin = world.TeamHome(Spring.GetMyTeamID()) or 1
	active = origin
	WG.PortalAccessible = Accessible
end
function widget:Update()
	if not ready and Spring.GetGameRulesParam("zkduels_regions") then
		View(active)
		ready = true
	end
	RefreshSelector()
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
	if key ~= string.byte("n") or mods.ctrl or mods.alt or mods.meta then
		return
	end
	for offset = 1, #world.regions - 1 do
		local i = (active - 1 + offset) % #world.regions + 1
		if Accessible(i) then
			View(i)
			UpdateSelector()
			return true
		end
	end
end
function widget:MousePress(x, y, button)
	if button ~= 3 then
		return false
	end
	local _, activeCommand = Spring.GetActiveCommand()
	if activeCommand then
		return false -- Preserve normal command cancellation and formation controls.
	end
	local kind, id = Spring.TraceScreenRay(x, y, false, true)
	local edge = kind == "unit" and Spring.GetUnitRulesParam(id, "zkduels_portal")
	if edge and Spring.GetUnitRulesParam(id, "zkduels_region") ~= active then
		edge = nil
	end
	if not edge then
		local _, pos = Spring.TraceScreenRay(x, y, true, true)
		if type(pos) ~= "table" then
			return false
		end
		for i, connection in ipairs(world.connections) do
			if IsOpen(i) and world.Other(connection, active) then
				local prefix = "zkduels_e" .. i .. "_r" .. active
				local mx, mz =
					Spring.GetGameRulesParam(prefix .. "_x"), Spring.GetGameRulesParam(prefix .. "_z")
				if mx and (pos[1] - mx) ^ 2 + (pos[3] - mz) ^ 2 <= 64 ^ 2 then
					edge = i
					break
				end
			end
		end
	end
	if not edge then
		return false
	end
	local selected = Spring.GetSelectedUnits()
	if #selected == 0 then
		return false
	end
	local _, _, _, shift = Spring.GetModKeyState()
	if Spring.GetInvertQueueKey() then
		shift = not shift
	end
	Spring.GiveOrderToUnitArray(
		selected,
		Spring.Utilities.CMD.PORTAL_TRAVEL,
		{ edge, active },
		shift and CMD.OPT_SHIFT or 0
	)
	return true
end
function widget:Shutdown()
	if selector then
		selector:Dispose()
	end
	WG.PortalWorldView = nil
	WG.PortalDuelsView = nil
	WG.PortalAccessible = nil
	Spring.SetCameraBounds()
	Spring.SetMiniMapView()
	Spring.SetWorldDrawBounds()
end
