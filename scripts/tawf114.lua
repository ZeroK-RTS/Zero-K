include "constants.lua"
include "RockPiece.lua"
include "pieceControl.lua"

local base, turret, sleeve = piece ('base', 'turret', 'sleeve')

local missiles = {
	piece ('dummy1'),
	piece ('dummy2'),
}

local SIG_ROCK_X = 8
local SIG_ROCK_Z = 16

local ROCK_FIRE_FORCE = 0.06
local ROCK_SPEED = 18		--Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.25	--Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base	-- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

local gunHeading = 0

local tracks = {}
for i = 1, 4 do
	tracks[i] = piece ('tracks' .. i)
end

local wheels = {
	large = { piece('wheels1'), piece('wheels8') },
	small = {},
}
for i = 2, 7 do
	wheels.small[i-1] = piece ('wheels' .. i)
end

local SIG_Restore = 1
local SIG_Aim = 2
local SIG_Move = 4

local isMoving = false
local isAiming = false
local currentMissile = 1
local currentTracks = 1

local smokePiece = {base, turret}

function TracksControl()
	Signal (SIG_Move)
	SetSignalMask (SIG_Move)

	for i = 1, #wheels.large do
		Spin (wheels.large[i], x_axis, math.rad(360), math.rad(10))
	end
	for i = 1, #wheels.small do
		Spin (wheels.small[i], x_axis, math.rad(540), math.rad(15))
	end

	while isMoving do
		Hide (tracks[currentTracks])
		currentTracks = (currentTracks == 4) and 1 or (currentTracks + 1)
		Show (tracks[currentTracks])
		Sleep (66)
	end

	for i = 1, #wheels.large do
		StopSpin (wheels.large[i], x_axis, math.rad(30))
	end
	for i = 1, #wheels.small do
		StopSpin (wheels.small[i], x_axis, math.rad(45))
	end
end

function Stunned(isFull) -- future disarm/EMP obedience
	Signal (SIG_Restore)
	StopTurn(turret, y_axis)
	StopTurn(sleeve, x_axis)
end

function script.StartMoving()
	isMoving = true
	StartThread(TracksControl)
end

function script.StopMoving()
	isMoving = false
end

local function RestoreAfterDelay()
	Signal (SIG_Restore)
	SetSignalMask (SIG_Restore)

	Sleep (8000)

	isAiming = false
	Turn (turret, y_axis, 0, math.rad (50))
	Turn (sleeve, x_axis, 0, math.rad (50))
end


function script.AimFromWeapon()
	return sleeve
end

function script.QueryWeapon()
	return missiles[currentMissile]
end

function script.AimWeapon(num, heading, pitch)
	Signal (SIG_Aim)
	SetSignalMask (SIG_Aim)

	isAiming = true

	while (Spring.GetUnitRulesParam(unitID, "disarmed") == 1) do
		Sleep (33)
	end

	local slowMult = (1 - (Spring.GetUnitRulesParam (unitID, "slowState") or 0))
	Turn (turret, y_axis, heading, math.rad(200)*slowMult)
	Turn (sleeve, x_axis, -pitch,  math.rad(200)*slowMult)

	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)

	StartThread (RestoreAfterDelay)
	gunHeading = heading

	return (Spring.GetUnitRulesParam (unitID, "disarmed") ~= 1)
end


local function ReloadThread(missile)
	Hide (missiles[missile])
	Move (missiles[missile], z_axis, -3)
	Sleep (4000)
	Show (missiles[missile])
	Move (missiles[missile], z_axis, 0.5, 1)
end

function script.FireWeapon()
	StartThread(ReloadThread, currentMissile)
	StartThread(Rock, gunHeading, ROCK_FIRE_FORCE, z_axis)
	StartThread(Rock, gunHeading - hpi, ROCK_FIRE_FORCE, x_axis)
	currentMissile = 3 - currentMissile
end

function script.Create()

	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_X, x_axis)
	InitializeRock(ROCK_PIECE, ROCK_SPEED, ROCK_DECAY, ROCK_MIN, ROCK_MAX, SIG_ROCK_Z, z_axis)
	
	for i = 2, 4 do
		Hide (tracks[i])
	end

	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end

	Move (missiles[1], z_axis, 0.5)
	Move (missiles[2], z_axis, 0.5)
	
	StartThread (SmokeUnit, smokePiece)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.5) then
		if (math.random() < 2*severity) then Explode (missiles[1], sfxFall + sfxFire) end
		if (math.random() < 2*severity) then Explode (missiles[2], sfxFall + sfxSmoke) end
		return 1
	elseif (severity < 0.75) then
		if (math.random() < severity) then 
			Explode (turret, sfxFall) 
		end
		Explode (sleeve, sfxFall)
		Explode (tracks[1], sfxShatter)
		Explode (missiles[1], sfxFall + sfxSmoke)
		Explode (missiles[2], sfxFall + sfxSmoke + sfxFire)
		return 2
	else
		Explode (base, sfxShatter)
		Explode (turret, sfxFall + sfxSmoke  + sfxFire)
		Explode (sleeve, sfxFall + sfxSmoke  + sfxFire)
		Explode (tracks[1], sfxShatter)
		Explode (missiles[1], sfxFall + sfxSmoke)
		Explode (missiles[2], sfxFall + sfxSmoke + sfxFire)
		return 2
	end
end
