-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return { name = "Portal arbitrary layout UI verification", layer = 10008, enabled = true, handler = true }
end
if Spring.GetModOptions().zk_duels_test ~= "layout" or Spring.GetModOptions().zk_duels_headless == "1" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local region, elapsed, pending = 1, 0, false
local function Check(name, pass)
	Spring.Echo("[LAYOUT_UI] ASSERT " .. name .. " pass=" .. tostring(not not pass))
end
function widget:Initialize()
	widgetHandler:DisableWidget("SmoothCam")
	widgetHandler:DisableWidget("Nubtron 2.0")
	widgetHandler:DisableWidget("Pause Screen")
end
function widget:Update(dt)
	if Spring.GetGameFrame() < 160 or not WG.PortalDuelsView then
		return
	end
	if region > #world.regions then
		Spring.SendCommands("quitforce")
		return
	end
	if not pending then
		Check("switch_" .. region, WG.PortalDuelsView(region))
		pending = true
		elapsed = 0
	else
		elapsed = elapsed + dt
	end
end
function widget:DrawScreenPost()
	if not pending or elapsed < 1 then
		return
	end
	local r = world.regions[region]
	Check("view_region_" .. region, WG.PortalWorldView.region == region)
	Check("material_region_" .. region, WG.PortalMapMaterial.region == region)
	local mx, my, mw, mh = Spring.GetMiniMapGeometry()
	local _, p = Spring.TraceScreenRay(mx + mw / 2, my + mh / 2, true, true)
	Check(
		"minimap_origin_" .. region,
		type(p) == "table"
			and math.abs(p[1] - (r.x0 + r.x1) / 2) < 30
			and math.abs(p[3] - (r.z0 + r.z1) / 2) < 30
	)
	local w, h = Spring.GetViewGeometry()
	Check("capture_" .. region, gl.SaveImage(0, 0, w, h, "screenshots/layout-" .. region .. ".png"))
	pending = false
	region = region + 1
end
