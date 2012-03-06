include "constants.lua"

local base = piece 'base' 
local turret = piece 'turret' 
local hull = piece 'hull' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2'
local missile = piece 'missile' 
local firepoint = piece 'firepoint' 
local doorl = piece 'doorl'
local doorr = piece 'doorr'

smokePiece = {base}

-- Signal definitions
local SIG_MOVE = 1

local gun_1 = 0

function script.Create()
	restore_delay = 3000
	StartThread(SmokeUnit)
	Turn(turret, x_axis, math.rad(-90), math.rad(10000) )
	Turn(doorl, z_axis, math.rad(-100), math.rad(240) )
	Turn(doorr, z_axis, math.rad(100), math.rad(240) )
	Move(turret, y_axis, 20, 16)
end

local function Motion()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	while  true  do
		EmitSfx( wake1,  2 )
		EmitSfx( wake2,  2 )
		Sleep(150)
	end
end

local function shootyThingo()
	Sleep(33)
	Move(turret, y_axis, 0,20)
	Hide(missile)
	Sleep(1000)
	Move(turret, y_axis, 20, 20)
	Show(missile)
end
	
	
function script.Shot()
	StartThread(shootyThingo)
end

function script.StartMoving()
	StartThread(Motion)
end

function script.StopMoving()
	Signal( SIG_MOVE)
end

function script.AimWeapon1(heading, pitch)
	return false
end

function script.AimFromWeapon1()
	return missile
end

function script.QueryWeapon1()
	return missile
end

function script.AimWeapon2(heading, pitch)
--	Turn(turret, x_axis, math.rad(-40), math.rad(50) )
	return true
end

function script.AimFromWeapon2()
	return firepoint
end

function script.QueryWeapon2()
	return firepoint
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(turret, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxExplode )
		Explode(wake2, sfxFall + sfxExplode )
		return 1
	elseif  severity <= .99  then
		corpsetype = 3
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(wake2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return (0)
	else
		Explode(base, sfxNone)
		Explode(turret, sfxShatter)
		Explode(wake1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(wake2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
	end
end
