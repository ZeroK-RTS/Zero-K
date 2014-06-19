local base = piece 'base' 
local flare = piece 'flare' 
local wake1 = piece 'wake1' 
local wake2 = piece 'wake2' 
local wake3 = piece 'wake3' 
local wake4 = piece 'wake4' 
local wake5 = piece 'wake5' 
local wake6 = piece 'wake6' 
local wake7 = piece 'wake7' 
local wake8 = piece 'wake8' 
local ground1 = piece 'ground1' 
local barrel = piece 'barrel' 

include "constants.lua"

-- Signal definitions
local SIG_HIT = 2
local SIG_AIM = 4

local RESTORE_DELAY = 3000

local function WobbleUnit()
	while true do
		Move( base , y_axis, 0.8 , 1.2)
		Sleep(750)
		Move( base , y_axis, -0.80 , 1.2)
		Sleep(750)
	end
end

function HitByWeaponThread(x, z)
	Signal( SIG_HIT)
	SetSignalMask( SIG_HIT)
	Turn( base , z_axis, math.rad(-z), math.rad(105))
	Turn( base , x_axis, math.rad(x ), math.rad(105))
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, 0, math.rad(30))
	Turn( base , x_axis, 0, math.rad(30))
end

--[[
function script.HitByWeapon(x, z)
	StartThread(HitByWeaponThread, x, z)
end
]]

local function MoveScript()
	while true do 
		if math.random() < 0.5  then
			EmitSfx(wake1, 5)
			EmitSfx(wake3, 5)
			EmitSfx(wake5, 5)
			EmitSfx(wake7, 5)
			EmitSfx(wake1, 3)
			EmitSfx(wake3, 3)
			EmitSfx(wake5, 3)
			EmitSfx(wake7, 3)
		else
			EmitSfx(wake2, 5)
			EmitSfx(wake4, 5)
			EmitSfx(wake6, 5)
			EmitSfx(wake8, 5)
			EmitSfx(wake2, 3)
			EmitSfx(wake4, 3)
			EmitSfx(wake6, 3)
			EmitSfx(wake8, 3)
		end
	
		EmitSfx( ground1,  1024+0 )
		Sleep( 150)
	end
end

function script.Create()
	Hide(flare)
	Hide(ground1)
	Move(ground1, x_axis, 24.2)
	Move(ground1, y_axis, -8)
	StartThread(SmokeUnit, {base})
	StartThread(WobbleUnit)
	StartThread(MoveScript)
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( barrel , y_axis, heading, math.rad(300.000000) )
	Turn( barrel , x_axis, -pitch, math.rad(300.000000) )
	WaitForTurn(barrel, y_axis)
	WaitForTurn(barrel, x_axis)
	return true
end

function script.QueryWeapon()
	return flare
end

function script.AimFromWeapon()
	return barrel
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		Explode(base, sfxNone)
		Explode(wake1, sfxNone)
		Explode(wake2, sfxNone)
		Explode(wake3, sfxNone)
		Explode(wake4, sfxNone)
		Explode(wake5, sfxNone)
		Explode(wake6, sfxNone)
		return 1
	elseif severity <= 0.50  then
		Explode(base, sfxNone)
		Explode(wake1, sfxFall)
		Explode(wake2, sfxFall)
		Explode(wake3, sfxFall)
		Explode(wake4, sfxFall)
		Explode(wake5, sfxFall)
		Explode(wake6, sfxFall)
		return 1
	end
	Explode(base, sfxNone)
	Explode(wake1, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake2, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake3, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake4, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake5, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	Explode(wake6, sfxSmoke + sfxFall + sfxFire + sfxExplodeOnHit)
	return 2
end
