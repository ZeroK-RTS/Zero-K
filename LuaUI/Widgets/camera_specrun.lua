function widget:GetInfo()
	return {
	name      = "SpecRun",
	desc      = "Your own imaginary unit - V0.7",
	author    = "Regret",
	date      = "Feb 4, 2009",
	license   = "GNU GPL, v2 or later",
	layer     = 0,
	enabled   = false  --  loaded by default?
	}
end


--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------


local theKeybinds = {

	N		= "ControlsEnable",
	M 		= "ControlsDisable",
	
	TAB 	= "ToggleFlyMode",

	W 		= "MoveForward",
	S		= "MoveBackward",
	A 		= "StrafeLeft",
	D 		= "StrafeRight",
	
	SPACE 	= "Jump",
	SHIFT 	= "Run",

	F 		= "ToggleWaterWalk",
	R 		= "ToggleCrosshair",
	
	E 		= "IncreaseHeight",
	Q 		= "DecreaseHeight",
}

local theSettings = {

	MouseSensitivity 	= 2,

	Speed 				= 10,
	FlyingSpeed 		= 25,
	JumpStrength 		= 10,

	Height 				= 50,

	MaxSlope 			= 75,
	BounceFactor 		= 0.3, --sleksafactor!11   higher = more bounce,  less than 1 please
	Gravity 			= 4,

	FOV 				= 80, --field of view
	
}








--------------------------------------------------------------------------------
-- WARNING: TERRIBLE UNOPTIMIZED, LAZY AND (possibly) BUGGY CODE AHEAD
--------------------------------------------------------------------------------


local camera_mouse_sensitivity = theSettings.MouseSensitivity -- 1 pixel = 1 degrees per 10 sens

include("keysym.h.lua")

WG.SpecRunWidget = {}
WG.SpecRunWidget["misc"] = {}
--Spring.SendCommands({"viewta"})
WG.SpecRunWidget["UIColor"] = {0,1,0}
WG.SpecRunWidget["OriginalCameraState"] = Spring.GetCameraState()
WG.SpecRunWidget["cameraMaxpitch"] = 89
WG.SpecRunWidget["cameraMinpitch"] = -89
WG.SpecRunWidget["maxCameraHeading"] = 90 --bugged if more than 90, will fix  yes[ ] no[ ]  maby [x]      not currently used
WG.SpecRunWidget["FictionalUnitHeading"] = 0

WG.SpecRunWidget["FictionalUnitHeight"] = theSettings.Height
WG.SpecRunWidget["MaxSpeed"] = theSettings.Speed
WG.SpecRunWidget["MaxSlope"] = theSettings.MaxSlope
WG.SpecRunWidget["FlyingSpeed"] = theSettings.FlyingSpeed
WG.SpecRunWidget["JumpVel"] = theSettings.JumpStrength
WG.SpecRunWidget["Bounce"] = theSettings.BounceFactor
WG.SpecRunWidget["Gravity"] = theSettings.Gravity
WG.SpecRunWidget["ShowCrosshair"] = true
WG.SpecRunWidget["HoverOverWater"] = false
WG.SpecRunWidget["FlyMode"] = false

theSettings.acc = WG.SpecRunWidget["MaxSpeed"]*0.5
WG.SpecRunWidget["acc"] = theSettings.acc
theSettings.dec = WG.SpecRunWidget["MaxSpeed"]*0.25
WG.SpecRunWidget["dec"] = theSettings.dec

WG.SpecRunWidget["TurnRate"] = 1600 --not really used

WG.SpecRunWidget["MaxFictionalUnitHeight"] = 500

theSettings.HeightChangeSpeed = 1
WG.SpecRunWidget["HeightChangeSpeed"] = theSettings.HeightChangeSpeed


WG.SpecRunWidget["Speed"] = 0
local function resetSettings()
	WG.SpecRunWidget["FictionalUnitVelocity"] = {0,0,0}
	WG.SpecRunWidget["Turning"] = 0
	WG.SpecRunWidget["StrafeSpeed"] = 0
end


--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------


function widget:DrawScreen()
	if (WG.SpecRunWidget["camFocused"] == true) then
		Spring.SetMouseCursor("none")
	
		local r,g,b = unpack(WG.SpecRunWidget["UIColor"])
		local vsx, vsy = widgetHandler:GetViewSizes()
		local imageSizeX = 0
		local imageSizeY = 0
		local xyz = {}
		
		----------------------------------------
		-- crosshair
		if (WG.SpecRunWidget["ShowCrosshair"]) then
			imageSizeX = 3
			imageSizeY = 20
			
			xyz = {0.5 * vsx - imageSizeX/2, 0.5 * vsy - imageSizeY/2, 0} 
			gl.Translate(unpack(xyz)) -- set drawing pointer w/e
			
			gl.Color(r,g,b,0.5)
			
			gl.Rect(imageSizeX,imageSizeY,0,0)
			
			gl.Translate(-xyz[1],-xyz[2],-xyz[3]) -- restore drawing pointer
			
			----------------------------------------
			
			imageSizeX = 20
			imageSizeY = 3
			
			xyz = {0.5 * vsx - imageSizeX/2, 0.5 * vsy - imageSizeY/2, 0} 
			gl.Translate(unpack(xyz)) -- set drawing pointer w/e
			
			gl.Color(r,g,b,0.5)
			
			gl.Rect(imageSizeX,imageSizeY,0,0)
			
			gl.Translate(-xyz[1],-xyz[2],-xyz[3]) -- restore drawing pointer
			
			----------------------------------------
			
			imageSizeX = 3
			imageSizeY = 3
			
			xyz = {0.5 * vsx - imageSizeX/2, 0.5 * vsy - imageSizeY/2, 0} 
			gl.Translate(unpack(xyz)) -- set drawing pointer w/e
			
			gl.Color(1,0,0,1)
			
			gl.Rect(imageSizeX,imageSizeY,0,0)
			
			gl.Translate(-xyz[1],-xyz[2],-xyz[3]) -- restore drawing pointer
		end
		--
		----------------------------------------
	end
