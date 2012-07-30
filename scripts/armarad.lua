local base = piece 'base' 
local spinner = piece 'spinner' 
local arm = piece 'arm' 
local ant = piece 'ant' 
local dish = piece 'dish' 
local float1 = piece 'float1' 
local float2 = piece 'float2' 

include "constants.lua"

smokePiece = { ant, base}

local spGetUnitIsStunned = Spring.GetUnitIsStunned

local SIG_CLOSE = 1
local SIG_OPEN = 2

function script.Create()
	if not onWater() then 
		--Hide(float1)
		--Hide(float2)
	end
	StartThread(SmokeUnit)
end

local function Activate()

	Signal(SIG_CLOSE)
	SetSignalMask(SIG_OPEN)
	
	Sleep(1000)
	Move( dish , y_axis, 11 , 7 )
	WaitForMove(dish, y_axis)
	Turn( ant , z_axis, rad(-100), rad(60) )
	Turn( arm , z_axis, rad(30), rad(40) )
	Spin( spinner , y_axis, rad(20), rad(20))
	WaitForTurn(ant, z_axis)
	Spin( dish , y_axis, rad(20), rad(20))
end

local function Deactivate()
	
	Signal(SIG_OPEN)
	SetSignalMask(SIG_CLOSE)

	if spGetUnitIsStunned(unitID) then
		Spring.UnitScript.StopSpin(dish , y_axis, rad(10))
		Spring.UnitScript.StopSpin(spinner , y_axis, rad(10))
	else
		Spin( dish , y_axis,  rad(0), rad(20))
		Turn( ant , z_axis, rad(0), rad(60) )
		Turn( arm , z_axis, rad(0), rad(40) )
		WaitForTurn(ant, z_axis)
		Move( dish , y_axis, 0, 7)
		WaitForMove(dish, y_axis)
		Spin( spinner , y_axis, rad(0), rad(3) )
	end
end

function script.Activate()
	StartThread( Activate)
end

function script.Deactivate()
	StartThread( Deactivate)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if  severity <= 0.25  then
		Explode(arm, sfxFire)
		Explode(ant, sfxFire)
		Explode(base, sfxFire)
		Explode(dish, sfxExplode)
		Explode(spinner, sfxExplode)
		return 1
	elseif  severity <= 0.50  then
		Explode(arm, sfxFall)
		Explode(ant, sfxFall)
		Explode(base, sfxShatter)
		Explode(dish, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(spinner, sfxShatter)
		return 1
	else
		Explode(arm, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(ant, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(base, sfxShatter)
		Explode(dish, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit )
		Explode(spinner, sfxFall + sfxSmoke + sfxFire + sfxExplodeOnHit)
		return 2
	end
end
