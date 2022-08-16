include 'constants.lua'

local base, bay, gantry, clamp1, clamp2, missile, smoke, strobe = piece("base", "bay", "gantry", "clamp1", "clamp2", "missile", "smoke", "strobe")
local tracks1, tracks2, tracks3, tracks4 = piece("tracks1", "tracks2", "tracks3", "tracks4")

local wheels = { piece("wheels1", "wheels2", "wheels3", "wheels4", "wheels5", "wheels6") }

local smokePiece = {bay, gantry}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_AIM = 2
local SIG_MOVE = 1

local RESTORE_DELAY = 5000
local LOAD_DELAY = 1000
local RELEASE_DELAY = 400 -- How long gantry waits after missile leaves
local TRACK_PERIOD = 50

local BAY_DISTANCE = -10
local BAY_SPEED_LOADED = 7
local BAY_SPEED_UNLOADED = 7
local GANTRY_SPEED_LOADED = math.rad(90)
local GANTRY_SPEED_UNLOADED = math.rad(40)
local CLAMP_SPEED_LOADED = math.rad(360)
local CLAMP_SPEED_UNLOADED = math.rad(90)

local WHEEL_SPIN_SPEED = math.rad(720)
local WHEEL_SPIN_ACCEL = math.rad(100)
local WHEEL_SPIN_DECEL = math.rad(200)

local isLoaded, isReady, isMoving, doStrobe = true, false, false, false
local tracks = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function TrackControl()
	SetSignalMask(SIG_MOVE)
	while isMoving do
		for i = 1, #wheels do
			Spin(wheels[i], x_axis, WHEEL_SPIN_SPEED, WHEEL_SPIN_ACCEL)
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
		Sleep(TRACK_PERIOD)
	end
end

local function Prepare()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)

	Move(bay, x_axis, 0, BAY_SPEED_LOADED)
	WaitForMove(bay, x_axis)
	doStrobe = true
	Turn(gantry, x_axis, math.rad(-90), GANTRY_SPEED_LOADED)
	WaitForTurn(gantry, x_axis)
	Turn(clamp1, z_axis, math.rad(-90), CLAMP_SPEED_LOADED)
	Turn(clamp2, z_axis, math.rad( 90), CLAMP_SPEED_LOADED)
	WaitForTurn(clamp1, z_axis)
	WaitForTurn(clamp2, z_axis)
	isReady = true
end

local function Reload()
	Signal(SIG_OPEN)
	SetSignalMask(SIG_OPEN)
	if not isLoaded then   -- Just fired
		Sleep(RELEASE_DELAY)
	end
	isReady = false
	doStrobe = false
	if isLoaded then -- Slow retract if missile still there
		Turn(clamp1, z_axis, 0, CLAMP_SPEED_LOADED)
		Turn(clamp2, z_axis, 0, CLAMP_SPEED_LOADED)
		Turn(gantry, x_axis, 0, GANTRY_SPEED_LOADED)
		WaitForTurn(clamp1, z_axis)
		WaitForTurn(clamp2, z_axis)
		WaitForTurn(gantry, x_axis)
		Move(bay, x_axis, -BAY_DISTANCE, BAY_SPEED_LOADED)
	else
		Turn(clamp1, z_axis, 0, CLAMP_SPEED_UNLOADED)
		Turn(clamp2, z_axis, 0, CLAMP_SPEED_UNLOADED)
		Turn(gantry, x_axis, 0, GANTRY_SPEED_UNLOADED)
		WaitForTurn(clamp1, z_axis)
		WaitForTurn(clamp2, z_axis)
		WaitForTurn(gantry, x_axis)
		Move(bay, x_axis, -BAY_DISTANCE, BAY_SPEED_UNLOADED)
	end
	WaitForMove(bay, x_axis)

	if not isLoaded then -- Only wait if reload required
		Sleep(LOAD_DELAY)
	end
	isLoaded = true
	Show(missile)
end

function script.StartMoving()
	Signal(SIG_MOVE)
	isMoving = true
	StartThread(TrackControl)
end

local function DelayStopMove()
	SetSignalMask(SIG_MOVE)
	Sleep(500)
	isMoving = false
end

function script.StopMoving()
	Signal(SIG_MOVE)
	StartThread(DelayStopMove)
	for i = 1, #wheels do
		StopSpin(wheels[i], x_axis, WHEEL_SPIN_DECEL)
	end
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	StartThread(Reload)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	GG.DontFireRadar_CheckAim(unitID)

	if isLoaded then
		StartThread(Prepare)
		if doStrobe then
			EmitSfx(strobe, 1024)
		end
	end
	while (not isReady) do
		Sleep(250)
	end
	StartThread(RestoreAfterDelay)
	return true
end

function script.BlockShot(num, targetID)
	if not targetID then
		return false
	end
	if GG.DontFireRadar_CheckBlock(unitID, targetID) then
		return true
	end
	-- Seperation check is not required as the physics of the missile seems to result in a
	-- time to impact of between 140 and 150 frames in almost all cases.
	if GG.OverkillPrevention_CheckBlock(unitID, targetID, GG.OverkillPrevention_GetHealthThreshold(targetID, 800.1, 720.1), 150, false, false, true) then
		return true
	end
	return false
end

function script.QueryWeapon(num)
	return missile
end

function script.Shot(num)
	Hide(missile)
	isLoaded = false
	doStrobe = false
	StartThread(Reload)
end

function script.Create()
	Hide(tracks2)
	Hide(tracks3)
	Hide(tracks4)
	Move(bay, x_axis, -BAY_DISTANCE)
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(base, SFX.NONE)
		Explode(bay, SFX.NONE)
		Explode(gantry, SFX.NONE)
		Explode(clamp1, SFX.NONE)
		Explode(clamp2, SFX.NONE)
		Explode(missile, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(base, SFX.NONE)
		Explode(bay, SFX.NONE)
		Explode(gantry, SFX.FALL)
		Explode(clamp1, SFX.FALL)
		Explode(clamp2, SFX.FALL)
		Explode(missile, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(bay, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(gantry, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(clamp1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(clamp2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(missile, SFX.NONE)
		return 2
	end
end
