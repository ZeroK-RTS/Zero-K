include "constants.lua"
include "spider_walking.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local body = piece 'body' 
local turret = piece 'turret' 
local gun = piece 'gun' 
local flare = piece 'flare' 
local br = piece 'leg1'	-- back right
local mr = piece 'leg2' 	-- middle right
local fr = piece 'leg3' 	-- front right
local bl = piece 'leg4' 	-- back left
local ml = piece 'leg5' 	-- middle left
local fl = piece 'leg6' 	-- front left

smokePiece = {body, turret}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = 2

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
		
		walk(br, mr, fr, bl, ml, fl,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	SetSignalMask(SIG_WALK)
	restoreLegs(br, mr, fr, bl, ml, fl,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)				
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
end

function script.AimWeapon(num, heading, pitch)
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

function script.QueryWeapon(num)
	return flare
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(gun, sfxNone)
		Explode(body, sfxNone)
		Explode(flare, sfxNone)
		Explode(br, sfxNone)
		Explode(mr, sfxNone)
		Explode(fr, sfxNone)
		Explode(bl, sfxNone)
		Explode(ml, sfxNone)
		Explode(fl, sfxNone)
		Explode(turret, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(gun, sfxFall)
		Explode(body, sfxNone)
		Explode(flare, sfxFall)
		Explode(br, sfxFall)
		Explode(mr, sfxFall)
		Explode(fr, sfxFall)
		Explode(bl, sfxFall)
		Explode(ml, sfxFall)
		Explode(fl, sfxFall)
		Explode(turret, sfxShatter)
		return 1
	elseif severity <= .99  then
		Explode(gun, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxNone)
		Explode(flare, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(br, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(mr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(bl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(ml, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter)
		return 2
	else
		Explode(gun, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(body, sfxNone)
		Explode(flare, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(br, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(mr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(bl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(ml, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(turret, sfxShatter + sfxExplode )
		return 2
	end
end
