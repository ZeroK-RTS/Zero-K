include "constants.lua"


local base, body, lift, turret, cradle, rear, nano, cab, firepoint = piece('base', 'body', 'lift', 'turret', 'cradle', 'rear', 'nano', 'cab', 'firepoint')
local panel_t, panel_r, panel_l, panel_b = piece('panel_t', 'panel_r', 'panel_l', 'panel_b')
local door1, door2 = piece('door1', 'door2')
local rwheel1, rwheel2, rwheel3, rwheel4 = piece('rwheel1', 'rwheel2', 'rwheel3', 'rwheel4')
local lwheel1, lwheel2, lwheel3, lwheel4 = piece('lwheel1', 'lwheel2', 'lwheel3', 'lwheel4')
local fwheel = piece('fwheel')
local rbrace1, rbrace2 = piece('rbrace1', 'rbrace2')
local lbrace1, lbrace2 = piece('lbrace1', 'lbrace2')
local rguard1, rguard2 = piece('rguard1', 'rguard2')
local lguard1, lguard2 = piece('lguard1', 'lguard2')

local smokePiece = {body, turret}

local wheels = {fwheel, rwheel1, rwheel2, rwheel3, rwheel4, lwheel1, lwheel2, lwheel3, lwheel4}

local SIG_MOVE = 1
local SIG_BUILD = 2

local WHEEL_TURN_SPEED = math.rad(480)
local WHEEL_ACCELERATION = math.rad(75)
local WHEEL_DECELERATION = math.rad(200)
local MOVE_SPEED_CLOSE = 10
local MOVE_SPEED_OPEN = 20
local TURN_SPEED_CLOSE = math.rad(160)
local TURN_SPEED_OPEN = math.rad(240)
local DOOR_ANGLE_Z = math.rad(160)
local PANEL_ANGLE_MIN = math.rad(60)
local PANEL_ANGLE_MAX = math.rad(90)
local TURRET_Y_MAX = 1.5
local TURRET_Y_MIN = 0.5

local wheel_cnt = #wheels
function script.StartMoving()
	for i = 1, wheel_cnt do
		Spin (wheels[i], x_axis, WHEEL_TURN_SPEED, WHEEL_ACCELERATION)
	end
end

function script.StopMoving()
	for i = 1, wheel_cnt do
		StopSpin (wheels[i], x_axis, WHEEL_DECELERATION)
	end
end

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Spring.SetUnitNanoPieces(unitID, {firepoint})
end

local function RestoreAfterDelay()
	Signal(SIG_BUILD)
	SetSignalMask(SIG_BUILD)
	Sleep(5000)

	Move (nano, z_axis, 0, MOVE_SPEED_CLOSE)
	Move (rear, z_axis, 0, MOVE_SPEED_CLOSE)
	Turn (panel_t, x_axis, 0, TURN_SPEED_CLOSE)
	Turn (panel_b, x_axis, 0, TURN_SPEED_CLOSE)
	Turn (panel_l, y_axis, 0, TURN_SPEED_CLOSE)
	Turn (panel_r, y_axis, 0, TURN_SPEED_CLOSE)
	Turn (turret, y_axis, 0, TURN_SPEED_CLOSE)
	Turn (cradle, x_axis, 0, TURN_SPEED_CLOSE)
	WaitForTurn (turret, y_axis)
	WaitForTurn (cradle, x_axis)

	Move (lift, y_axis, 0, MOVE_SPEED_CLOSE)
	Move (turret, y_axis, 0, MOVE_SPEED_CLOSE)
	Sleep (250)

	Turn (door1, z_axis, 0, TURN_SPEED_CLOSE)
	Turn (door2, z_axis, 0, TURN_SPEED_CLOSE)
end

function script.StopBuilding()
	SetUnitValue(COB.INBUILDSTANCE, 0)
	StartThread(RestoreAfterDelay)
end

local math_random = math.random
function script.StartBuilding(heading, pitch)
	Signal (SIG_BUILD)
	SetSignalMask (SIG_BUILD)

	Turn (door1, z_axis,  DOOR_ANGLE_Z, TURN_SPEED_OPEN)
	Turn (door2, z_axis, -DOOR_ANGLE_Z, TURN_SPEED_OPEN)
	Sleep (250)

	Move (lift, y_axis, 4.5, MOVE_SPEED_OPEN)
	Move (turret, y_axis, TURRET_Y_MAX, MOVE_SPEED_OPEN)
	WaitForMove (lift, y_axis)

	Move (nano, z_axis, 2, MOVE_SPEED_OPEN)
	Move (rear, z_axis, -1.2, MOVE_SPEED_OPEN)
	Turn (panel_t, x_axis, -PANEL_ANGLE_MIN, TURN_SPEED_OPEN)
	Turn (panel_b, x_axis,  PANEL_ANGLE_MIN, TURN_SPEED_OPEN)
	Turn (panel_l, y_axis,  PANEL_ANGLE_MIN, TURN_SPEED_OPEN)
	Turn (panel_r, y_axis, -PANEL_ANGLE_MIN, TURN_SPEED_OPEN)
	Turn (turret, y_axis, heading, TURN_SPEED_OPEN)
	Turn (cradle, x_axis, -pitch, TURN_SPEED_OPEN)
	WaitForTurn (turret, y_axis)
	WaitForTurn (cradle, x_axis)

	SetUnitValue(COB.INBUILDSTANCE, 1)

	-- misleading-ass wobble
	local rand = math_random
	while true do
		if rand() < 0.33 then
			Move (turret, y_axis, TURRET_Y_MIN + (rand() * (TURRET_Y_MAX - TURRET_Y_MIN)), MOVE_SPEED_OPEN)

			local rand_panel_angle = PANEL_ANGLE_MIN + (rand() * (PANEL_ANGLE_MAX - PANEL_ANGLE_MIN))
			Turn (panel_t, x_axis, -rand_panel_angle, TURN_SPEED_OPEN)
			Turn (panel_b, x_axis,  rand_panel_angle, TURN_SPEED_OPEN)
			Turn (panel_l, y_axis,  rand_panel_angle, TURN_SPEED_OPEN)
			Turn (panel_r, y_axis, -rand_panel_angle, TURN_SPEED_OPEN)
		end
		Sleep (250)
	end
end

function script.QueryNanoPiece()
	GG.LUPS.QueryNanoPiece(unitID,unitDefID,Spring.GetUnitTeam(unitID), firepoint)
	return firepoint
end

local explodables = {nano, rear, cradle, panel_t, panel_b, panel_l, panel_r, turret, fwheel, rwheel1}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = (severity > 0.5)
	local sfx = SFX

	local effect = sfx.FALL + (brutal and (sfx.SMOKE + sfx.FIRE) or 0)
	for i = 1, #explodables do
		if math.random() < severity then
			Explode (explodables[i], effect)
		end
	end

	if not brutal then
		return 1
	else
		Explode (base, sfx.SHATTER)
		return 2
	end
end
