local base = piece 'base' 
local body = piece 'body' 
local barrel = piece 'barrel' 
local turret = piece 'turret' 
local flare = piece 'flare' 
--linear constant 163840

include "constants.lua"
include "pieceControl.lua"

-- Signal definitions
local SIG_AIM = 2

function script.Create()
	StartThread(SmokeUnit, {base})
end

function Stunned ()
	StopTurn (turret, y_axis)
	StopTurn (barrel, x_axis)
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	while Spring.GetUnitRulesParam(unitID,"disarmed") == 1 do
		Sleep(100)
	end

	local slowMult = (1-(Spring.GetUnitRulesParam(unitID,"slowState") or 0))
	Turn(turret, y_axis, heading, math.rad(300)*slowMult)
	Turn(barrel, x_axis, -pitch, math.rad(200)*slowMult)
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel, x_axis)
	return true
end

function script.AimFromWeapon()
	return barrel
end

function script.QueryWeapon()
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	Hide(flare)
	if severity <= 0.25 then
		Explode(base, sfxNone)
		Explode(flare, sfxNone)
		Explode(turret, sfxNone)
		Explode(barrel, sfxNone)
		return 1
	elseif severity <= 0.50 then
		Explode(base, sfxNone)
		Explode(flare, sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(turret, sfxSmoke + sfxFire + sfxExplodeOnHit)
		Explode(barrel, sfxNone)
		return 1
	end
	Explode(base, sfxNone)
	Explode(flare, sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(turret, sfxSmoke + sfxFire + sfxExplodeOnHit)
	Explode(barrel, sfxShatter)
	return 2
end