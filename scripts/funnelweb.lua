include "constants.lua"
include "spider_walking.lua"

--------------------------------------------------------------------------------
-- pieces
--------------------------------------------------------------------------------
local notum = piece 'notum'
local gaster = piece 'gaster' 
local gunL, gunR, flareL, flareR, aimpoint = piece('gunl', 'gunr', 'flarel', 'flarer', 'aimpoint')
local shieldArm, shield, eye, eyeflare = piece('shield_arm', 'shield', 'eye', 'eyeflare')

-- note reversed sides from piece names!
local br = piece 'thigh_bacl'	-- back right
local mr = piece 'thigh_midl' 	-- middle right
local fr = piece 'thigh_frol' 	-- front right
local bl = piece 'thigh_bacr' 	-- back left
local ml = piece 'thigh_midr' 	-- middle left
local fl = piece 'thigh_fror' 	-- front left

smokePiece = {gaster}

local weaponPieces = {
	[1] = {aimFrom = aimpoint, flare = aimpoint},
	[2] = {aimFrom = eye, flare = eye},
	[3] = {aimFrom = eye, flare = eyeflare},
	[4] = {aimFrom = gaster, flare = gaster},
}

local cannons = {
	[0] = {turret = gunL, flare = flareL},
	[1] = {turret = gunR, flare = flareR},
}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = {
	[1] = 2,
	[2] = 4,
	[3] = 8,
}
local SIG_GRASER = 16
local GRASER_FIRE_TIME = 75	--gameframes

local PERIOD = 0.7

local sleepTime = PERIOD*1000

local legRaiseAngle = math.rad(20)
local legRaiseSpeed = legRaiseAngle/PERIOD
local legLowerSpeed = legRaiseAngle/PERIOD

local legForwardAngle = math.rad(12)
local legForwardTheta = math.rad(25)
local legForwardOffset = 0
local legForwardSpeed = legForwardAngle/PERIOD

local legMiddleAngle = math.rad(12)
local legMiddleTheta = 0
local legMiddleOffset = 0
local legMiddleSpeed = legMiddleAngle/PERIOD

local legBackwardAngle = math.rad(12)
local legBackwardTheta = -math.rad(25)
local legBackwardOffset = 0
local legBackwardSpeed = legBackwardAngle/PERIOD

local restore_delay = 3000

--------------------------------------------------------------------------------
-- variables
--------------------------------------------------------------------------------
local gun_1 = 1

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
	for i=0, 1 do
		Turn( cannons[i].turret, y_axis, 0, math.rad(30) )
		Turn( cannons[i].turret, x_axis, 0, math.rad(15) )
	end
end

local function RestoreAfterDelayHead()
	Sleep(restore_delay)
	Turn( shieldArm , y_axis, 0, math.rad(30) )
	--Turn( shield , y_axis, 0, math.rad(30) )
	Turn( shield, x_axis, 0, math.rad(15) )
end

function script.AimWeapon(num, heading, pitch)
	if num > 2 then return false end
	Signal( SIG_AIM[num])
	SetSignalMask( SIG_AIM[num])
	if num == 1 then
		for i=0,1 do
			Turn( cannons[i].turret, y_axis, heading, math.rad(60) )
			Turn( cannons[i].turret, x_axis, -pitch, math.rad(30) )
		end
		WaitForTurn(gunL, y_axis)
		WaitForTurn(gunL, x_axis)
		WaitForTurn(gunR, y_axis)
		WaitForTurn(gunR, x_axis)		
		StartThread(RestoreAfterDelay)
		return true
	else
		if heading > math.pi then heading = -(2 * math.pi - heading) end
		Turn( shieldArm , y_axis, heading/2, math.rad(75) )
		Turn( shield , y_axis, heading/2, math.rad(75) )
		Turn( shield, x_axis, -pitch, math.rad(60) )
		WaitForTurn(shieldArm, y_axis)
		WaitForTurn(shield, y_axis)
		WaitForTurn(shield, x_axis)
		StartThread(RestoreAfterDelayHead)		
		return true
	end
end

function script.AimFromWeapon(num)
	return weaponPieces[num].aimFrom
end

function script.QueryWeapon(num)
	if num == 1 then return cannons[gun_1].flare end
	return weaponPieces[num].flare
end

local function GraserLoop()
	Signal(SIG_GRASER)
	SetSignalMask(SIG_GRASER)
	local px, py, pz = Spring.GetUnitPosition(unitID)
	Spring.PlaySoundFile("sounds/weapon/laser/heavy_laser5.wav", 4, px, py, pz)	
	for i=1, GRASER_FIRE_TIME do
		EmitSfx(eyeflare, 2048 + 2)
		Sleep(33)
	end
end

function script.FireWeapon(num)
	if num == 2 then
		GraserLoop()
	elseif num == 1 then
		EmitSfx(cannons[gun_1].flare, 1024)
		EmitSfx(cannons[gun_1].flare, 1025)
		gun_1 = 1 - gun_1
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(gunL, sfxNone)
		Explode(gunR, sfxNone)
		Explode(gaster, sfxNone)
		Explode(br, sfxNone)
		Explode(mr, sfxNone)
		Explode(fr, sfxNone)
		Explode(bl, sfxNone)
		Explode(ml, sfxNone)
		Explode(fl, sfxNone)
		return 1
	elseif  severity <= .50  then
		Explode(gunL, sfxFall)
		Explode(gunR, sfxFall)
		Explode(gaster, sfxNone)
		Explode(br, sfxFall)
		Explode(mr, sfxFall)
		Explode(fr, sfxFall)
		Explode(bl, sfxFall)
		Explode(ml, sfxFall)
		Explode(fl, sfxFall)
		return 1
	elseif severity <= .99  then
		Explode(gunL, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gunR, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gaster, sfxNone)
		Explode(br, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(mr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(bl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(ml, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	else
		Explode(gunL, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gunR, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(gaster, sfxNone)
		Explode(br, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(mr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fr, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(bl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(ml, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		Explode(fl, sfxFall + sfxSmoke  + sfxFire  + sfxExplode )
		return 2
	end
end
