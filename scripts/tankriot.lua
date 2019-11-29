include "constants.lua"
include "rockPiece.lua"
include "trackControl.lua"
include "pieceControl.lua"
local dynamicRockData

local base, turret, sleeve = piece ('base', 'turret', 'sleeve')

local missiles = {
	piece ('dummy1'),
	piece ('dummy2'),
}

local SIG_AIM = 1
local SIG_MOVE = 2
local SIG_ROCK_X = 4
local SIG_ROCK_Z = 8

local ROCK_FIRE_FORCE = 0.06
local ROCK_SPEED = 18 --Number of half-cycles per second around x-axis.
local ROCK_DECAY = -0.25 --Rocking around axis is reduced by this factor each time = piece 'to rock.
local ROCK_PIECE = base -- should be negative to alternate rocking direction.
local ROCK_MIN = 0.001 --If around axis rock is not greater than this amount, rocking will stop after returning to center.
local ROCK_MAX = 1.5

local hpi = math.pi*0.5

local rockData = {
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
		large = {piece('wheels1'), piece('wheels8')},
		small = {},
	},
	tracks = {},
	signal = SIG_MOVE,
	smallSpeed = math.rad(540),
	smallAccel = math.rad(15),
	smallDecel = math.rad(45),
	largeSpeed = math.rad(360),
	largeAccel = math.rad(10),
	largeDecel = math.rad(30),
	trackPeriod = 66,
}

for i = 2, 7 do
	trackData.wheels.small[i-1] = piece('wheels' .. i)
end
for i = 1, 4 do
	trackData.tracks[i] = piece ('tracks' .. i)
end

local gunHeading = 0

local disarmed = false
local stuns = {false, false, false}
local isAiming = false
local currentMissile = 1
local smokePiece = {base, turret}

local function RestoreAfterDelay()
	SetSignalMask (SIG_AIM)

	Sleep (5000)

	Turn (turret, y_axis, 0, math.rad (50))
	Turn (sleeve, x_axis, 0, math.rad (50))

	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)
	isAiming = false
end

function StunThread()
	disarmed = true
	Signal (SIG_AIM)
	GG.PieceControl.StopTurn(turret, y_axis)
	GG.PieceControl.StopTurn(sleeve, x_axis)
end

function UnstunThread()
	disarmed = false
	if isAiming then
		StartThread(RestoreAfterDelay)
	end
end

function Stunned (stun_type)
	-- since only the turret is animated, treat all types the same since they all disable weaponry
	stuns[stun_type] = true
	StartThread (StunThread)
end

function Unstunned (stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread (UnstunThread)
	end
end

function script.StartMoving()
	StartThread(TrackControlStartMoving)
end

function script.StopMoving()
	TrackControlStopMoving()
end

function script.AimFromWeapon()
	return sleeve
end

function script.QueryWeapon()
	return missiles[currentMissile]
end

function script.AimWeapon(num, heading, pitch)
	Signal (SIG_AIM)
	SetSignalMask (SIG_AIM)

	isAiming = true

	while disarmed do
		Sleep (34)
	end

	local slowMult = (Spring.GetUnitRulesParam (unitID, "baseSpeedMult") or 1)
	Turn (turret, y_axis, heading, math.rad(200)*slowMult)
	Turn (sleeve, x_axis, -pitch, math.rad(200)*slowMult)

	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)
	StartThread (RestoreAfterDelay)

	gunHeading = heading

	return true
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
	StartThread(GG.ScriptRock.Rock, dynamicRockData[z_axis], gunHeading, ROCK_FIRE_FORCE)
	StartThread(GG.ScriptRock.Rock, dynamicRockData[x_axis], gunHeading - hpi, ROCK_FIRE_FORCE)
end

function script.EndBurst()
	currentMissile = 3 - currentMissile
end

function script.BlockShot(num, targetID)
	return GG.OverkillPrevention_CheckBlock(unitID, targetID, 420.5, 25)
end

function script.Create()
	dynamicRockData = GG.ScriptRock.InitializeRock(rockData)
	InitiailizeTrackControl(trackData)

	while (select(5, Spring.GetUnitHealth(unitID)) < 1) do
		Sleep (250)
	end

	Move (missiles[1], z_axis, 0.5)
	Move (missiles[2], z_axis, 0.5)

	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity < 0.5) then
		if (math.random() < 2*severity) then Explode (missiles[1], SFX.FALL + SFX.FIRE) end
		if (math.random() < 2*severity) then Explode (missiles[2], SFX.FALL + SFX.SMOKE) end
		return 1
	elseif (severity < 0.75) then
		if (math.random() < severity) then
			Explode (turret, SFX.FALL)
		end
		Explode(sleeve, SFX.FALL)
		Explode(trackData.tracks[1], SFX.SHATTER)
		Explode(missiles[1], SFX.FALL + SFX.SMOKE)
		Explode(missiles[2], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	else
		Explode(base, SFX.SHATTER)
		Explode(turret, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(sleeve, SFX.FALL + SFX.SMOKE + SFX.FIRE)
		Explode(trackData.tracks[1], SFX.SHATTER)
		Explode(missiles[1], SFX.FALL + SFX.SMOKE)
		Explode(missiles[2], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		return 2
	end
end
