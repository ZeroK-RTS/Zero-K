include "constants.lua"

local base, turret, gun, triple, bolt, shell,
	brl1, brl2, brl3, flare1, flare2, flare3,
	door1, door2, bay1, bay2,
	tracks1, tracks2, tracks3, tracks4,
	wheels1, wheels2, wheels3, wheels4, wheels5, wheels6 = piece(
		"base", "turret", "gun", "triple", "bolt", "shell",
		"brl1", "brl2", "brl3", "flare1", "flare2", "flare3",
		"door1", "door2", "bay1", "bay2",
		"tracks1", "tracks2", "tracks3", "tracks4",
		"wheels1", "wheels2", "wheels3", "wheels4", "wheels5", "wheels6")

local gun_1 = 1
local tracks = 1
local isOpen = false
local isMoving = false

-- Signal definitions
local SIG_AIM = 2
local SIG_MOVE = 1 --Signal to prevent multiple track motion
local SIG_OPEN = 4

local RESTORE_DELAY = 1000

local WHEEL_SPIN_SPEED_L = math.rad(360)
local WHEEL_SPIN_DECEL_L = math.rad(30)
local WHEEL_SPIN_SPEED_S = math.rad(900)
local WHEEL_SPIN_DECEL_S = math.rad(75)

local BAY_SPEED = 20
local BAY2_DIST = 17
local BAY1_DIST = 15.693
local DOOR_SPEED = math.rad(120)
local DOOR1_ANGLE = math.rad(105)
local DOOR2_ANGLE = math.rad(-105)
local TURRET_HEIGHT = 8
local TURRET_SPEED = 20
local BARREL_EXTEND = 14.5
local BARREL_SPEED = 20
local TRIPLE_SPEED = math.rad(600)

local BOLT_RECOIL = -2.8
local BOLT_RESTORE_SPEED = 10
local BARREL_RECOIL = 7.5
local BARREL_RESTORE_SPEED = 20

local TURRET_YAW_SPEED = math.rad(30)
local TURRET_PITCH_SPEED = math.rad(30)

local TRACK_PERIOD = 50

local ableToMove = true
local function SetAbleToMove(newMove)
	if ableToMove == newMove then
		return
	end
	ableToMove = newMove
	
	Spring.SetUnitRulesParam(unitID, "selfTurnSpeedChange", (ableToMove and 1) or 0.05)
	Spring.SetUnitRulesParam(unitID, "selfMoveSpeedChange", (ableToMove and 1) or 0.05)
	GG.UpdateUnitAttributes(unitID)
	if newMove then
		GG.WaitWaitMoveUnit(unitID)
	end
end

local function TrackControl()
	SetSignalMask(SIG_MOVE)
	firstMove = false
	while isMoving do
		if ableToMove then
			if firstMove then
				firstMove = true
				Spin(wheels1, x_axis, WHEEL_SPIN_SPEED_L)
				Spin(wheels2, x_axis, WHEEL_SPIN_SPEED_L)
				Spin(wheels3, x_axis, WHEEL_SPIN_SPEED_L)
				Spin(wheels4, x_axis, WHEEL_SPIN_SPEED_S)
				Spin(wheels5, x_axis, WHEEL_SPIN_SPEED_S)
				Spin(wheels6, x_axis, WHEEL_SPIN_SPEED_L)
			end
			tracks = tracks + 1
			if tracks == 2 then
				Hide(tracks1)
				Show(tracks2)
			elseif tracks == 3 then
				Hide(tracks2)
				Show(tracks3)
			elseif tracks == 4 then
				Hide(tracks3)
				Show(tracks4)
			else
				tracks = 1
				Hide(tracks4)
				Show(tracks1)
			end
		end
		Sleep(TRACK_PERIOD)
	end
end

local function Open()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	SetAbleToMove(false)
	Move(bay2, z_axis, BAY2_DIST, BAY_SPEED)
	Move(bay1, z_axis, BAY1_DIST, BAY_SPEED)
	Turn(door1, z_axis, -DOOR1_ANGLE, DOOR_SPEED)
	Turn(door2, z_axis, -DOOR2_ANGLE, DOOR_SPEED)
	WaitForMove(bay2, z_axis)
	WaitForMove(bay1, z_axis)
	WaitForTurn(door1, z_axis)
	WaitForTurn(door2, z_axis)
	
	Move(turret, y_axis, TURRET_HEIGHT, TURRET_SPEED)
	WaitForMove(turret, y_axis)
	
	Move(brl1, z_axis, BARREL_EXTEND, BARREL_SPEED)
	Move(brl2, z_axis, BARREL_EXTEND, BARREL_SPEED)
	Move(brl3, z_axis, BARREL_EXTEND, BARREL_SPEED)
	WaitForMove(brl1, z_axis)
	WaitForMove(brl2, z_axis)
	WaitForMove(brl3, z_axis)
	
	isOpen = true
end

