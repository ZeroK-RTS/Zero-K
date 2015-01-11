include "constants.lua"
include "pieceControl.lua"

local base, turret, sleeve = piece ('base', 'turret', 'sleeve')

local missiles = {
	piece ('dummy1'),
	piece ('dummy2'),
}

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

local function RestoreAfterDelay()
	Signal (SIG_Restore)
	SetSignalMask (SIG_Restore)

	Sleep (8000)

	isAiming = false
	Turn (turret, y_axis, 0, math.rad (10))
	Turn (sleeve, x_axis, 0, math.rad (10))
	StartThread (IdleAnim)
end

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

	StartThread (IdleAnim)
end

function IdleAnim ()
	if (isAiming or isMoving) then 
		return 
	end
	SetSignalMask(SIG_Aim + SIG_Move)

	while true do
		Turn (turret, y_axis, math.rad(math.random(-20, 20)), math.rad(5))
		WaitForTurn (turret, y_axis)
		Sleep (math.random(2000, 6000))
	end
end

function Stunned(isFull) -- future disarm/EMP obedience
	StopTurn (turret, y_axis)
	StopTurn (sleeve, x_axis)
end

function script.StartMoving ()
	isMoving = true
	StartThread (TracksControl)
end

function script.StopMoving ()
	isMoving = false
end

function script.AimFromWeapon ()
	return sleeve
end

function script.QueryWeapon ()
	return missiles[currentMissile]
end

function script.FireWeapon ()
	currentMissile = 3 - currentMissile
end

function script.Shot ()
	Hide (missiles[currentMissile])
	Move (missiles[currentMissile], z_axis, -7.5)
	Sleep (500)
	Show (missiles[currentMissile])
	Move (missiles[currentMissile], z_axis, 0, 2.5)
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

	return (Spring.GetUnitRulesParam (unitID, "disarmed") ~= 1)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.5) then
		Explode (missiles[1], sfxFall + sfxFire)
		Explode (missiles[2], sfxFall + sfxSmoke)
		return 1
	elseif (severity < 0.75) then
		Explode (turret, sfxFall) 
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

function script.Create()
	for i = 2, 4 do
		Hide (tracks[i])
	end

	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end

	StartThread (SmokeUnit, smokePiece)
end
