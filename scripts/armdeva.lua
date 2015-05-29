include "constants.lua"
include "pieceControl.lua"

local base, turret, sleeve, barrel, flare, muzzle, ejector = piece('base', 'turret', 'sleeve', 'barrel', 'flare', 'muzzle', 'ejector')

local explodables = {barrel, flare, sleeve, turret}
local smokePiece = { base, turret }

local disarmed = false

local SigAim = 1

local function RestoreAfterDelay()
	Sleep (10000)
	Turn (turret, y_axis, 0, math.rad(10))
	Turn (sleeve, x_axis, 0, math.rad(10))
end

local function StunThread ()
	disarmed = true
	Signal (SigAim)
	SetSignalMask(SigAim)

	StopTurn (turret, y_axis)
	StopTurn (sleeve, x_axis)

	while (IsDisarmed()) do
		Sleep (200)
	end

	disarmed = false
	RestoreAfterDelay()
end

function Stunned ()
	StartThread (StunThread)
end

function script.Create()
	StartThread (SmokeUnit, smokePiece)
	Turn (ejector, y_axis, math.rad(-90))
end

function script.QueryWeapon() return muzzle end
function script.AimFromWeapon() return turret end

function script.AimWeapon (num, heading, pitch)

	Signal (SigAim)
	SetSignalMask (SigAim)

	while disarmed do
		Sleep (100)
	end

	StartThread (RestoreAfterDelay)
	local slowMult = (1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0))
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
			Explode (explodables[i], sfxSmoke + sfxFire)
		end
	end

	if (severity <= .5) then
		return 1
	else
		Explode (base, sfxShatter)
		return 2
	end
end
