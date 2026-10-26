-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Portal multiple maps UI verification",
		desc = "Opt-in connected selection, materials, minimap and screenshots",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10008,
		enabled = true,
		handler = true,
	}
end
if Spring.GetModOptions().zk_duels_headless == "1" or Spring.GetModOptions().zk_duels_test ~= "four" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local clickDeadline
local checked, stage, elapsed, pending, draws = {}, 0, 0, false, 0
local sequence = { 1, 2, 3, 4, 4, 3, 2, 1 }
local function Check(name, pass, detail)
	Spring.Echo("[FOUR_UI] ASSERT " .. name .. " pass=" .. tostring(not not pass) .. " " .. (detail or ""))
end
local function SelectorButtons()
	for _, child in ipairs(WG.Chili.Screen0.children) do
		if child.name == "System selector" then
			local count = 0
			for _, button in ipairs(child.children) do
				if button.classname == "button" then
					count = count + 1
				end
			end
			return count
		end
	end
	return 0
end
local function Near(a, b)
	if type(a) == "table" then
		for i = 1, #a do
			if not b[i] or math.abs(a[i] - b[i]) > 0.001 then
				return false
			end
		end
		return true
	end
	return math.abs(a - b) < 0.001
end
-- Keep tracing/selection real while checking emitted queue options for all
-- queue-key settings. Restore shared API functions even if a click fails.
local function CheckQueueKeys(ui, x, y)
	local getKeys, getInvert, giveOrder =
		Spring.GetModKeyState, Spring.GetInvertQueueKey, Spring.GiveOrderToUnitArray
	for _, invert in ipairs({ false, true }) do
		for _, shift in ipairs({ false, true }) do
			local sent
			Spring.GetModKeyState = function()
				return false, false, false, shift
			end
			Spring.GetInvertQueueKey = function()
				return invert
			end
			Spring.GiveOrderToUnitArray = function(ids, cmd, params, opts)
				sent = { ids = ids, cmd = cmd, params = params, opts = opts }
			end
			local ok, consumed = pcall(ui.MousePress, ui, x, y, 3)
			Spring.GetModKeyState, Spring.GetInvertQueueKey, Spring.GiveOrderToUnitArray =
				getKeys, getInvert, giveOrder
			Check(
				"portal_click_queue_shift_" .. tostring(shift) .. "_inverted_" .. tostring(invert),
				ok
					and consumed
					and sent
					and #sent.ids == 2
					and sent.cmd == Spring.Utilities.CMD.PORTAL_TRAVEL
					and sent.params[1] == 1
					and sent.params[2] == 1
					and sent.opts == (shift ~= invert and CMD.OPT_SHIFT or 0),
				not ok and tostring(consumed) or nil
			)
		end
	end
end
local function CheckActiveCommands(ui, x, y)
	local getActive, giveOrder = Spring.GetActiveCommand, Spring.GiveOrderToUnitArray
	for _, cmd in ipairs({ CMD.MOVE, CMD.ATTACK, -UnitDefNames.energysolar.id }) do
		local sent = false
		Spring.GetActiveCommand = function()
			return 1, cmd
		end
		Spring.GiveOrderToUnitArray = function()
			sent = true
		end
		local ok, consumed = pcall(ui.MousePress, ui, x, y, 3)
		Spring.GetActiveCommand, Spring.GiveOrderToUnitArray = getActive, giveOrder
		Check("portal_click_defers_active_command_" .. cmd, ok and consumed == false and not sent)
	end
end
function widget:Initialize()
	widgetHandler:DisableWidget("SmoothCam")
	widgetHandler:DisableWidget("Nubtron 2.0")
	widgetHandler:DisableWidget("Pause Screen")
