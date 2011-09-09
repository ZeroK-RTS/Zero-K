include "constants.lua"
include "spider_walking.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base'
local body = piece 'body'
local leg1 = piece 'leg1'	-- back right
local leg2 = piece 'leg2' 	-- middle right
local leg3 = piece 'leg3' 	-- front right
local leg4 = piece 'leg4' 	-- back left
local leg5 = piece 'leg5' 	-- middle left
local leg6 = piece 'leg6' 	-- front left

local armr1 = piece 'armr1'
local arml1 = piece 'arml1'
local gunr = piece 'gunr'
local gunl = piece 'gunl'
local barrel1r = piece 'barrel1r'
local barrel1l = piece 'barrel1l'

local tail1 = piece 'tail1'
local tail2 = piece 'tail2'
local tail3 = piece 'tail3'
local tail4 = piece 'tail4'
local tail5 = piece 'tail5'
local tailgun = piece 'tailgun'

local flare1 = piece 'flare1'

smokePiece = {base, tailgun}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM1 = 2
local SIG_AIM2 = 3
local SIG_AIM3 = 4

local PERIOD = 0.135

local sleepTime = PERIOD*1000

local legRaiseAngle = math.rad(30)
local legRaiseSpeed = legRaiseAngle/PERIOD
local legLowerSpeed = legRaiseAngle/PERIOD

local legForwardAngle = math.rad(20)
local legForwardTheta = math.rad(25)
local legForwardOffset = -math.rad(20)
local legForwardSpeed = legForwardAngle/PERIOD

local legMiddleAngle = math.rad(20)
local legMiddleTheta = 0
local legMiddleOffset = 0
local legMiddleSpeed = legMiddleAngle/PERIOD

local legBackwardAngle = math.rad(20)
local legBackwardTheta = -math.rad(25)
local legBackwardOffset = math.rad(20)
local legBackwardSpeed = legBackwardAngle/PERIOD

local restore_delay = 3000


-- four-stroke hexapedal walkscript
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		
		walk(leg1, leg2, leg3, leg4, leg5, leg6,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	SetSignalMask(SIG_WALK)
	restoreLegs(leg1, leg2, leg3, leg4, leg5, leg6,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)		
end


function script.Create()
	StartThread(SmokeUnit)
--	Turn( armr1 , z_axis, math.rad(30), 100 )
--	Turn( arml1 , z_axis, math.rad(-30), 100 )
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
	Turn( tail1 , x_axis, 0, math.rad(50) )
	Turn( tail2 , x_axis, 0, math.rad(50) )
	Turn( tail3 , x_axis, 0, math.rad(50) )
	Turn( tail4 , x_axis, 0, math.rad(50) )
	Turn( tail5 , x_axis, 0, math.rad(50) )
	Turn( tailgun , x_axis, 0, math.rad(50) )
	Turn( tail1 , y_axis, 0, math.rad(50) )
	Turn( tail2 , y_axis, 0, math.rad(50) )
	Turn( tail3 , y_axis, 0, math.rad(50) )
	Turn( tail4 , y_axis, 0, math.rad(50) )
	Turn( tail5 , y_axis, 0, math.rad(50) )
	Turn( tailgun , y_axis, 0, math.rad(50) )
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM1)
	SetSignalMask( SIG_AIM1)
	Turn( tail1 , x_axis, (-pitch/6), math.rad(50) )
	Turn( tail2 , x_axis, (-pitch/6), math.rad(50) )
	Turn( tail3 , x_axis, (-pitch/6), math.rad(50) )
	Turn( tail4 , x_axis, (-pitch/6), math.rad(50) )
	Turn( tail5 , x_axis, (-pitch/6), math.rad(50) )
	Turn( tailgun , x_axis, -(pitch/6), math.rad(50) )
	Turn( tail1 , y_axis, (heading/6), math.rad(50) )
	Turn( tail2 , y_axis, (heading/6), math.rad(50) )
	Turn( tail3 , y_axis, (heading/6), math.rad(50) )
	Turn( tail4 , y_axis, (heading/6), math.rad(50) )
	Turn( tail5 , y_axis, (heading/6), math.rad(50) )
	Turn( tailgun , y_axis, (heading/6), math.rad(50) )
	WaitForTurn(tailgun, y_axis)
	WaitForTurn(tailgun, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon1()
	return tailgun
end

function script.QueryWeapon1()
	return flare1
end

function script.AimWeapon2(heading, pitch)
	Signal( SIG_AIM2)
	SetSignalMask( SIG_AIM2)
	Turn( gunl , y_axis, heading, math.rad(50) )
	Turn( arml1 , x_axis, -pitch, math.rad(50) )
	WaitForTurn(gunl, y_axis)
	WaitForTurn(arml1, x_axis)
	return true
end

function script.AimFromWeapon2()
	return gunl
end

function script.QueryWeapon2()
	return barrel1l
end

function script.AimWeapon3(heading, pitch)
	Signal( SIG_AIM3)
	SetSignalMask( SIG_AIM3)
	Turn( gunr , y_axis, heading, math.rad(50) )
	Turn( armr1 , x_axis, -pitch, math.rad(50) )
	WaitForTurn(gunr, y_axis)
	WaitForTurn(armr1, x_axis)
	return true
end

function script.AimFromWeapon3()
	return gunr
end

function script.QueryWeapon3()
	return barrel1r
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(tail2, sfxNone)
		Explode(body, sfxNone)
		Explode(tail1, sfxNone)
		Explode(leg1, sfxNone)
		Explode(leg2, sfxNone)
		Explode(leg3, sfxNone)
		Explode(leg4, sfxNone)
		Explode(leg5, sfxNone)
		Explode(leg6, sfxNone)
		Explode(tailgun, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(tail2, sfxFall)
		Explode(body, sfxNone)
		Explode(tail1, sfxFall)
		Explode(leg1, sfxFall)
		Explode(leg2, sfxFall)
		Explode(leg3, sfxFall)
		Explode(leg4, sfxFall)
		Explode(leg5, sfxFall)
		Explode(leg6, sfxFall)
		Explode(tailgun, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(tail2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxNone)
		Explode(tail1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(tailgun, sfxShatter)
		return 2
	else
		Explode(tail2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
		Explode(tail1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg1, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg2, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg3, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg4, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg5, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(leg6, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(tailgun, sfxShatter)
		return 2
	end
end