end


--------------------------------------------------------------------------------
--CAMERA
--------------------------------------------------------------------------------


local function angle_calc(a,b) -- support function for calculations with angles
	if ((a + b) > 360) then
		c = (a + b) - 360
	elseif ((a + b) < 0) then
		c = 360 + (a + b)
	else
		c = (a + b)
	end
	return c
end

local function lock_camera_on_unit()
	local current_cam_state = Spring.GetCameraState()
	
	----------------------------------------
	-- force free camera mode
	if (current_cam_state.name ~= "free") then
		Spring.SendCommands({"viewfree"}) -- set camera view to FREE mode
		current_cam_state = Spring.GetCameraState()
	end
	----------------------------------------
	
	----------------------------------------
	-- camera rotation with mouse
	local vsx, vsy = widgetHandler:GetViewSizes() --get resolution
	local mouse_x1,mouse_y1,_,_,_ = Spring.GetMouseState() --get mouse position
	local mouse_x2 = vsx * 0.5 --middle of screen
	local mouse_y2 = vsy * 0.5 --middle of screen
	
	
	local mouse_speed = camera_mouse_sensitivity / 180 * math.pi / 10 -- 1 pixel = 1 degrees per 10 sens
	local _,speedFactor,game_is_paused = Spring.GetGameSpeed()
	--if ((game_is_paused == false)) then
		Spring.WarpMouse(mouse_x2, mouse_y2) --set mouse to center of screen
		current_cam_state.rx = current_cam_state.rx + (speedFactor * mouse_speed * (mouse_y1 - mouse_y2))
		current_cam_state.ry = current_cam_state.ry - (speedFactor * mouse_speed * (mouse_x1 - mouse_x2))
	--end
	--
	----------------------------------------
	
	----------------------------------------
	-- 'normalization' of unit heading (0 to 360)
	local player_unit_heading = WG.SpecRunWidget["FictionalUnitHeading"]
	local player_unit_heading_rad = player_unit_heading / 32768 * math.pi
	if (math.abs(player_unit_heading_rad) < math.pi) then
		if (player_unit_heading_rad > 0) then
			player_unit_heading_rad = math.pi - (-player_unit_heading_rad + math.pi)
		elseif (player_unit_heading_rad < 0) then
			player_unit_heading_rad = math.pi - (-player_unit_heading_rad - math.pi)
		end
	end
	local player_unit_heading_deg = player_unit_heading_rad * 180/math.pi
	if (player_unit_heading_deg == -180) then
		player_unit_heading_deg = 180 --hahhahaha >.>
	end
	----------------------------------------
	
	----------------------------------------
	-- adjust camera heading to player unit heading changes
	if (previous_player_unit_heading == nil) then
		previous_player_unit_heading = player_unit_heading
	end
	local player_unit_heading_change = 0
	local player_unit_heading_change_rad = 0
	if (false) then --(previous_player_unit_heading ~= player_unit_heading) then
		local player_unit_heading_change = previous_player_unit_heading - player_unit_heading
		
		if (player_unit_heading_change > 32767) then
			player_unit_heading_change = player_unit_heading_change - 65536
		elseif (player_unit_heading_change < -32768) then
			player_unit_heading_change = player_unit_heading_change + 65536
		end
		
		local player_unit_heading_change_rad = player_unit_heading_change * math.pi / 32768
		camera_heading_rad = camera_heading_rad - player_unit_heading_change_rad
	else
		camera_heading_rad = current_cam_state.ry
		WG.SpecRunWidget["FictionalUnitHeading"] = camera_heading_rad * 32768 / math.pi
	end
	----------------------------------------
	
	----------------------------------------
	-- 'normalization' of camera heading (0 to 360)
	if (math.abs(camera_heading_rad) > math.pi) then
		if (camera_heading_rad > 0) then
			camera_heading_rad = -math.pi + (camera_heading_rad - math.pi)
		elseif (camera_heading_rad < 0) then
			camera_heading_rad = math.pi + (camera_heading_rad + math.pi)
		end
	end
	if (math.abs(camera_heading_rad) < math.pi) then
		if (camera_heading_rad > 0) then
			camera_heading_rad = math.pi - (-camera_heading_rad + math.pi)
		elseif (camera_heading_rad < 0) then
			camera_heading_rad = math.pi - (-camera_heading_rad - math.pi)
		end
	end
	local camera_heading_deg = camera_heading_rad * 180/math.pi
	----------------------------------------
	
	----------------------------------------
	-- calculate camera angle offset relative to player unit (-180 to 180) 
	if (camera_heading_deg <= 180) then
		if ((player_unit_heading_deg - camera_heading_deg) <= 180) then
			camera_offset_deg = player_unit_heading_deg - camera_heading_deg
		else
			camera_offset_deg = -(camera_heading_deg - player_unit_heading_deg) - 360
		end
	elseif (camera_heading_deg > 180) then
		if ((-(camera_heading_deg - player_unit_heading_deg) + 360) <= 180) then
			camera_offset_deg = -(camera_heading_deg - player_unit_heading_deg) + 360
		else
			camera_offset_deg = player_unit_heading_deg - camera_heading_deg
		end
	end
	WG.SpecRunWidget["cameraOffset"] = camera_offset_deg
	----------------------------------------
	
	----------------------------------------
	-- force maximum and minimum camera pitch
	local aim_max_pitch_deg = WG.SpecRunWidget["cameraMaxpitch"]
	local aim_min_pitch_deg = WG.SpecRunWidget["cameraMinpitch"]
	local camera_pitch_rad = current_cam_state.rx
	local camera_pitch_deg = camera_pitch_rad * 180/math.pi
	if (camera_pitch_deg > aim_max_pitch_deg) then
		camera_pitch_deg = aim_max_pitch_deg
		camera_pitch_rad = aim_max_pitch_deg / 180*math.pi
	elseif (camera_pitch_deg < aim_min_pitch_deg) then
		camera_pitch_deg = aim_min_pitch_deg
		camera_pitch_rad = aim_min_pitch_deg / 180*math.pi
	end
	----------------------------------------
	
	----------------------------------------
	-- force maximum and minimum camera heading
	local aim_max_heading_deg = WG.SpecRunWidget["maxCameraHeading"]
	if (camera_offset_deg > aim_max_heading_deg) then
		camera_offset_deg = aim_max_heading_deg
		camera_heading_deg = angle_calc(player_unit_heading_deg-180,aim_max_heading_deg)
	elseif (camera_offset_deg < -aim_max_heading_deg) then
		camera_offset_deg = -aim_max_heading_deg
		camera_heading_deg = angle_calc(player_unit_heading_deg,aim_max_heading_deg)
	end
	camera_heading_rad = camera_heading_deg / 180*math.pi
	----------------------------------------
	
	----------------------------------------
	-- configure camera
	--current_cam_state.px = camera_pos_x -- cam pos x
	--current_cam_state.py = camera_pos_y -- cam pos y
	--current_cam_state.pz = camera_pos_z -- cam pos z
	
	current_cam_state.rx = camera_pitch_rad -- pitch
	current_cam_state.ry = camera_heading_rad -- heading, shifts accordingly with unit heading
	
	current_cam_state.fov = theSettings.FOV
	current_cam_state.gndOffset = 0
	current_cam_state.gravity = 0
	current_cam_state.slide = 0
	current_cam_state.scrollSpeed = 0
	current_cam_state.tiltSpeed = 0
	current_cam_state.velTime = 0
	current_cam_state.avelTime = 0
	current_cam_state.autoTilt = 0
	current_cam_state.goForward = -1
	current_cam_state.invertAlt = -1
	current_cam_state.gndLock = -1
	--
	----------------------------------------
	
	Spring.SetCameraState(current_cam_state,0.2) -- refresh camera, 0.2 = smooth ; 0.0 = stupid laggage
	
	previous_player_unit_heading = player_unit_heading -- needed to determine unit heading changes
