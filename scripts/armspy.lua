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

local PACE = 1.4

local SIG_Walk = 1
local SIG_Aim = 2

smokePiece = {body, gun}

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	while true do
		--Spring.Echo("Left foot up, right foot down")
		Turn( lthigh , x_axis, math.rad(20), math.rad(120)*PACE )
--		Turn( lknee , x_axis, math.rad(-40), math.rad(135)*PACE  )
		Turn( lcalf , x_axis, math.rad(-60), math.rad(140)*PACE  )
		Turn( lfoot , x_axis, math.rad(40), math.rad(210)*PACE  )
		Turn( rthigh , x_axis, math.rad(-20), math.rad(210)*PACE  )
--		Turn( rknee , x_axis, math.rad(-60), math.rad(210)*PACE  )
		Turn( rcalf , x_axis, math.rad(50), math.rad(210)*PACE  )
		Turn( rfoot , x_axis, math.rad(-30), math.rad(210)*PACE  )
		Turn( body , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Turn( lthigh , z_axis, math.rad(5), math.rad(20)*PACE  )
		Turn( rthigh , z_axis, math.rad(5), math.rad(420)*PACE  )
		Move( body , y_axis, 4 , 9*PACE)
		WaitForMove(body, y_axis)
		Sleep(0)	-- needed to prevent anim breaking, DO NOT REMOVE
		
		--Spring.Echo("Right foot middle, left foot middle")
		Turn( lthigh , x_axis, math.rad(-10), math.rad(160)*PACE  )
--		Turn( lknee , x_axis, math.rad(15), math.rad(135)*PACE  )
		Turn( lcalf , x_axis, math.rad(-40), math.rad(250)*PACE  )
		Turn( lfoot , x_axis, math.rad(50), math.rad(140)*PACE  )		
		Turn( rthigh , x_axis, math.rad(40), math.rad(140)*PACE  )
--		Turn( rknee , x_axis, math.rad(-35), math.rad(135)*PACE  )
		Turn( rcalf , x_axis, math.rad(-40), math.rad(140)*PACE  )
		Turn( rfoot , x_axis, math.rad(0), math.rad(140)*PACE  )	
		Move( body , y_axis, 0, 12*PACE )
		WaitForMove(body, y_axis)
		Sleep(0)
		
		--Spring.Echo("Right foot up, Left foot down")		
		Turn( rthigh , x_axis, math.rad(20), math.rad(120)*PACE  )
--		Turn( rknee , x_axis, math.rad(-40), math.rad(135)*PACE  )
		Turn( rcalf , x_axis, math.rad(-60), math.rad(140)*PACE  )
		Turn( rfoot , x_axis, math.rad(40), math.rad(210)*PACE  )
		Turn( lthigh , x_axis, math.rad(-20), math.rad(210)*PACE  )
--		Turn( lknee , x_axis, math.rad(-60), math.rad(210) )
		Turn( lcalf , x_axis, math.rad(50), math.rad(210)*PACE  )
		Turn( lfoot , x_axis, math.rad(-30), math.rad(420)*PACE  )
		Turn( body , z_axis, math.rad(5), math.rad(20)*PACE  )
		Turn( lthigh , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Turn( rthigh , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Move( body , y_axis, 4 , 9*PACE )
		WaitForMove(body, y_axis)
		Sleep(0)
		
		--Spring.Echo("Left foot middle, right foot middle")
		Turn( rthigh , x_axis, math.rad(-10), math.rad(160)*PACE  )
--		Turn( rknee , x_axis, math.rad(15), math.rad(135)*PACE  )
		Turn( rcalf , x_axis, math.rad(-40), math.rad(250)*PACE  )
		Turn( rfoot , x_axis, math.rad(50), math.rad(140)*PACE  )
		Turn( lthigh , x_axis, math.rad(40), math.rad(140)*PACE  )
--		Turn( lknee , x_axis, math.rad(-35), math.rad(135) )
		Turn( lcalf , x_axis, math.rad(-40), math.rad(140)*PACE  )
		Turn( lfoot , x_axis, math.rad(0), math.rad(140)*PACE  )
		Move( body , y_axis, 0, 12*PACE )
		WaitForMove(body, y_axis)
		Sleep(0)
	end
end

function script.Create()
	bMoving = false
	StartThread(SmokeUnit,smokePiece)
end


local function RestoreAfterDelay()
	Sleep( 2750)
	Turn( gun , y_axis, 0, math.rad(90) )
	Turn( gun , x_axis, 0, math.rad(90) )
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_Walk)
	Move( body , y_axis, 0 , 12 )
	Turn( body , z_axis, 0, math.rad(20) )
	Turn( rthigh , x_axis, 0, math.rad(200) )
	Turn( rcalf , x_axis, 0, math.rad(200) )
	Turn( rfoot , x_axis, 0, math.rad(200) )
	Turn( lthigh , x_axis, 0, math.rad(200) )
	Turn( lcalf , x_axis, 0, math.rad(200) )
	Turn( lfoot , x_axis, 0, math.rad(200) )
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_Aim)
	SetSignalMask(SIG_Aim)
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