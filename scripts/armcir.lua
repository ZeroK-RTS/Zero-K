local flare1 = piece 'flare1' 
local flare6 = piece 'flare6' 
local flare5 = piece 'flare5' 
local flare4 = piece 'flare4' 
local flare3 = piece 'flare3' 
local flare2 = piece 'flare2' 
local base = piece 'base' 
local turret = piece 'turret' 
local barrel1 = piece 'barrel1' 
local barrel2 = piece 'barrel2' 
local barrel3 = piece 'barrel3' 
local barrel4 = piece 'barrel4' 
local barrel5 = piece 'barrel5' 
local barrel6 = piece 'barrel6' 
local sleeve12 = piece 'sleeve12' 
local sleeve34 = piece 'sleeve34' 
local sleeve56 = piece 'sleeve56' 
local spindle = piece 'spindle' 
local float = piece 'float' 

include "constants.lua"

local fireCycle = {
	{flare = flare1, barrel = barrel1, angle = rad(0)},
	{flare = flare2, barrel = barrel2, angle = rad(120)},
	{flare = flare3, barrel = barrel3, angle = rad(120)},
	{flare = flare4, barrel = barrel4, angle = rad(240)},
	{flare = flare5, barrel = barrel5, angle = rad(240)},
	{flare = flare6, barrel = barrel6, angle = rad(0)},
}

local gun = 1

-- Signal definitions
local SIG_AIM = 1

smokePiece = {base}

function script.Create()
	if not onWater() then
		Hide( float)
	end
	Hide(flare1)
	Hide(flare2)
	Hide(flare3)
	Hide(flare4)
	Hide(flare5)
	Hide(flare6)
	StartThread(SmokeUnit)
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(145) )
	WaitForTurn(turret, y_axis)
	return true
end

function script.FireWeapon(num)
	WaitForTurn(spindle, z_axis)
	Move( fireCycle[gun].barrel , z_axis, -6 )
	Show( fireCycle[gun].flare)
	Sleep(50)
	Hide( fireCycle[gun].flare)
	Move( fireCycle[gun].barrel , z_axis, 0 , 10 )
	Turn( spindle , z_axis, fireCycle[gun].angle, math.rad(213) )
	gun = (gun%6) + 1
end

function script.QueryWeapon(num)
	return fireCycle[gun].flare
end

function script.AimFromWeapon(num)
	return fireCycle[gun].flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		return 1
	elseif severity <= 0.50  then
		Explode(flare1, sfxFall)
		Explode(flare2, sfxFall)
		Explode(flare3, sfxFall)
		Explode(flare4, sfxFall)
		Explode(flare5, sfxFall)
		Explode(flare6, sfxFall)
		Explode(barrel1, sfxFall)
		Explode(barrel2, sfxFall)
		Explode(barrel3, sfxFall)
		Explode(barrel4, sfxFall)
		Explode(barrel5, sfxFall)
		Explode(barrel6, sfxFall)
		Explode(spindle, sfxFall)
		Explode(turret, sfxShatter)
		return 1
	else
		Explode(flare1, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(flare2, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(flare3, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(flare4, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(flare5, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(flare6, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel1, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel2, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel3, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel4, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel5, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(barrel6, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(spindle, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(turret, sfxShatter)
		return 2
	end
end