end

--------------------------------------------------------------------------------
-- CONTROLS
--------------------------------------------------------------------------------

local function cleanUI()
	Spring.SendCommands({
		--"resbar 0",
		--"minimap minimize 0",
		--"tooltip 0",
		--"showhealthbars 1",
	})
end

local function restoreUI()
	Spring.SendCommands({
		--"resbar 1",
		--"minimap minimize 0",
		--"tooltip 1",
		--"showhealthbars 1",
	})
end

local theKey_functions = {
	["MoveForward"] = {function()
			if (WG.SpecRunWidget["FlyMode"]) then
				local distance = WG.SpecRunWidget["FlyingSpeed"]
				local current_cam_state = Spring.GetCameraState()
				current_cam_state.px = current_cam_state.px + (distance * math.sin(current_cam_state.ry)) --heading rad
				current_cam_state.py = current_cam_state.py + (distance * math.tan(current_cam_state.rx)) --pitch rad
				current_cam_state.pz = current_cam_state.pz + (distance * math.cos(current_cam_state.ry)) --heading rad
				Spring.SetCameraState(current_cam_state,0)
				resetSettings()
			end
			
			WG.SpecRunWidget["Speed"] = 100
			WG.SpecRunWidget["misc"]["MovingForward"] = true
			return "repeat"
		end,
		function()
			if (WG.SpecRunWidget["misc"]["MovingBackward"] ~= true) then
				WG.SpecRunWidget["Speed"] = 0
			end
			WG.SpecRunWidget["misc"]["MovingForward"] = false
			return
		end},
	
	["MoveBackward"] = {function()
			if (WG.SpecRunWidget["FlyMode"]) then
				local distance = WG.SpecRunWidget["FlyingSpeed"]
				local current_cam_state = Spring.GetCameraState()
				current_cam_state.px = current_cam_state.px - (distance * math.sin(current_cam_state.ry)) --heading rad
				current_cam_state.py = current_cam_state.py - (distance * math.tan(current_cam_state.rx)) --pitch rad
				current_cam_state.pz = current_cam_state.pz - (distance * math.cos(current_cam_state.ry)) --heading rad
				Spring.SetCameraState(current_cam_state,0)
				resetSettings()
			end
	
			WG.SpecRunWidget["Speed"] = -100
			WG.SpecRunWidget["misc"]["MovingBackward"] = true
			return "repeat"
		end,
		function()
			if (WG.SpecRunWidget["misc"]["MovingForward"] ~= true) then
				WG.SpecRunWidget["Speed"] = 0
			end
			WG.SpecRunWidget["misc"]["MovingBackward"] = false
			return
		end},
		
	["StrafeLeft"] = {function()
			if (WG.SpecRunWidget["FlyMode"]) then
				local distance = WG.SpecRunWidget["FlyingSpeed"]
				local current_cam_state = Spring.GetCameraState()
				current_cam_state.px = current_cam_state.px + (distance * math.cos(current_cam_state.ry)) --heading rad
				current_cam_state.pz = current_cam_state.pz - (distance * math.sin(current_cam_state.ry)) --heading rad
				Spring.SetCameraState(current_cam_state,0)
				resetSettings()
			end
	
			WG.SpecRunWidget["StrafeSpeed"] = 75
			WG.SpecRunWidget["misc"]["StrafingLeft"] = true
			return "repeat"
		end,
		function()
			if (WG.SpecRunWidget["misc"]["StrafingRight"] ~= true) then
				WG.SpecRunWidget["StrafeSpeed"] = 0
			end
			WG.SpecRunWidget["misc"]["StrafingLeft"] = false
			return
		end},
		
	["StrafeRight"] = {function()
			if (WG.SpecRunWidget["FlyMode"]) then
				local distance = WG.SpecRunWidget["FlyingSpeed"]
				local current_cam_state = Spring.GetCameraState()
				current_cam_state.px = current_cam_state.px - (distance * math.cos(current_cam_state.ry)) --heading rad
				current_cam_state.pz = current_cam_state.pz + (distance * math.sin(current_cam_state.ry)) --heading rad
				Spring.SetCameraState(current_cam_state,0)
				resetSettings()
			end
			
			WG.SpecRunWidget["StrafeSpeed"] = -75
			WG.SpecRunWidget["misc"]["StrafingRight"] = true
			return "repeat"
		end,
		function()
			if (WG.SpecRunWidget["misc"]["StrafingLeft"] ~= true) then
				WG.SpecRunWidget["StrafeSpeed"] = 0
			end
			WG.SpecRunWidget["misc"]["StrafingRight"] = false
			return
		end},
		
	["Jump"] = {function()
			if (not WG.SpecRunWidget["FlyMode"]) then
				WG.SpecRunWidget["jump"] = true
			end
			return "repeat"
		end},
		
	["IncreaseHeight"] = {function()
			WG.SpecRunWidget["FictionalUnitHeight"] = WG.SpecRunWidget["FictionalUnitHeight"] + WG.SpecRunWidget["HeightChangeSpeed"]
			if (WG.SpecRunWidget["FictionalUnitHeight"] > WG.SpecRunWidget["MaxFictionalUnitHeight"]) then
				WG.SpecRunWidget["FictionalUnitHeight"] = WG.SpecRunWidget["MaxFictionalUnitHeight"]
			end
			local ratio = (WG.SpecRunWidget["FictionalUnitHeight"] / theSettings.Height)
			WG.SpecRunWidget["MaxSpeed"] = theSettings.Speed * ratio
			WG.SpecRunWidget["FlyingSpeed"] = theSettings.FlyingSpeed * ratio
			WG.SpecRunWidget["JumpVel"] = theSettings.JumpStrength * ratio
			WG.SpecRunWidget["acc"] = theSettings.acc * ratio
			WG.SpecRunWidget["dec"] = theSettings.dec * ratio
			
			WG.SpecRunWidget["FictionalUnitVelocity"] = {0,-100,0}
			
			if (not WG.SpecRunWidget["FlyMode"]) then
				WG.SpecRunWidget["Gravity"] = theSettings.Gravity * ratio
			end
			
			return "repeat"
		end,
		function()
			WG.SpecRunWidget["FictionalUnitVelocity"] = {0,0,0}
			return
		end},
		
	["DecreaseHeight"] = {function()
			WG.SpecRunWidget["FictionalUnitHeight"] = WG.SpecRunWidget["FictionalUnitHeight"] - WG.SpecRunWidget["HeightChangeSpeed"]
			if (WG.SpecRunWidget["FictionalUnitHeight"] < 5) then
				WG.SpecRunWidget["FictionalUnitHeight"] = 5
			end
			local ratio = (WG.SpecRunWidget["FictionalUnitHeight"] / theSettings.Height)
			WG.SpecRunWidget["MaxSpeed"] = theSettings.Speed * ratio
			WG.SpecRunWidget["FlyingSpeed"] = theSettings.FlyingSpeed * ratio
			WG.SpecRunWidget["JumpVel"] = theSettings.JumpStrength * ratio
			WG.SpecRunWidget["acc"] = theSettings.acc * ratio
			WG.SpecRunWidget["dec"] = theSettings.dec * ratio
			
			WG.SpecRunWidget["FictionalUnitVelocity"] = {0,-100,0}
			
			if (not WG.SpecRunWidget["FlyMode"]) then
				WG.SpecRunWidget["Gravity"] = theSettings.Gravity * ratio
			end
			
			return "repeat"
		end,
		function()
			WG.SpecRunWidget["FictionalUnitVelocity"] = {0,0,0}
			return
		end},

	["Run"] = {function()
			WG.SpecRunWidget["MaxSpeed"] = WG.SpecRunWidget["MaxSpeed"] * 2
			WG.SpecRunWidget["FlyingSpeed"] = WG.SpecRunWidget["FlyingSpeed"] * 4
			WG.SpecRunWidget["HeightChangeSpeed"] = WG.SpecRunWidget["HeightChangeSpeed"] * 10
			return
		end,
		function()
			local ratio = (WG.SpecRunWidget["FictionalUnitHeight"] / theSettings.Height)
			WG.SpecRunWidget["MaxSpeed"] = theSettings.Speed * ratio
			WG.SpecRunWidget["FlyingSpeed"] = theSettings.FlyingSpeed * ratio
			WG.SpecRunWidget["HeightChangeSpeed"] = theSettings.HeightChangeSpeed
			return
		end},

	["ToggleWaterWalk"] = {function()
			WG.SpecRunWidget["HoverOverWater"] = not WG.SpecRunWidget["HoverOverWater"]
			if (WG.SpecRunWidget["HoverOverWater"]) then
				Spring.Echo("Waterwalking enabled")
			else
				Spring.Echo("Waterwalking disabled")
			end
			return
		end},

	["ToggleFlyMode"] = {function()
			WG.SpecRunWidget["FlyMode"] = not WG.SpecRunWidget["FlyMode"]
			if (WG.SpecRunWidget["FlyMode"]) then
				WG.SpecRunWidget["Gravity"] = 0
				Spring.Echo("Flying enabled")
			else
				local ratio = (WG.SpecRunWidget["FictionalUnitHeight"] / theSettings.Height)
				WG.SpecRunWidget["Gravity"] = theSettings.Gravity * ratio
				Spring.Echo("Flying disabled")
			end
			return
		end},
	
	["ToggleCrosshair"] = {function()
			WG.SpecRunWidget["ShowCrosshair"] = not WG.SpecRunWidget["ShowCrosshair"]
			return
		end},
		
	["ControlsDisable"] = {function()
			if (WG.SpecRunWidget["controlsEnabled"] == true) then
				WG.SpecRunWidget["controlsEnabled"] = false
				
				WG.SpecRunWidget["Speed"] = 0
				
				if (WG.SpecRunWidget["camFocused"] == true) then --restore camera
					WG.SpecRunWidget["camFocused"] = false
					local current_cam_state = Spring.GetCameraState()
					WG.SpecRunWidget["OriginalCameraState"].px = current_cam_state.px
					WG.SpecRunWidget["OriginalCameraState"].pz = current_cam_state.pz
					Spring.SetCameraState(WG.SpecRunWidget["OriginalCameraState"], 1.0)
					
					Spring.SendCommands({
						"viewta", --set camera view to TA mode
					}) 
					
					restoreUI()
					
					local vsx, vsy = widgetHandler:GetViewSizes()
					Spring.WarpMouse(vsx * 0.5, vsy * 0.5)
				end
				
				Spring.SendCommands({"keyreload"})
				Spring.SendCommands({
						"unbindkeyset  Any+f11",
						"unbindkeyset Ctrl+f11",
						"bind    f11  luaui selector",
						"bind  C+f11  luaui tweakgui",
						})
				Spring.Echo("SpecRun disabled")
				
				--reset stuff
				WG.SpecRunWidget["FictionalUnitHeight"] = theSettings.Height
				WG.SpecRunWidget["MaxSpeed"] = theSettings.Speed
				WG.SpecRunWidget["MaxSlope"] = theSettings.MaxSlope
				WG.SpecRunWidget["FlyingSpeed"] = theSettings.FlyingSpeed
				WG.SpecRunWidget["JumpVel"] = theSettings.JumpStrength
				WG.SpecRunWidget["Bounce"] = theSettings.BounceFactor
				WG.SpecRunWidget["Gravity"] = theSettings.Gravity
				WG.SpecRunWidget["ShowCrosshair"] = true
				WG.SpecRunWidget["HoverOverWater"] = false
				WG.SpecRunWidget["FlyMode"] = false
				
				return --dont repeat while key down
			end
			return "repeat"
		end},
	
	["ControlsEnable"] = {function()
			if (WG.SpecRunWidget["camFocused"] ~= true) then
				local mouse_x,mouse_y,_,_,_ = Spring.GetMouseState() --get mouse position
				local _,mousePointedCoord = Spring.TraceScreenRay(mouse_x,mouse_y,true) -- get mouse pointed coordinates
				if (mousePointedCoord ~= nil) then --aiming at something other than sky
					local current_cam_state = Spring.GetCameraState()
					if (current_cam_state.name ~= "free") then
						Spring.SendCommands({"viewfree"}) -- set camera view to FREE mode
						current_cam_state = Spring.GetCameraState()
					end
					current_cam_state.px, current_cam_state.py, current_cam_state.pz = unpack(mousePointedCoord)
					current_cam_state.rx = 0
					current_cam_state.ry = -math.pi
					Spring.SetCameraState(current_cam_state,2)
				else --aiming at sky
					return
				end
				
				if (WG.SpecRunWidget["controlsEnabled"] ~= true) then
					WG.SpecRunWidget["controlsEnabled"] = true
					WG.SpecRunWidget["camFocused"] = true
					Spring.Echo("SpecRun enabled")
					
					resetSettings()
					
					for keyname,_ in pairs(theKeybinds) do --ignore uikeys.txt binds on overlap
						if (string.sub(keyname,1,5) ~= "MOUSE") then --leftover from copypasta
							Spring.SendCommands({"unbindkeyset "..string.lower(keyname)})
							Spring.SendCommands({"unbindkeyset Any+"..string.lower(keyname)})
						end
					end
					
					cleanUI()

					local vsx, vsy = widgetHandler:GetViewSizes()
					Spring.WarpMouse(vsx * 0.5, vsy * 0.5)
				end
			end
			return
		end},
}

