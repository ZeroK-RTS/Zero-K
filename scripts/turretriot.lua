include "constants.lua"
include "pieceControl.lua"

local base, turret, sleeve, barrel, flare, muzzle, ejector = piece('base', 'turret', 'sleeve', 'barrel', 'flare', 'muzzle', 'ejector')

local explodables = {barrel, flare, sleeve, turret}
local smokePiece = { base, turret }

local stuns = {false, false, false}
local disarmed = false

local SigAim = 1

local function RestoreAfterDelay()
	Sleep (5000)
	Turn (turret, y_axis, 0, math.rad(10))
	Turn (sleeve, x_axis, 0, math.rad(10))
end

local function StunThread()
	Signal (SigAim)
	SetSignalMask(SigAim)
	disarmed = true

	GG.PieceControl.StopTurn (turret, y_axis)
	GG.PieceControl.StopTurn (sleeve, x_axis)
end

local function UnstunThread()
	disarmed = false
	SetSignalMask(SigAim)
	RestoreAfterDelay()
end

function Stunned(stun_type)
	stuns[stun_type] = true
	StartThread(StunThread)
end

function Unstunned(stun_type)
	stuns[stun_type] = false
	if not stuns[1] and not stuns[2] and not stuns[3] then
		StartThread(UnstunThread)
	end
end

function script.Create()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
	Turn (ejector, y_axis, math.rad(-90))
end

function script.QueryWeapon()
	return muzzle
end

function script.AimFromWeapon()
	return turret
end

function script.AimWeapon (num, heading, pitch)

	Signal (SigAim)
	SetSignalMask (SigAim)

	while disarmed do
		Sleep (34)
	end

	StartThread (RestoreAfterDelay)
	local slowMult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
	Turn (turret, y_axis, heading, math.rad(360)*slowMult)
	Turn (sleeve, x_axis, -pitch, math.rad(360)*slowMult)
	WaitForTurn (turret, y_axis)
	WaitForTurn (sleeve, x_axis)

	return true
end

function script.FireWeapon ()
	EmitSfx (muzzle, 1024)
	EmitSfx (ejector, 1025)
	Spin (barrel, z_axis, math.rad(720))
	StopSpin (barrel, z_axis, math.rad(18))
end

function script.Killed (recentDamage, maxHealth)
	local severity = recentDamage / maxHealth

	for i = 1, #explodables do
		if (math.random() < severity) then
			Explode (explodables[i], SFX.SMOKE + SFX.FIRE)
		end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (base, SFX.SHATTER)
		return 2
	end
end
