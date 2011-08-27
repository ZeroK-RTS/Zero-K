include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local body = piece 'body' 
local turret = piece 'turret' 
local gun = piece 'gun' 
local flare = piece 'flare' 
local leg1 = piece 'leg1'	-- back right
local leg2 = piece 'leg2' 	-- middle right
local leg3 = piece 'leg3' 	-- front right
local leg4 = piece 'leg4' 	-- back left
local leg5 = piece 'leg5' 	-- middle left
local leg6 = piece 'leg6' 	-- front left

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2

local PACE = 2.5

local legRaiseSpeed = math.rad(67.5)*PACE
local legRaiseAngle = math.rad(30)
local legLowerSpeed = math.rad(75)*PACE

local legForwardSpeed = math.rad(40)*PACE
local legForwardAngle = -math.rad(20)
local legMiddleSpeed = math.rad(40)*PACE
local legMiddleAngle = math.rad(20)
local legBackwardSpeed = math.rad(35)*PACE
local legBackwardAngle = math.rad(20)

local restore_delay = 3000


-- four-stroke hexapedal walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		Turn(leg6, z_axis, legRaiseAngle, legRaiseSpeed)	-- LF leg up
		Turn(leg6, y_axis, legForwardAngle, legForwardSpeed)	-- LF leg forward
		Turn(leg2, z_axis, -legRaiseAngle, legRaiseSpeed)	-- RM leg up
		Turn(leg2, y_axis, legMiddleAngle, legMiddleSpeed)	-- RM leg forward
		Turn(leg4, z_axis, legRaiseAngle, legRaiseSpeed)	-- LB leg up
		Turn(leg4, y_axis, -legBackwardAngle, legBackwardSpeed)	-- LB leg forward		
		
		Turn(leg3, y_axis, legForwardAngle, legForwardSpeed)	-- RF leg back
		Turn(leg5, y_axis, legMiddleAngle, legMiddleSpeed)	-- LM leg down
		Turn(leg1, y_axis, -legBackwardAngle, legBackwardSpeed)	-- RB leg back	
	
		WaitForTurn(leg6, z_axis)
		WaitForTurn(leg6, y_axis)
		Sleep(0)		
		
		Turn(leg6, z_axis, 0, legLowerSpeed)	-- LF leg down
		Turn(leg2, z_axis, 0, legLowerSpeed)	-- RM leg down
		Turn(leg4, z_axis, 0, legLowerSpeed)	-- LB leg down	
		Sleep(0)		
		WaitForTurn(leg6, z_axis)

		
		Turn(leg3, z_axis, -legRaiseAngle, legRaiseSpeed)	-- RF leg up
		Turn(leg3, y_axis, -legForwardAngle, legForwardSpeed)	-- RF leg forward
		Turn(leg5, z_axis, legRaiseAngle, legRaiseSpeed)	-- LM leg up
		Turn(leg5, y_axis, -legMiddleAngle, legMiddleSpeed)	-- LM leg forward
		Turn(leg1, z_axis, -legRaiseAngle, legRaiseSpeed)	-- RB leg up
		Turn(leg1, y_axis, legBackwardAngle, legBackwardSpeed)	-- RB leg forward		
		
		
		Turn(leg6, y_axis, -legForwardAngle, legForwardSpeed)	-- LF leg back
		Turn(leg2, y_axis, -legMiddleAngle, legMiddleSpeed)	-- RM leg down
		Turn(leg4, y_axis, legBackwardAngle, legBackwardSpeed)	-- LB leg back	

		WaitForTurn(leg3, z_axis)
		WaitForTurn(leg3, y_axis)
		Sleep(0)				
		
		Turn(leg3, z_axis, 0, legLowerSpeed)	-- RF leg down
		Turn(leg5, z_axis, 0, legLowerSpeed)	-- LM leg down
		Turn(leg1, z_axis, 0, legLowerSpeed)	-- RB leg down
		Sleep(0)	
		WaitForTurn(leg6, z_axis)	
		
	-- old shitty walkscript kept here for posterity
	--[[
		Turn( leg1 , y_axis, math.rad(43.8) )
		Turn( leg1 , y_axis, 0, math.rad(219) )
		Turn( leg1 , z_axis, math.rad(0.6) )
		Turn( leg1 , z_axis, 0, math.rad(3) )
		Turn( leg2 , z_axis, 0 )
		Turn( leg2 , z_axis, math.rad(-(31)), math.rad(155) )
		Turn( leg3 , y_axis, math.rad(35) )
		Turn( leg3 , y_axis, math.rad(34), math.rad(3) )
		Turn( leg3 , z_axis, math.rad(32) )
		Turn( leg3 , z_axis, math.rad(-0.6), math.rad(155) )
		Turn( leg4 , y_axis, math.rad(-40) )
		Turn( leg4 , y_axis, math.rad(-40), 0 )
		Turn( leg4 , z_axis, math.rad(-31) )
		Turn( leg4 , z_axis, math.rad(0.6), math.rad(152) )
		Turn( leg5 , y_axis, math.rad(-37) )
		Turn( leg5 , y_axis, 0, math.rad(186) )
		Turn( leg5 , z_axis, 0 )
		Turn( leg5 , z_axis, 0, 0 )
		Turn( leg6 , y_axis, 0 )
		Turn( leg6 , y_axis, math.rad(-30.5), math.rad(152) )
		Turn( leg6 , z_axis, math.rad(-45) )
		Sleep(200)

		
		Turn( leg1 , z_axis, math.rad(-32), math.rad(158) )
		Turn( leg2 , y_axis, math.rad(35), math.rad(173) )
		Turn( leg2 , z_axis, math.rad(-(31)), 0 )
		Turn( leg3 , y_axis, 0, math.rad(170) )
		Turn( leg3 , z_axis, 0, math.rad(3) )
		Turn( leg4 , y_axis, 0, math.rad(200) )
		Turn( leg5 , z_axis, math.rad(31), math.rad(155) )
		Turn( leg6 , z_axis, math.rad(-2.4), math.rad(237) )
		Sleep(200)

		Turn( leg1 , y_axis, math.rad(56), math.rad(280) )
		Turn( leg1 , z_axis, math.rad(-(31)), math.rad(3) )
		Turn( leg2 , y_axis, math.rad(35), 0 )
		Turn( leg2 , z_axis, math.rad(-0.6), math.rad(152) )
		Turn( leg3 , z_axis, math.rad(-32), math.rad(158) )
		Turn( leg4 , y_axis, math.rad(-0.6), math.rad(3) )
		Turn( leg4 , z_axis, math.rad(31), math.rad(152) )
		Turn( leg5 , y_axis, math.rad(-32), math.rad(158) )
		Turn( leg5 , z_axis, math.rad(31), 0 )
		Turn( leg6 , y_axis, math.rad(3), math.rad(167) )
		Sleep(200)

		Turn( leg1 , y_axis, math.rad(43.8), math.rad(60) )
		Turn( leg1 , z_axis, math.rad(-0.6), math.rad(152) )
		Turn( leg2 , y_axis, 0, math.rad(173) )
		Turn( leg2 , z_axis, 0, math.rad(3) )
		Turn( leg3 , y_axis, math.rad(35), math.rad(173) )
		Turn( leg3 , z_axis, math.rad(-32), 0 )
		Turn( leg4 , y_axis, math.rad(-40), math.rad(198) )
		Turn( leg4 , z_axis, math.rad(31), 0 )
		Turn( leg5 , y_axis, math.rad(-37), math.rad(27) )
		Turn( leg5 , z_axis, 0, math.rad(155) )
		Turn( leg6 , y_axis, 0, math.rad(15) )
		Turn( leg6 , z_axis, math.rad(45), math.rad(237) )
		Sleep(200)
	]]--
	end