function widget:Initialize()
	keysyms_original = KEYSYMS --from keysym.h.lua
	keysyms_inverted = {}
	for keyname,keyid in pairs(keysyms_original) do
		keysyms_inverted[keyid] = keyname
	end
	
	WG.SpecRunWidget["keyTable"] = {}
	for keyname,keyfunction in pairs(theKeybinds) do --load the binds
		if (keyfunction == "ControlsEnable") then
			maincontrolswitchkey = keyname --used to enable these controls
			theKeybinds[keyname] = nil
		else
			local func = {theKey_functions[keyfunction]}
			--this stuff is here 'cause KEYSYMS in lua aren't the same as spring ones
			if (keysyms_original["L"..keyname] or keysyms_original["R"..keyname]) then --spring uikeys.txt doesnt differenciate between left or right keys, f.e. shift
				WG.SpecRunWidget["keyTable"]["L"..keyname] = func
				WG.SpecRunWidget["keyTable"]["R"..keyname] = func
			elseif (type(tonumber(keyname)) == "number") then --nombers
				if ((tonumber(keyname) >= 0) and (tonumber(keyname) <= 9)) then
					WG.SpecRunWidget["keyTable"]["N_"..keyname] = func
				end
			else
				WG.SpecRunWidget["keyTable"][keyname] = func
			end
			----
		end
	end
