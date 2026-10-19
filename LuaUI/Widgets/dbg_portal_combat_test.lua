-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return { name = "Portal combat rendering captures", layer = 10008, enabled = true, handler = true }
end
if Spring.GetModOptions().zk_duels_test ~= "combat" then
	return false
end
local world = VFS.Include("LuaRules/Utilities/portal_worlds.lua")
local stage, elapsed, pending, paused = 1, 0, false, false
function widget:Initialize()
	for _, name in ipairs({ "SmoothCam", "Nubtron 2.0", "Pause Screen" }) do
		widgetHandler:DisableWidget(name)
	end
end
function widget:Update(dt)
	if Spring.GetGameFrame() < 910 or not WG.PortalDuelsView then
		return
	end
	if not paused then
		paused = true
		Spring.SendCommands({ "pause", "hideinterface" })
	end
	if stage > #world.regions * 3 then
		Spring.SendCommands("quitforce")
		return
	end
	if not pending then
		local region = math.floor((stage - 1) / 3) + 1
		local camera = (stage - 1) % 3
		local r = world.regions[region]
		local x, z =
			r.x0 + r.width * (camera == 0 and 0.5 or 0.73), r.z0 + r.height * (camera == 0 and 0.5 or 0.7)
		WG.PortalDuelsView(
			region,
			{
				name = "ta",
				mode = 1,
				px = x,
				py = Spring.GetGroundHeight(x, z),
				pz = z,
				height = camera == 0 and 3900 or 800,
				angle = camera == 2 and 0.05 or 0.85,
				flipped = 0,
			}
		)
		pending = true
		elapsed = 0
	else
		elapsed = elapsed + dt
	end
end
function widget:DrawScreenPost()
	if not pending or elapsed < 0.8 then
		return
	end
	local w, h = Spring.GetViewGeometry()
	local path = "screenshots/combat-" .. stage .. ".png"
	Spring.Echo(
		"[COMBAT_UI] ASSERT capture_" .. stage .. " pass=" .. tostring(gl.SaveImage(0, 0, w, h, path))
	)
	pending = false
	stage = stage + 1
end
