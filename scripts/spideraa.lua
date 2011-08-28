include "spider_walking.lua"
include "constants.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local base = piece 'base' 
local turret = piece 'turret' 
local barrel = piece 'barrel' 
local flare = piece 'flare' 
local leg1 = piece 'leg1'	-- back right
local leg2 = piece 'leg2' 	-- middle right
local leg3 = piece 'leg3' 	-- front right
local leg4 = piece 'leg4' 	-- back left
local leg5 = piece 'leg5' 	-- middle left
local leg6 = piece 'leg6' 	-- front left

smokePiece = {base, turret}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2

local PERIOD = 0.17

local sleepTime = PERIOD*1000

local legRaiseAngle = math.rad(30)
local legRaiseSpeed = legRaiseAngle/PERIOD
local legLowerSpeed = legRaiseAngle/PERIOD

local legForwardAngle = math.rad(20)
local legForwardTheta = math.rad(45)
local legForwardOffset = 0
local legForwardSpeed = legForwardAngle/PERIOD

local legMiddleAngle = math.rad(20)
local legMiddleTheta = 0
local legMiddleOffset = 0
local legMiddleSpeed = legMiddleAngle/PERIOD

local legBackwardAngle = math.rad(20)
local legBackwardTheta = -math.rad(45)
local legBackwardOffset = 0
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
	Turn( barrel , x_axis, 0, math.rad(90) )
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( turret , y_axis, heading, math.rad(450) )
	Turn( barrel , x_axis, math.max(-pitch - math.rad(15), -math.rad(90)), math.rad(180) )
	WaitForTurn(turret, y_axis)
	WaitForTurn(barrel, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.AimFromWeapon(num)
	return turret
end

function script.QueryWeapon(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(barrel, sfxNone)
		Explode(base, sfxNone)
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
		Explode(barrel, sfxFall)
		Explode(base, sfxNone)
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
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
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
		Explode(barrel, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(base, sfxNone)
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
