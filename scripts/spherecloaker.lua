include "constants.lua"


local body, hips = piece('body', 'hips')
local lshin = piece 'lshin' 
local rshin = piece 'rshin'
local lfoot = piece 'lfoot'
local rfoot = piece 'rfoot' 
local lthigh = piece 'lthigh' 
local rthigh = piece 'rthigh'
local lknee, rknee = piece('lknee', 'rknee')
local pod, sphere = piece('pod', 'sphere')

smokePiece = {body, sphere}

local active = false

local PACE = 1

local SIG_Walk = 2

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	while true do
		--Spring.Echo("Left foot up, right foot down")
		Turn( lthigh , x_axis, math.rad(20), math.rad(120)*PACE )
--		Turn( lknee , x_axis, math.rad(-40), math.rad(135)*PACE  )
		Turn( lshin , x_axis, math.rad(-60), math.rad(140)*PACE  )
		Turn( lfoot , x_axis, math.rad(40), math.rad(210)*PACE  )
		Turn( rthigh , x_axis, math.rad(-20), math.rad(210)*PACE  )
--		Turn( rknee , x_axis, math.rad(-60), math.rad(210)*PACE  )
		Turn( rshin , x_axis, math.rad(50), math.rad(210)*PACE  )
		Turn( rfoot , x_axis, math.rad(-30), math.rad(210)*PACE  )
		Turn( hips , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Turn( lthigh , z_axis, math.rad(5), math.rad(20)*PACE  )
		Turn( rthigh , z_axis, math.rad(5), math.rad(420)*PACE  )
		Move( hips , y_axis, 4 , 9*PACE)
		WaitForMove(hips, y_axis)
		Sleep(33)
		
		--Spring.Echo("Right foot middle, left foot middle")
		Turn( lthigh , x_axis, math.rad(-10), math.rad(160)*PACE  )
--		Turn( lknee , x_axis, math.rad(15), math.rad(135)*PACE  )
		Turn( lshin , x_axis, math.rad(-40), math.rad(250)*PACE  )
		Turn( lfoot , x_axis, math.rad(50), math.rad(140)*PACE  )		
		Turn( rthigh , x_axis, math.rad(40), math.rad(140)*PACE  )
--		Turn( rknee , x_axis, math.rad(-35), math.rad(135)*PACE  )
		Turn( rshin , x_axis, math.rad(-40), math.rad(140)*PACE  )
		Turn( rfoot , x_axis, math.rad(0), math.rad(140)*PACE  )	
		Move( hips , y_axis, 0, 12*PACE )
		WaitForMove(hips, y_axis)
		Sleep(33)
		
		--Spring.Echo("Right foot up, Left foot down")		
		Turn( rthigh , x_axis, math.rad(20), math.rad(120)*PACE  )
--		Turn( rknee , x_axis, math.rad(-40), math.rad(135)*PACE  )
		Turn( rshin , x_axis, math.rad(-60), math.rad(140)*PACE  )
		Turn( rfoot , x_axis, math.rad(40), math.rad(210)*PACE  )
		Turn( lthigh , x_axis, math.rad(-20), math.rad(210)*PACE  )
--		Turn( lknee , x_axis, math.rad(-60), math.rad(210) )
		Turn( lshin , x_axis, math.rad(50), math.rad(210)*PACE  )
		Turn( lfoot , x_axis, math.rad(-30), math.rad(420)*PACE  )
		Turn( hips , z_axis, math.rad(5), math.rad(20)*PACE  )
		Turn( lthigh , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Turn( rthigh , z_axis, math.rad(-5), math.rad(20)*PACE  )
		Move( hips , y_axis, 4 , 9*PACE )
		WaitForMove(hips, y_axis)
		Sleep(33)
		
		--Spring.Echo("Left foot middle, right foot middle")
		Turn( rthigh , x_axis, math.rad(-10), math.rad(160)*PACE  )
--		Turn( rknee , x_axis, math.rad(15), math.rad(135)*PACE  )
		Turn( rshin , x_axis, math.rad(-40), math.rad(250)*PACE  )
		Turn( rfoot , x_axis, math.rad(50), math.rad(140)*PACE  )
		Turn( lthigh , x_axis, math.rad(40), math.rad(140)*PACE  )
--		Turn( lknee , x_axis, math.rad(-35), math.rad(135) )
		Turn( lshin , x_axis, math.rad(-40), math.rad(140)*PACE  )
		Turn( lfoot , x_axis, math.rad(0), math.rad(140)*PACE  )
		Move( hips , y_axis, 0, 12*PACE )
		WaitForMove(hips, y_axis)
		Sleep(33)
	end
end

local function SpinBall()
	Spin(pod, z_axis, math.rad(math.random(-60,60)), math.rad(30))
	Spin(sphere, x_axis, math.rad(math.random(-60,60)), math.rad(30))
end

function script.Activate()
	active = true
	SpinBall()
end

function script.Deactivate()
	active = false
	StopSpin(sphere, x_axis, math.rad(30))
	StopSpin(pod, z_axis, math.rad(30))
end

function script.StartMoving()
	bMoving = true
	StartThread(Walk)
end

function script.StopMoving()
	bMoving = false
	Signal(SIG_Walk)
	Move( hips , y_axis, 0, 10 )
	Turn( hips , z_axis, 0, math.rad(20) )
	
	Turn( rthigh , x_axis, 0, math.rad(160) )
--	Turn( rknee , x_axis, math.rad(15), math.rad(135) )
	Turn( rshin , x_axis, 0, math.rad(250) )
	Turn( rfoot , x_axis, 0, math.rad(135) )
	Turn( lthigh , x_axis, 0, math.rad(135) )
--	Turn( lknee , x_axis, math.rad(-35), math.rad(135) )
	Turn( lshin , x_axis, 0, math.rad(135) )
	Turn( lfoot , x_axis, 0, math.rad(135) )
end

function script.Create()
	StartThread(SmokeUnit)
	SpinBall()
end

--[[
function script.AimWeapon(num, heading, pitch)
	return active
end
--]]

function script.AimFromWeapon(num)
	return sphere
end

function script.QueryWeapon(num)
	return sphere
end

function script.Shot(num)
	if num == 1 then
		fired = true
		EmitSfx(1024, sphere)
		EmitSfx(1025, sphere)
		Spring.DestroyUnit(unitID, false)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	--[[
	if fired then
		corpsetype = 4
		Explode(body, sfxNone)
		return
	end	
	--]]
	if  severity <= .25  then
		corpsetype = 1
		Explode(body, sfxNone)
	elseif  severity <= .50  then
		corpsetype = 1
		Explode(body, sfxNone)
	elseif  severity <= .99  then
		corpsetype = 2
		Explode(body, sfxShatter)
	end
	corpsetype = 2
	Explode(body, sfxShatter)
end