end
function widget:Update(dt)
	local f = Spring.GetGameFrame()
	if not WG.PortalDuelsView or not WG.PortalAccessible or not WG.PortalWorldView then
		return
	end
	if f >= 60 and f < 120 and not checked.closed then
		checked.closed = true
		Check("selector_absent_before_open", SelectorButtons() == 0)
		for i = 2, #world.regions do
			Check("sealed_view_refused_" .. i, WG.PortalDuelsView(i) == false)
		end
		local ui = widgetHandler:FindWidget("Portal view bounds")
		Check(
			"n_does_not_switch_before_open",
			not ui:KeyPress(string.byte("n"), {}) and WG.PortalWorldView.region == 1
		)
	end
	if f >= 180 and f < 300 and not checked.partial then
		checked.partial = true
		Check("selector_only_connected_maps", SelectorButtons() == 2)
		Check("first_neighbour_accessible", WG.PortalAccessible(2))
		Check("unconnected_maps_remain_hidden", not WG.PortalAccessible(3) and not WG.PortalAccessible(4))
		Check("partial_graph_refuses_view", WG.PortalDuelsView(4) == false)
	end
	if f >= 710 and not checked.clickPrepared then
		checked.clickPrepared = true
		local beacon = Spring.GetGameRulesParam("four_click_beacon")
		local x, y, z = Spring.GetUnitPosition(beacon)
		WG.PortalDuelsView(
			1,
			{ name = "ta", mode = 1, px = x, py = y, pz = z, height = 900, angle = 0.05, flipped = 0 }
		)
		Spring.SelectUnitArray({
			Spring.GetGameRulesParam("four_click_unit"),
			Spring.GetGameRulesParam("four_other_selected"),
		})
		clickDeadline = Spring.GetDrawSeconds() + 0.35
	end
	if clickDeadline and Spring.GetDrawSeconds() > clickDeadline then
		clickDeadline = nil
		local beacon = Spring.GetGameRulesParam("four_click_beacon")
		local x, y, z = Spring.GetUnitPosition(beacon)
		local sx, sy = Spring.WorldToScreenCoords(x, y + 5, z)
		CheckQueueKeys(widgetHandler:FindWidget("Portal view bounds"), sx, sy)
		CheckActiveCommands(widgetHandler:FindWidget("Portal view bounds"), sx, sy)
		Check(
			"actual_portal_right_click",
			widgetHandler:FindWidget("Portal view bounds"):MousePress(sx, sy, 3) == true
		)
	end
	if f < 900 then
		return
	end
	if stage == 0 then
		Check("selector_lists_all_connected_maps", SelectorButtons() == #world.regions)
		for i = 1, #world.regions do
			Check("connected_accessible_" .. i, WG.PortalAccessible(i))
		end
		local ids = {}
		for i = 1, #world.regions do
			ids[i] = Spring.GetGameRulesParam("four_event_unit_" .. i)
		end
		Spring.SelectUnitArray(ids)
		Spring.SendCommands("pause")
		stage = 1
	end
	if stage > #sequence then
		Spring.SendCommands("pause")
		widgetHandler:RemoveWidget(self)
		return
	end
	if not pending then
		local region = sequence[stage]
		local r = world.regions[region]
		local x, z = (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2
		local close = stage > 4
		Check(
			"switch_accepted_" .. stage,
			WG.PortalDuelsView(region, {
				name = "ta",
				mode = 1,
				px = x,
				py = Spring.GetGroundHeight(x, z),
				pz = z,
				height = close and 850 or 5100,
				angle = close and 0.7 or 0.05,
				flipped = 0,
			})
		)
		local events = widgetHandler:FindWidget("MinimapEvents")
		for i = 1, #world.regions do
			local id = Spring.GetGameRulesParam("four_event_unit_" .. i)
			events:UnitDamaged(id, Spring.GetUnitDefID(id), 0, 100, false)
		end
		pending = true
		elapsed = 0
		draws = 0
	else
		elapsed = elapsed + dt
		draws = draws + 1
	end
end
function widget:DrawScreenPost()
	if not pending or elapsed < 0.65 or draws < 8 then
		return
	end
	local region = sequence[stage]
	local r = world.regions[region]
	local state = WG.PortalMapMaterial
	Check("material_region_" .. stage, state and state.region == region)
	local p = world.profiles[region]
	Check("dnts_scales_" .. stage, Near({ gl.GetMapRendering("splatTexScales") }, p.rendering.splatTexScales))
	Check(
		"dnts_strengths_" .. stage,
		Near({ gl.GetMapRendering("splatTexMults") }, p.rendering.splatTexMults)
	)
	Check("lighting_" .. stage, Near({ gl.GetSun("diffuse", "ground") }, p.sun.groundDiffuseColor))
	for slot = 0, 3 do
		local info = gl.TextureInfo("$ssmf_splat_normals:" .. slot)
		local source = gl.TextureInfo(p.textures[slot + 4][2])
		Check("dnts_texture_" .. stage .. "_" .. slot, info and source and info.id == source.id)
	end
	local camera = Spring.GetCameraState()
	Check("camera_in_active_region_" .. stage, world.Region(camera.px, camera.pz) == region)
	local mx, my, mw, mh = Spring.GetMiniMapGeometry()
	local _, hit = Spring.TraceScreenRay(mx + mw / 2, my + mh / 2, true, true)
	local error = type(hit) == "table"
			and math.sqrt((hit[1] - (r.x0 + r.x1) / 2) ^ 2 + (hit[3] - (r.z0 + r.z1) / 2) ^ 2)
		or math.huge
	Check("minimap_cropped_" .. stage, mw == mh and error < 30, "centerError=" .. error)
	Check(
		"selection_filtered_" .. stage,
		WG.PortalWorldSelectionCount == 1,
		"count=" .. tostring(WG.PortalWorldSelectionCount)
	)
	local events = WG.PortalMinimapEventTest
	Check(
		"foreign_minimap_events_hidden_" .. stage,
		events and events.damage == 1 and events.width == r.width and events.height == r.height,
		"damage=" .. tostring(events and events.damage)
	)
	local vsx, vsy = Spring.GetViewGeometry()
	Check(
		"capture_saved_" .. stage,
		gl.SaveImage(0, 0, vsx, vsy, "screenshots/four-" .. stage .. "-" .. r.id .. ".png")
	)
	stage = stage + 1
	pending = false
end