local function Close()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	Turn(turret, y_axis, 0, TURRET_YAW_SPEED)
	Turn(gun, x_axis, 0, TURRET_PITCH_SPEED)
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	
	isOpen = false
	
	Move(brl1, z_axis, 0, BARREL_SPEED)
	Move(brl2, z_axis, 0, BARREL_SPEED)
	Move(brl3, z_axis, 0, BARREL_SPEED)
	WaitForMove(brl1, z_axis)
	WaitForMove(brl2, z_axis)
	WaitForMove(brl3, z_axis)
	
	Move(turret, y_axis, 0, TURRET_SPEED)
	WaitForMove(turret, y_axis)
	
	Move(bay1, z_axis, 0, BAY_SPEED)
	Turn(door1, z_axis, 0, DOOR_SPEED)
	Turn(door2, z_axis,0, DOOR_SPEED)
	Move(bay2, z_axis, 0, BAY_SPEED)
	
	SetAbleToMove(true)
end

function script.StartMoving()
	--Spring.Utilities.UnitEcho(unitID, "START")
	Signal(SIG_MOVE)
	isMoving = true
	StartThread(TrackControl)
	StartThread(Close)
end

local function DelayStopMove()
	SetSignalMask(SIG_MOVE)
	Sleep(500)
	--Spring.Utilities.UnitEcho(unitID, "PPP")
	isMoving = false
	local oldX, oldY, oldZ = Spring.GetUnitPosition(unitID)
	while not isMoving do
		local x, y, z = Spring.GetUnitPosition(unitID)
		if math.abs(x - oldX) +  math.abs(y - oldY) +  math.abs(z - oldZ) > 24 then
			StartThread(Close)
			isMoving = true
			Sleep(400)
			isMoving = false
			oldX, oldY, oldZ = Spring.GetUnitPosition(unitID)
		end
		Sleep(166)
	end
end

function script.StopMoving()
	Signal(SIG_MOVE)
	StartThread(DelayStopMove)
	StopSpin(wheels1, x_axis, WHEEL_SPIN_DECEL_L)
	StopSpin(wheels2, x_axis, WHEEL_SPIN_DECEL_L)
	StopSpin(wheels3, x_axis, WHEEL_SPIN_DECEL_L)
	StopSpin(wheels4, x_axis, WHEEL_SPIN_DECEL_S)
	StopSpin(wheels5, x_axis, WHEEL_SPIN_DECEL_S)
	StopSpin(wheels6, x_axis, WHEEL_SPIN_DECEL_L)
end

function script.Create()
	Turn(shell, x_axis, math.rad(-90))
	StartThread(GG.Script.SmokeUnit, unitID, {base, gun})
	StartThread(DelayStopMove)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Close()
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	if isMoving then
		return false
	end
	
	if not isOpen then
		StartThread(Open)
		while not isOpen do
			Sleep(400)
		end
	end
	Turn(turret, y_axis, heading, TURRET_YAW_SPEED)
	Turn(gun, x_axis, -pitch, TURRET_PITCH_SPEED)
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.EndBurst()
	EmitSfx(shell, 1024)

	if gun_1 == 1 then
		Move(brl1, z_axis, BARREL_RECOIL)
		Move(brl1, z_axis, BARREL_EXTEND, BARREL_RESTORE_SPEED)
	elseif gun_1 == 2 then
		Move(brl2, z_axis, BARREL_RECOIL)
		Move(brl2, z_axis, BARREL_EXTEND, BARREL_RESTORE_SPEED)
	else
		Move(brl3, z_axis, BARREL_RECOIL)
		Move(brl3, z_axis, BARREL_EXTEND, BARREL_RESTORE_SPEED)
	end
	Move(bolt, z_axis, BOLT_RECOIL)
	Move(bolt, z_axis, 0, BOLT_RESTORE_SPEED)
	
	gun_1 = gun_1 + 1
	if gun_1 > 3 then
		gun_1 = 1
	end
	
	Sleep(100)
	Turn(triple, z_axis, math.rad(-120)*(gun_1 - 1), TRIPLE_SPEED)
end

function script.QueryWeapon(num)
	if gun_1 == 1 then
		return flare1
	elseif gun_1 == 2 then
		return flare2
	else
		return flare3
	end
end

function script.AimFromWeapon(num)
	return triple
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.25)  then
		Explode(brl1, SFX.SMOKE)
		Explode(brl2, SFX.SMOKE)
		Explode(brl3, SFX.SMOKE)
		return 1
	end
	if (severity < 0.5) then
		Explode(brl1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(brl2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(brl3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door1, SFX.SMOKE)
		Explode(door2, SFX.SMOKE)
		Explode(bay1, SFX.SMOKE)
		Explode(bay2, SFX.SMOKE)
		Explode(triple, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(bolt, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 1
	end
	if (severity < 1) then
		Explode(brl1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(brl2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(brl3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(door2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(bay1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(bay2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(triple, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(bolt, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		return 2
	end
	Explode(brl1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(brl2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(brl3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(door1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(door2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(bay1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(bay2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(gun, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(triple, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	Explode(bolt, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
	return 2
end
