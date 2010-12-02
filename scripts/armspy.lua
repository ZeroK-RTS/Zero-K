include "constants.lua"

local rfoot = piece 'rfoot' 
local body = piece 'body' 
local rcalf = piece 'rcalf' 
local lcalf = piece 'lcalf' 
local lfoot = piece 'lfoot' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh' 
local gun = piece 'gun' 
local fire = piece 'fire' 

local  bMoving, Static_Var_2, Static_Var_3, Static_Var_4

smokePiece = {body, gun}

local function Walk()
	if bMoving then
		Turn( lthigh , x_axis, math.rad(20), math.rad(115) )
--		Turn( lknee , x_axis, math.rad(-40), math.rad(135) )
		Turn( lcalf , x_axis, math.rad(-60), math.rad(135) )
		Turn( lfoot , x_axis, math.rad(40), math.rad(210) )
		
		Turn( rthigh , x_axis, math.rad(-20), math.rad(210) )
--		Turn( rknee , x_axis, math.rad(-60), math.rad(210) )
		Turn( rcalf , x_axis, math.rad(50), math.rad(210) )
		Turn( rfoot , x_axis, math.rad(-30), math.rad(210) )
		
		Turn( body , z_axis, math.rad(-(5)), math.rad(20) )
		Turn( lthigh , z_axis, math.rad(-(-5)), math.rad(20) )
		Turn( rthigh , z_axis, math.rad(-(-5)), math.rad(420) )
		Move( body , y_axis, 0.7 , 4000 )
		WaitForTurn(lthigh, x_axis)
			
		Turn( lthigh , x_axis, math.rad(-10), math.rad(160) )
--		Turn( lknee , x_axis, math.rad(15), math.rad(135) )
		Turn( lcalf , x_axis, math.rad(-40), math.rad(250) )
		Turn( lfoot , x_axis, math.rad(50), math.rad(135) )
		
		Turn( rthigh , x_axis, math.rad(40), math.rad(135) )
--		Turn( rknee , x_axis, math.rad(-35), math.rad(135) )
		Turn( rcalf , x_axis, math.rad(-40), math.rad(135) )
		Turn( rfoot , x_axis, math.rad(-0), math.rad(135) )
			
		Move( body , y_axis, 0, 4000 )
		WaitForTurn(lcalf, x_axis)
			
		Turn( rthigh , x_axis, math.rad(20), math.rad(115) )
--		Turn( rknee , x_axis, math.rad(-40), math.rad(135) )
		Turn( rcalf , x_axis, math.rad(-60), math.rad(135) )
		Turn( rfoot , x_axis, math.rad(40), math.rad(210) )
			
		Turn( lthigh , x_axis, math.rad(-20), math.rad(210) )
--		Turn( lknee , x_axis, math.rad(-60), math.rad(210) )
		Turn( lcalf , x_axis, math.rad(50), math.rad(210) )
		Turn( lfoot , x_axis, math.rad(-30), math.rad(420) )
			
		Turn( body , z_axis, math.rad(-(-5)), math.rad(20) )
		Turn( lthigh , z_axis, math.rad(-(5)), math.rad(20) )
		Turn( rthigh , z_axis, math.rad(-(5)), math.rad(20) )
		Move( body , y_axis, 0.7 , 4000 )
		WaitForTurn(rthigh, x_axis)
			
		Turn( rthigh , x_axis, math.rad(-10), math.rad(160) )
--		Turn( rknee , x_axis, math.rad(15), math.rad(135) )
		Turn( rcalf , x_axis, math.rad(-40), math.rad(250) )
		Turn( rfoot , x_axis, math.rad(50), math.rad(135) )
			
		Turn( lthigh , x_axis, math.rad(40), math.rad(135) )
--		Turn( lknee , x_axis, math.rad(-35), math.rad(135) )
		Turn( lcalf , x_axis, math.rad(-40), math.rad(135) )
		Turn( lfoot , x_axis, math.rad(-0), math.rad(135) )
		Move( body , y_axis, 0, 4000 )
		WaitForTurn(rcalf, x_axis)
	end
end



local function MotionControl(moving, aiming, justmoved)
	justmoved = true
	while true do
		bmoving = bMoving
		if  bmoving  then
			Walk()
			justmoved = true
		end
		if  not bmoving  then
			if  justmoved  then
				Move( body , y_axis, 0.000000 , 1.000000 )
				Turn( rthigh , x_axis, 0, math.rad(200.000000) )
				Turn( rcalf , x_axis, 0, math.rad(200.000000) )
				Turn( rfoot , x_axis, 0, math.rad(200.000000) )
				Turn( lthigh , x_axis, 0, math.rad(200.000000) )
				Turn( lcalf , x_axis, 0, math.rad(200.000000) )
				Turn( lfoot , x_axis, 0, math.rad(200.000000) )
				justmoved = false
			end
		end
		Sleep(100)
	end
end

function script.Create()
	bMoving = false
	StartThread(MotionControl)
	StartThread(SmokeUnit,smokePiece)
end


local function RestoreAfterDelay()
	Sleep( 2750)
	Turn( gun , y_axis, 0, math.rad(90.021978) )
end

function script.StartMoving()
	bMoving = true
end

function script.StopMoving()
	bMoving = false
end

function script.AimWeapon(num, heading, pitch)
	Turn( gun , y_axis, heading, math.rad(360) ) -- left-right
	Turn( gun , x_axis, -pitch, math.rad(270) ) --up-down
	WaitForTurn(gun, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return fire
end

function script.QueryWeapon(num)
	return fire
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(body, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(body, sfxNone)
		Explode(gun, sfxFall + sfxSmoke)
		return 1
	else
		Explode(body, sfxShatter)
		Explode(gun, sfxFall + sfxSmoke + sfxFire + sfxExplode)
		return 2
	end
end