end

function widget:KeyRelease(key)
	local key_name = keysyms_inverted[key]
	if ((WG.SpecRunWidget["controlsEnabled"] == true) or
	((theKeybinds[key_name] == "ControlsDisable") and ((WG.SpecRunWidget["controlsEnabled"] == false)))) then
		if (WG.SpecRunWidget["keyTable"][key_name] ~= nil) then
			WG.SpecRunWidget["keyTable"][key_name]["isPressed"] = false
			WG.SpecRunWidget["keyTable"][key_name]["isReleased"] = true
			if (type(WG.SpecRunWidget["keyTable"][key_name][1][2]) == "function") then
				WG.SpecRunWidget["keyTable"][key_name][1][2]()
			end
		end
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	local key_name = keysyms_inverted[key]
	if (WG.SpecRunWidget["controlsEnabled"] == true) then
		--local key_name = keysyms_inverted[key]
		if (WG.SpecRunWidget["keyTable"][key_name] ~= nil) then
			if (WG.SpecRunWidget["keyTable"][key_name]["isReleased"] ~= false) then
				WG.SpecRunWidget["keyTable"][key_name]["isReleased"] = false
				WG.SpecRunWidget["keyTable"][key_name]["isPressed"] = true
			end
		end
	end
	if (key == keysyms_original[maincontrolswitchkey]) then
		theKey_functions["ControlsEnable"][1]()
	end
