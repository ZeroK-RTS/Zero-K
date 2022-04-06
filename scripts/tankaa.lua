include "constants.lua"
include "trackControl.lua"
include "pieceControl.lua"

local base, turret, guns, aim = piece("base", "turret", "guns", "aim")
local barrels = {piece("barrel1", "barrel2")}
local flares = {piece("flare1", "flare2")}
local a1, a2, neck = piece("a1", "a2", "neck")

local currentGun = 1
local isAiming = false

local disarmed = false
local stuns = {false, false, false}

local SIG_AIM = 1

local function RestoreAfterDelay()
	SetSignalMask (SIG_AIM)

	Sleep (5000)

	Turn (turret, y_axis, 0, 1)
	Turn (  guns, x_axis, 0, 1)

	WaitForTurn (turret, y_axis)
	WaitForTurn (  guns, x_axis)
	isAiming = false
end

local StopPieceTurn = GG.PieceControl.StopTurn
function Stunned(stun_type)
	stuns[stun_type] = true

	disarmed = true
	Signal (SIG_AIM)
	StopPieceTurn(turret, y_axis)
	StopPieceTurn(  guns, x_axis)
end

function Unstunned(stun_type)
	stuns[stun_type] = false

	if not stuns[1] and not stuns[2] and not stuns[3] then
		disarmed = false
		StartThread(RestoreAfterDelay)
	end
end

function script.StartMoving()
	StartThread(TrackControlStartMoving)
end

function script.StopMoving()
	TrackControlStopMoving()
end

function script.AimFromWeapon()
	return aim
end

function script.QueryWeapon()
	return flares[currentGun]
end

function script.AimWeapon(num, heading, pitch)
	Signal (SIG_AIM)
	SetSignalMask (SIG_AIM)

	isAiming = true
	while disarmed do
		Sleep (33)
	end

	local slowMult = (Spring.GetUnitRulesParam (unitID, "baseSpeedMult") or 1)
	Turn (turret, y_axis, heading, 10*slowMult)
	Turn (  guns, x_axis,  -pitch, 10*slowMult)

	WaitForTurn (turret, y_axis)
	WaitForTurn (  guns, x_axis)
	StartThread (RestoreAfterDelay)

	return true
end

function script.FireWeapon()
	EmitSfx(flares[currentGun], 1024)

	local barrel = barrels[currentGun]
	Move (barrel, z_axis, -14)
	Move (barrel, z_axis,   0, 21)

	currentGun = 3 - currentGun
end

function script.Create()
	local trax = {piece("tracks1", "tracks2", "tracks3", "tracks4")}
	Show(trax[1]) -- in case current != 1 before luarules reload
	Hide(trax[2])
	Hide(trax[3])
	Hide(trax[4])

	InitiailizeTrackControl({
		wheels = {
			large = {piece('wheels1', 'wheels2', 'wheels3')},
			small = {piece('wheels4', 'wheels5', 'wheels6')},
		},
		tracks = trax,
		signal = 2,
		smallSpeed = math.rad(360),
		smallAccel = math.rad(60),
		smallDecel = math.rad(120),
		largeSpeed = math.rad(540),
		largeAccel = math.rad(90),
		largeDecel = math.rad(180),
		trackPeriod = 50,
	})

	StartThread (GG.Script.SmokeUnit, unitID, {base, turret, guns})
end

local explodables = {a1, a2, neck, turret, barrels[1], barrels[2]}
function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	local brutal = severity > 0.5
	local sfx = SFX
	local explodeFX = sfx.FALL + (brutal and (sfx.SMOKE + sfx.FIRE) or 0)
	local rand = math.random

	for i = 1, #explodables do
		if rand() < severity then
			Explode (explodables[i], explodeFX)
		end
	end

	if brutal then
		Explode(base, sfx.SHATTER)
		return 2
	else
		return 1
	end
end
