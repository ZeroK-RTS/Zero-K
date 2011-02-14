include "constants.lua"

local base, cylinder, turret, jammersturret, jam1, jam2, deploy = piece ('base', 'cylinder', 'turret', 'jammersturret', 'jam1', 'jam2', 'deploy')
smokePiece = {base}

function script.Create()
	StartThread(SmokeUnit)
end

function script.Activate()
	Spin(jammersturret, y_axis, math.rad(120), math.rad(30))
	Move(deploy, y_axis, 25, 10)
	Turn(jam1, z_axis, 0.2, 0.1)
	Turn(jam2, z_axis, -0.2, 0.1)
	
	Spin(turret, y_axis, -0.5, 0.01)
    Spin(cylinder, y_axis, 1.2, 0.05)
end

function script.Deactivate()
	Move(deploy, y_axis, 0, 10)
    Turn(jam1, z_axis, 0, 0.1)
    Turn(jam2, z_axis, 0, 0.1)
	StopSpin(jammersturret, y_axis, math.rad(30))
	
	StopSpin(turret, y_axis, 0.01)
    StopSpin(cylinder, y_axis, 0.01)
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
	elseif  severity <= .99  then
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
