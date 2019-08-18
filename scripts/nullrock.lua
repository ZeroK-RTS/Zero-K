local base = piece "base"

local SIG_HIT = 2

function HitByWeaponThread(x, z)
	Signal(SIG_HIT)
	SetSignalMask(SIG_HIT)
	Turn(base, z_axis, x*0.5, math.rad(105))
	Turn(base, x_axis, -z*0.5, math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn(base, z_axis, 0, math.rad(30))
	Turn(base, x_axis, 0, math.rad(30))
end
function script.HitByWeapon(x, z, a)
	StartThread(HitByWeaponThread, x, z)
end

function script.Killed(recentDamage, maxHealth)
	return 0
end