end

function handleControls()
	for key_name,_ in pairs(WG.SpecRunWidget["keyTable"]) do
		if (WG.SpecRunWidget["keyTable"][key_name]["isPressed"] == true) then
			if (type(WG.SpecRunWidget["keyTable"][key_name][1][1]) == "function") then
				local output = WG.SpecRunWidget["keyTable"][key_name][1][1]()
				if (output == "repeat") then
					WG.SpecRunWidget["keyTable"][key_name]["isPressed"] = true
					WG.SpecRunWidget["keyTable"][key_name]["isReleased"] = true
				else
					WG.SpecRunWidget["keyTable"][key_name]["isPressed"] = false
					WG.SpecRunWidget["keyTable"][key_name]["isReleased"] = false
				end
			end
		end
	end
end


--------------------------------------------------------------------------------
-- PHYSICS
--------------------------------------------------------------------------------


local function unitIsTouchingSomething()
	local minDistance = 1 --minimum distance for it to validate as touching
	local current_cam_state = Spring.GetCameraState()
	
	if (WG.SpecRunWidget["HoverOverWater"]) then
		if ((current_cam_state.py-WG.SpecRunWidget["FictionalUnitHeight"]) < minDistance) then
			return true
		end
	end
	
	
	if ((current_cam_state.py-WG.SpecRunWidget["FictionalUnitHeight"]) < Spring.GetGroundHeight(current_cam_state.px,current_cam_state.pz)+minDistance) then
		return true
	end
	
	return false
