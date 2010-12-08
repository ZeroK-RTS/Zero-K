include "constants.lua"

local base, cylinder, turret, jammersturret, jam1, jam2, deploy = piece ('base', 'cylinder', 'turret', 'jammersturret', 'jam1', 'jam2', 'deploy')
smokePiece = {base}

function script.Create()
	StartThread(SmokeUnit)
end

function script.Activate()
	Spin(jammersturret, y_axis, math.rad(120), math.rad(30))
end

function script.Deactivate()
	StopSpin(jammersturret, y_axis, math.rad(30))
end


function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(cylinder, sfxNone )
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(cylinder, sfxShatter )
		return 1
	elseif  severity <= 99  then
		Explode(base, sfxShatter)
		Explode(turret, SFX.FIRE  + SFX.EXPLODE_ON_HIT )
		Explode(cylinder, SFX.FALL + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
		return 2
	end
	Explode(base, sfxShatter )
	Explode(turret, sfxSmoke + SFX.FIRE  + SFX.EXPLODE_ON_HIT )
	Explode(cylinder, SFX.FALL + SFX.FIRE  + SFX.SMOKE  + SFX.EXPLODE_ON_HIT )
	return 2
end
