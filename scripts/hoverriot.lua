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

local wobble = true

-- Signal definitions
local SIG_MOVE = 2
local SIG_AIM = 4

local RESTORE_DELAY = 3000

local function WobbleUnit()
	while true do
		if  wobble == true  then
			Move( base , y_axis, 0.800000 , 1.20000 )
		end
		if  wobble == false  then
			Move( base , y_axis, -0.800000 , 1.20000 )
		end
		wobble = not wobble
		Sleep( 750)
	end
end

local function RockUnit(anglex, anglez)
	Turn( base , x_axis, math.rad(anglex ), math.rad(50.000000) )
	Turn( base , z_axis, math.rad(-(anglez )), math.rad(50.000000) )
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, math.rad(-(0.000000)), math.rad(20.000000) )
	Turn( base , x_axis, 0, math.rad(20.000000) )
end

function script.HitByWeapon(Func_Var_1, Func_Var_2)
	Turn( base , z_axis, math.rad(-(Func_Var_2 )), math.rad(105.000000) )
	Turn( base , x_axis, math.rad(Func_Var_1 ), math.rad(105.000000) )
	WaitForTurn(base, z_axis)
	WaitForTurn(base, x_axis)
	Turn( base , z_axis, math.rad(-(0.000000)), math.rad(30.000000) )
	Turn( base , x_axis, 0, math.rad(30.000000) )
end

local function MoveScript()
	while true do 
		if math.random() < 0.5  then
		
			EmitSfx( wake1,  5 )
			EmitSfx( wake3,  5 )
			EmitSfx( wake5,  5 )
			EmitSfx( wake7,  5 )
			EmitSfx( wake1,  3 )
			EmitSfx( wake3,  3 )
			EmitSfx( wake5,  3 )
			EmitSfx( wake7,  3 )
		else
			EmitSfx( wake2,  5 )
			EmitSfx( wake4,  5 )
			EmitSfx( wake6,  5 )
			EmitSfx( wake8,  5 )
			EmitSfx( wake2,  3 )
			EmitSfx( wake4,  3 )
			EmitSfx( wake6,  3 )
			EmitSfx( wake8,  3 )
		end
	
		EmitSfx( ground1,  1024+0 )
		Sleep( 150)
	end
end

function script.Create()
	Hide( flare)
	Hide( ground1)
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