end

local function RestoreLegs()
	SetSignalMask(SIG_WALK)

	Turn(leg1, z_axis, 0, legRaiseSpeed)	-- LF leg up
	Turn(leg1, y_axis, 0, legForwardSpeed)	-- LF leg forward
	Turn(leg4, z_axis, 0, legRaiseSpeed)	-- RM leg up
	Turn(leg4, y_axis, 0, legMiddleSpeed)	-- RM leg forward
	Turn(leg5, z_axis, 0, legRaiseSpeed)	-- LB leg up
	Turn(leg5, y_axis, 0, legBackwardSpeed)	-- LB leg forward		
	
	Turn(leg2, z_axis, 0, legRaiseSpeed)	-- LF leg up
	Turn(leg2, y_axis, 0, legForwardSpeed)	-- LF leg forward
	Turn(leg3, z_axis, 0, legRaiseSpeed)	-- RM leg up
	Turn(leg3, y_axis, 0, legMiddleSpeed)	-- RM leg forward
	Turn(leg6, z_axis, 0, legRaiseSpeed)	-- LB leg up
	Turn(leg6, y_axis, 0, legBackwardSpeed)	-- LB leg forward			
end

function script.Create()
	StartThread(SmokeUnit)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal(SIG_WALK)
	StartThread(RestoreLegs)
end

local function RestoreAfterDelay()
	Sleep(restore_delay)
	Turn( turret , y_axis, 0, math.rad(90) )
	Turn( gun , x_axis, 0, math.rad(90) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(turret, x_axis)
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(450) )
	Turn( gun , x_axis, -pitch, math.rad(180) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(gun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon1(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(gun, sfxNone)
		Explode(body, sfxNone)
		Explode(flare, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(leg3, sfxNone)
		Explode(leg4, sfxNone)
		Explode(leg5, sfxNone)
		Explode(leg6, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(gun, sfxFall)
		Explode(body, sfxNone)
		Explode(flare, sfxFall)
		Explode(leg1, sfxFall)
		Explode(leg2, sfxFall)
		Explode(leg3, sfxFall)
		Explode(leg4, sfxFall)
		Explode(leg5, sfxFall)
		Explode(leg6, sfxFall)
		Explode(turret, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(gun, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxNone)
		Explode(flare, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(gun, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxNone)
		Explode(flare, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter + sfxExplode )
		return 2
	end
end
