include "constants.lua"
include "rockPiece.lua"
include "trackControl.lua"
include "pieceControl.lua"

local base, body, turret1, sleeve1, barrel1, firepoint1, turret2, sleeve2, gun2, firepoint2 
	= piece("base", "body", "turret1", "sleeve1", "barrel1", "firepoint1", "turret2", "sleeve2", "gun2", "firepoint2")
	
-- Signal definitions
local SIG_AIM1 = 1
local SIG_AIM2 = 2
local SIG_AIM3 = 4
local SIG_MOVE = 8
local SIG_ROCK_X = 16
local SIG_ROCK_Z = 32

local ROCK_FIRE_FORCE = 0.06
local ROCK_SPEED = 9
local ROCK_DECAY = -0.18
local ROCK_PIECE = base
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

rockData = {
	[x_axis] = {
		piece = ROCK_PIECE,
		speed = ROCK_SPEED,
		decay = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_X,
		axis = x_axis,
	},
	[z_axis] = {
		piece = ROCK_PIECE,
		speed = ROCK_SPEED,
		decay = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_ROCK_Z,
		axis = z_axis,
	},
}

local trackData = {
	wheels = {
		large = {piece('wheels1'), piece('wheels6')},
		small = {},
	},
	tracks = {},
	signal = SIG_MOVE,
	smallSpeed = math.rad(480),
	smallAccel = math.rad(80),
	smallDecel = math.rad(100),
	largeSpeed = math.rad(360),
	largeAccel = math.rad(40),
	largeDecel = math.rad(50),
	trackPeriod = 50,
}

for i = 1, 3 do
	trackData.tracks[i] = piece ('tracks' .. i)
end
for i = 2, 5 do
	trackData.wheels.small[i - 1] = piece('wheels' .. i)
end

local gunHeading = 0

local smokePiece = {base, turret1}

local RESTORE_DELAY = 3000
local LARGE_MUZZLE_FLASH_FX = 1024
local HUGE_MUZZLE_FLASH_FX = 1025

local ROCK_X_FIRE_1 = -24

local aimPoints = {
	turret1,
	turret2,
}
local firePoints = {
	firepoint1,
	firepoint2,
}

function RestoreMainGun()
	Sleep(RESTORE_DELAY)
	Turn(turret1, y_axis, 0, math.rad(45))
	Turn(sleeve1, x_axis, 0, math.rad(15))
end

function RestoreSideGun()
	Sleep(RESTORE_DELAY)
	Turn(turret2, y_axis, 0, math.rad(120))
	Turn(sleeve2, x_axis, 0, math.rad(90))
end

function RestoreBarrel()
	Sleep(125)
	Move(barrel1, z_axis, 0, 10)
end

function script.Create()
	InitializeRock(rockData)
	InitiailizeTrackControl(trackData)

	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end
	StartThread (SmokeUnit, smokePiece)
end

function script.StartMoving()
	StartThread(TrackControlStartMoving)
end

function script.StopMoving()
	TrackControlStopMoving()
end

-- Weapons
function script.AimFromWeapon(num)
	return aimPoints[num]
end

function script.QueryWeapon(num)
	return firePoints[num]
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		
		Turn(turret1, y_axis, heading, math.rad(90))
		Turn(sleeve1, x_axis, -pitch, math.rad(45))
		WaitForTurn(turret1, y_axis)
		WaitForTurn(sleeve1, x_axis)
		StartThread(RestoreMainGun)
		gunHeading = heading
		return true
	else
		Signal(SIG_AIM2)
		SetSignalMask(SIG_AIM2)

		Turn(turret2, y_axis, heading, math.rad(360))
		Turn(sleeve2, x_axis, -pitch, math.rad(180))
		WaitForTurn(turret2, y_axis)
		WaitForTurn(sleeve2, x_axis)

		StartThread(RestoreSideGun)
		return true
	end
end

function script.Shot(num)
	if num ~= 1 then
		return
	end
	StartThread(Rock, z_axis, gunHeading, ROCK_FIRE_FORCE)
	StartThread(Rock, x_axis, gunHeading - hpi, ROCK_FIRE_FORCE)
	
	EmitSfx(firepoint1, LARGE_MUZZLE_FLASH_FX)
	Move(barrel1, z_axis, -5)
	StartThread(RestoreBarrel)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.25) then
		Explode(turret1, sfxSmoke)
		return 1
	elseif (severity < 0.5) then
		Explode(barrel1, sfxFall)
		Explode(gun2, sfxShatter)
		Explode(sleeve1, sfxFall)
		Explode(turret1, sfxShatter)
		Explode(turret2, sfxFall)
		Explode(body, sfxSmoke)
		return 1
	elseif (severity < 1) then
		Explode(barrel1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(gun2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(turret1, sfxShatter)
		Explode(turret2, sfxShatter)
		return 2
	end
	
	Explode(barrel1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(gun2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(sleeve1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret1, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret2, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(body, sfxShatter)
	return 2
end
