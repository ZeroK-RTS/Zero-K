-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
function widget:GetInfo()
	return {
		name = "Portal playtest capture",
		desc = "Save reproducible rendering state alongside F12 screenshots",
		author = "Codex",
		license = "GPL v2 or later",
		layer = 10007,
		enabled = true,
		handler = true,
	}
end
local options = Spring.GetModOptions()
if not options.zk_duels or options.zk_duels == "baseline" then
	return false
end
local json = Spring.Utilities.json
include("keysym.lua")
local pending, sequence, tested = nil, 0, false
local function Numbers(enum, count)
	return { gl.GetNumber(enum, count or 1) }
end
local function Capture()
	sequence = sequence + 1
	local lo, hi = Spring.GetDrawFrame()
	pending = {
		schema = 2,
		frameTimeOffset = Spring.GetFrameTimeOffset(),
		gameSpeed = { Spring.GetGameSpeed() },
		spectating = { Spring.GetSpectatingState() },
		myTeam = Spring.GetMyTeamID(),
		frame = Spring.GetGameFrame(),
		drawFrame = { lo, hi },
		camera = Spring.GetCameraState(),
		cameraVectors = Spring.GetCameraVectors(),
		viewGeometry = { Spring.GetViewGeometry() },
		windowGeometry = { Spring.GetWindowGeometry() },
		minimap = { Spring.GetMiniMapGeometry() },
		interfaceHidden = Spring.IsGUIHidden(),
		selected = Spring.GetSelectedUnits(),
		view = WG.PortalWorldView and WG.PortalWorldView.rect,
		portalOpen = Spring.GetGameRulesParam("zkduels_open"),
		passes = {},
		widgets = {},
		projectiles = {},
	}
	for _, w in ipairs(widgetHandler.widgets) do
		local values = {}
		for key, option in pairs(w.options or {}) do
			local value = option.value
			if type(value) == "number" or type(value) == "boolean" or type(value) == "string" then
				values[key] = value
			end
		end
		pending.widgets[w.whInfo.name] = values
	end
	-- The projectile-name API is unavailable in this engine. Optional diagnostic
	-- data must never prevent the camera and render-state capture from being saved.
	local ok, err = pcall(function()
		local lights = widgetHandler:FindWidget("Deferred rendering GL4")
		local get = lights and lights.SpringRestricted and lights.SpringRestricted.GetVisibleProjectiles
		for _, id in ipairs(get and get() or {}) do
			local x, y, z = Spring.GetProjectilePosition(id)
			if x then
				pending.projectiles[#pending.projectiles + 1] = {
					id = id,
					position = { x, y, z },
					velocity = { Spring.GetProjectileVelocity(id) },
					screen = { Spring.WorldToScreenCoords(x, y, z) },
				}
			end
		end
	end)
	if not ok then
		pending.projectileError = tostring(err)
	end
end
function widget:KeyPress(key, mods, isRepeat)
	if key == KEYSYMS.F12 and not isRepeat then
		Capture()
	end
	return false -- Keep the engine's normal F12 screenshot action.
end
function widget:DrawWorldPreParticles()
	if not pending then
		return
	end
	pending.passes[#pending.passes + 1] = {
		viewport = Numbers(0x0BA2, 4),
		scissor = Numbers(0x0C11),
		scissorBox = Numbers(0x0C10, 4),
		culling = Numbers(0x0B44),
		depthTest = Numbers(0x0B71),
		depthFunction = Numbers(0x0B74),
		depthMask = Numbers(0x0B72),
		blending = Numbers(0x0BE2),
		blendEquation = Numbers(0x8009),
		alphaTest = Numbers(0x0BC0),
		clip0 = Numbers(0x3000),
		clip3 = Numbers(0x3003),
		drawFramebuffer = Numbers(0x8CA6),
		readFramebuffer = Numbers(0x8CAA),
		drawBuffer = Numbers(0x0C01),
		readBuffer = Numbers(0x0C02),
		projection = { gl.GetMatrixData(GL.PROJECTION) },
		modelview = { gl.GetMatrixData(GL.MODELVIEW) },
	}
end
function widget:DrawScreenPost()
	if not pending then
		return
	end
	Spring.CreateDir("diagnostics")
	local path = string.format("diagnostics/portal-frame-%09d-%03d.json", pending.frame, sequence)
	local file, err = io.open(path, "w")
	if file then
		file:write(json.encode(pending))
		file:close()
		Spring.Echo("[PORTAL_CAPTURE] " .. path)
	else
		Spring.Echo("[PORTAL_CAPTURE] Failed to save: " .. tostring(err))
	end
	pending = nil
end
function widget:Update()
	if options.zk_duels_test == "capture" and not tested and Spring.GetGameFrame() >= 120 then
		tested = true
		self:KeyPress(KEYSYMS.F12, {}, false)
		Spring.SendCommands("screenshot png")
	end
end
