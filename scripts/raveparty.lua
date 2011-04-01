local base, turret, spindle, fakespindle = piece('base', 'turret', 'spindle', 'fakespindle')

local guns = {} 
for i=1,6 do
	guns[i] = {
		center = piece('center'..i),
		sleeve = piece('sleeve'..i),
		barrel = piece('barrel'..i),
		flare = piece('flare'..i),
	}
end

local smokePiece = {spindle, turret}

include "constants.lua"

-- Signal definitions
local SIG_AIM = 2

local gunNum = 1
local weaponNum = 1
local randomize = false
local reloading = false


function script.Create()
	StartThread(SmokeUnit)
	Turn(fakespindle, x_axis, math.rad(60))
	
	for i=1,6 do
		Turn(guns[i].flare, x_axis, (math.rad(-60)* i+1))
	end
end

function script.Activate()
	randomize = true
end

function script.Deactivate()
	randomize = false
end

function script.AimWeapon(num, heading, pitch)
	if weaponNum ~= num then return false end
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(40) )
	Turn( spindle , x_axis, 0 - pitch, math.rad(90) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(spindle, x_axis)
	while reloading do Sleep(30) end
	return true
end

function script.AimFromWeapon(num)
	return spindle
end

function script.QueryWeapon(num)
	return guns[gunNum].flare
end

function script.Shot(num)
	EmitSfx(guns[gunNum].flare, 1024)
	EmitSfx(guns[gunNum].flare, 1025)
	EmitSfx(guns[gunNum].flare, 1026)
end

function script.FireWeapon(num)
	reloading = true
	gunNum = gunNum + 1
	if gunNum > 6 then gunNum = 1 end
	Sleep(120)
	Turn(fakespindle, x_axis, math.rad(60)*(gunNum), math.rad(120))
	WaitForTurn(fakespindle, x_axis)
	reloading = false
	if randomize then
		weaponNum = math.random(1,6)
	else
		weaponNum = weaponNum + 1
		if weaponNum > 6 then weaponNum = 1 end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(base, sfxNone)
		Explode(spindle, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(base, sfxNone)
		Explode(spindle, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif severity <= .99  then
		Explode(base, sfxShatter)
		Explode(spindle, sfxShatter)
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(base, sfxShatter)
		Explode(spindle, sfxShatter)
		Explode(turret, sfxShatter)
		return 2
	end
end
