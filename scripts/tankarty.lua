include "constants.lua"
include "rockPiece.lua"
include "trackControl.lua"
include "pieceControl.lua"

local main = piece 'main' 
local turret = piece 'turret' 
local outer = piece 'outer' 
local inner = piece 'inner' 
local sleeve = piece 'sleeve' 
local barrel = piece 'barrel' 
local flare = piece 'flare' 
local breech = piece 'breech' 
local smoke = piece 'smoke'

local gunHeading = 0

local RESTORE_DELAY = 3000

-- Signal definitions
local SIG_AIM = 1
local SIG_MOVE = 2 --Signal to prevent multiple track motion
local SIG_TILT = 4
local SIG_RAISE = 8
local SIG_PUSH = 16

local TURRET_SPEED = math.rad(35)
local TURRET_SPEED_2 = math.rad(70)

local BARREL_DISTANCE = -4
local BREECH_DISTANCE = -2
local BARREL_SPEED = 1
local BREECH_SPEED = 0.5

local smokePiece = {main, smoke}

local ROCK_FIRE_FORCE_TILT = 0.2
local ROCK_FIRE_FORCE_PUSH = 8

local ROCK_SPEED = 7 --Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.3 --Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = main -- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 40

local rockData = {
	[1] = {
		piece = main,
		speed = ROCK_SPEED,
		decay = ROCK_DECAY,
		minPos = ROCK_MIN,
		maxPos = ROCK_MAX,
		signal = SIG_TILT,
		minSpeed = 0.05,
		axis = z_axis,
		extraEffect = function (pos, speed)
			Move(main, y_axis, math.abs(pos)*25, speed*25)
		end
	},
	[2] = {
		piece = main,
		speed = 8,
		minSpeed = 2,
		decay = 0,
		minPos = 0.1,
		maxPos = 10,
		signal = SIG_PUSH,
		axis = z_axis,
	},
}

local trackData = {
	wheels = {
		large = {},
		small = {piece('wheels1'), piece('wheels8')},
	},
	tracks = {},
	signal = SIG_MOVE,
	smallSpeed = math.rad(540),
	smallAccel = math.rad(30),
	smallDecel = math.rad(50),
	largeSpeed = math.rad(360),
	largeAccel = math.rad(20),
	largeDecel = math.rad(75),
	trackPeriod = 50,
}

for i = 1, 4 do
	trackData.tracks[i] = piece ('tracks' .. i)
end
for i = 2, 7 do
	trackData.wheels.large[i-1] = piece ('wheels' .. i)
end

function script.StartMoving()
	StartThread(TrackControlStartMoving)
end

function script.StopMoving()
	TrackControlStopMoving()
end

function script.Create()
	InitializeRock(rockData)
	InitiailizeTrackControl(trackData)
	
	Hide(flare)
	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end
	StartThread (SmokeUnit, smokePiece)
end

local function RestoreAfterDelay()
	Sleep(RESTORE_DELAY)
	Turn(turret, y_axis, 0, TURRET_SPEED)
	Turn(outer, x_axis, 0, TURRET_SPEED)
	Turn(inner, x_axis, 0, TURRET_SPEED_2)
	Turn(sleeve, x_axis, 0, TURRET_SPEED_2)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(turret, y_axis, heading, TURRET_SPEED)
	Turn(outer, x_axis, -pitch, TURRET_SPEED)
	Turn(inner, x_axis, 2 * pitch, TURRET_SPEED_2)
	Turn(sleeve, x_axis, -2 * pitch, TURRET_SPEED_2)
	WaitForTurn(turret, y_axis)
	WaitForTurn(sleeve, x_axis)
	StartThread(RestoreAfterDelay)
	gunHeading = heading
	return true
end

function script.FireWeapon()
	StartThread(Rock, 1, gunHeading, ROCK_FIRE_FORCE_TILT)
	StartThread(Push, 2, gunHeading - hpi, ROCK_FIRE_FORCE_PUSH)
	Move(barrel, z_axis, BARREL_DISTANCE)
	Move(breech, z_axis, BREECH_DISTANCE)
	Move(barrel, z_axis, 0, BARREL_SPEED)
	Move(breech, z_axis, 0, BREECH_SPEED)
end

function script.AimFromWeapon(num)
	return barrel
end

function script.QueryWeapon(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.25) then
		return 1
	elseif (severity < 0.5) then
		corpsetype = 1
		Explode(barrel, sfxFall)
		Explode(breech, sfxFall)
		Explode(sleeve, sfxFall)
		Explode(turret, sfxShatter)
		return 1
	elseif(severity < 1) then
		Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(breech, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(sleeve, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(turret, sfxShatter)
		return 2
	end
	Explode(barrel, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(breech, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(sleeve, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret, sfxShatter + sfxExplodeOnHit)
	return 2
end