end

local function HandleUnitPhysics()
	----------------------------------------
	-- unit properties
	local current_cam_state = Spring.GetCameraState()
	local unitX,unitY,unitZ = current_cam_state.px,current_cam_state.py,current_cam_state.pz
	local curGroundHeight = Spring.GetGroundHeight(unitX,unitZ)
	
	local heading = WG.SpecRunWidget["FictionalUnitHeading"]
	local heading_rad = heading / 32768 * math.pi
	
	local velX,velY,velZ = unpack(WG.SpecRunWidget["FictionalUnitVelocity"])
	local vecHeadingX,vecHeadingZ = Spring.GetVectorFromHeading(heading)
	
	local velocity = math.sqrt(velX^2 + velZ^2)
	if (velocity == 0) then
		vecVelocityX = 0
		vecVelocityZ = 0
	else
		vecVelocityX = velX/velocity
		vecVelocityZ = velZ/velocity
	end
	
	local reqVel = WG.SpecRunWidget["Speed"] --requested velocity in % of max velocity
	local maxVel = WG.SpecRunWidget["MaxSpeed"]
	local minVel = maxVel / -1 --max backwards velocity is this much lower than forward    -1 == equal
	local acc = WG.SpecRunWidget["acc"]
	local dec = WG.SpecRunWidget["dec"]
	
	if (reqVel < 0) then --calculate real requested velocity from %
		reqVel = minVel * (reqVel / -100)
	else
		reqVel = maxVel * (reqVel / 100)
	end
	--
	----------------------------------------
	
	----------------------------------------
	-- slope
	local maxSlope = WG.SpecRunWidget["MaxSlope"]
	
	local hxmax = math.max(Spring.GetGroundHeight(unitX-1,unitZ),Spring.GetGroundHeight(unitX+1,unitZ))-curGroundHeight
	local hxmin = math.min(Spring.GetGroundHeight(unitX-1,unitZ),Spring.GetGroundHeight(unitX+1,unitZ))-curGroundHeight
	
	local hzmax = math.max(Spring.GetGroundHeight(unitX,unitZ-1),Spring.GetGroundHeight(unitX,unitZ+1))-curGroundHeight
	local hzmin = math.min(Spring.GetGroundHeight(unitX,unitZ-1),Spring.GetGroundHeight(unitX,unitZ+1))-curGroundHeight
	
	local hmax = math.sqrt(hxmax^2 + hzmax^2)
	local hmin = math.sqrt(hxmin^2 + hzmin^2)
	
	local curSlope = math.atan(hmax+hmin/2) * 180/math.pi --degrees
	
	local frontX = unitX + math.sin(heading_rad) --position of the 'pixel' in front of unit
	local frontZ = unitZ + math.cos(heading_rad) --
	
	if (Spring.GetGroundHeight(frontX,frontZ) > curGroundHeight) then
		reqVel = (1 - math.min(curSlope,maxSlope) / maxSlope) * reqVel
	end
	--
	----------------------------------------
	
	----------------------------------------
	-- acceleration
	local accX = 0
	local accZ = 0
	if(math.abs(velocity) < math.abs(reqVel)) then
		if (reqVel < 0) then
			accX = -acc*math.sin(heading_rad)
			accZ = -acc*math.cos(heading_rad)
		else
			accX = acc*math.sin(heading_rad)
			accZ = acc*math.cos(heading_rad)
		end
	end
	
	if (velocity > 0) then
		local realDec = math.min(math.abs(dec),math.abs(velocity))
		accX = accX - realDec * (velX/velocity)
		accZ = accZ - realDec * (velZ/velocity)
	end
	--
	----------------------------------------
	
	----------------------------------------
	-- strafing
	local reqSVel = WG.SpecRunWidget["StrafeSpeed"]
	
	local Svelocity = -velZ*math.sin(heading_rad)+velX*math.cos(heading_rad)
	reqSVel = maxVel * (reqSVel / 100)
	
	local SaccX = 0
	local SaccZ = 0
	
	if(math.abs(Svelocity) < math.abs(reqSVel)) then
		if (reqSVel < 0) then
			SaccX = -acc*math.cos(heading_rad)
			SaccZ = acc*math.sin(heading_rad)
		else
			SaccX = acc*math.cos(heading_rad)
			SaccZ = -acc*math.sin(heading_rad)
		end
	end
	
	velX = velX + SaccX + accX
	velZ = velZ + SaccZ+ accZ
	--
	----------------------------------------
	
	----------------------------------------
	-- rotation
	local rotDir = WG.SpecRunWidget["Turning"] --requested rotation direction
	local turnRate = WG.SpecRunWidget["TurnRate"]
	
	local maxheading = 32767
	local minheading = -32768
	
	local newheading = heading+turnRate*rotDir
	
	if (newheading < minheading) then
		if (newheading < maxheading) then
			newheading = math.abs(minheading) - math.abs(newheading)
			newheading = maxheading + newheading
		end
	end
	
	if (newheading > maxheading) then
		newheading = math.abs(newheading) - math.abs(maxheading)
		newheading = minheading + newheading
	end
	
	WG.SpecRunWidget["FictionalUnitHeading"] = newheading
	--
	----------------------------------------
	
	if (unitIsTouchingSomething()) then
		if (WG.SpecRunWidget["jump"] == true) then
			velY = velY + WG.SpecRunWidget["JumpVel"]
			WG.SpecRunWidget["jump"] = false
		end
		WG.SpecRunWidget["FictionalUnitVelocity"] = {velX,velY,velZ}
	else --else unit is in air
		WG.SpecRunWidget["jump"] = false
	end
	
	velX,velY,velZ = unpack(WG.SpecRunWidget["FictionalUnitVelocity"])
	
	--hardcore math
	velY = velY - (WG.SpecRunWidget["Gravity"]/8)  --8, because 8!
	unitX = unitX + velX
	unitZ = unitZ + velZ
	unitY = unitY + velY
	
	----------------------------------------
	-- force map limits
	local mapMinX,mapMinZ = 0, 0
	local mapMaxX,mapMaxZ = Game.mapX * 512, Game.mapY * 512
	
	if (unitX < mapMinX) then
		unitX = mapMinX
	end
	if (unitX > mapMaxX) then
		unitX = mapMaxX
	end
	
	if (unitZ < mapMinZ) then
		unitZ = mapMinZ
	end
	if (unitZ > mapMaxZ) then
		unitZ = mapMaxZ
	end
	
	
	if ((unitY-WG.SpecRunWidget["FictionalUnitHeight"]) < Spring.GetGroundHeight(unitX,unitZ))
	then
		unitY = Spring.GetGroundHeight(unitX,unitZ)+WG.SpecRunWidget["FictionalUnitHeight"]
		velY = -(velY*WG.SpecRunWidget["Bounce"])
	end
	
	if (WG.SpecRunWidget["HoverOverWater"]) then
		if ((unitY-WG.SpecRunWidget["FictionalUnitHeight"]) < 0) then
			unitY = WG.SpecRunWidget["FictionalUnitHeight"]
			velY = -(velY*WG.SpecRunWidget["Bounce"])
		end
	end
	--
	----------------------------------------
	
	WG.SpecRunWidget["FictionalUnitVelocity"] = {velX,velY,velZ}
	current_cam_state.px, current_cam_state.py, current_cam_state.pz = unitX,unitY,unitZ
	Spring.SetCameraState(current_cam_state,0)
end

function widget:GameOver()
	theKey_functions["ControlsDisable"][1]()
end


--------------------------------------------------------------------------------
-- HEART
--------------------------------------------------------------------------------


local function Heartbeat()
	handleControls()
	if (WG.SpecRunWidget["camFocused"] == true) then
		HandleUnitPhysics()
		lock_camera_on_unit()
	end
end

local currentframe = 0
local _,_,paused = Spring.GetGameSpeed()
if (paused) then
	currentframe = 1 --quick fix for widget reload when paused
end

function widget:GameFrame(n)
	currentframe = n
	if (n>0) then
		local _,_,paused = Spring.GetGameSpeed()
		if (not paused) then
			Heartbeat()
		end
	end
end

local frequency = 30
local framecount = 0
local framerate = Spring.GetFPS()
function widget:Update()
	----------------------------------------
	-- Attempt at creating a gamestate independant GameFrame call
	local _,_,paused = Spring.GetGameSpeed()
	if (paused or (currentframe==0)) then
		if ((framerate ~= Spring.GetFPS()) or (framecount > framerate)) then
			framecount = 0
		end
		framerate = Spring.GetFPS()
		
		if (framerate >= frequency) then
			if ((framecount % math.floor((framerate/frequency) + 0.5)) == 0) then
				Heartbeat()
			end
		else
			local framestodo = ((frequency-(frequency % framerate)) / framerate)
			local extraframes = frequency % framerate
			while (framestodo > 0) do
				Heartbeat()
				framestodo = framestodo - 1
				if (extraframes > 0) then --this section could be neater
					Heartbeat()
					extraframes = extraframes - 1 
				end
			end
		end
		
		framecount = framecount + 1
	end
	--
	----------------------------------------
end
