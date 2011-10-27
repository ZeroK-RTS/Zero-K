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
local barrel1r, barrel2r, barrel3r = piece('barrel1r', 'barrel2r', 'barrel3r')
local barrel1l, barrel2l, barrel3l = piece('barrel1l', 'barrel2l', 'barrel3l')
local flare1r, flare2r, flare3r = piece('flare1r', 'flare2r', 'flare3r')
local flare1l, flare2l, flare3l = piece('flare1l', 'flare2l', 'flare3l')

local tail1 = piece 'tail1'
local tail2 = piece 'tail2'
local tail3 = piece 'tail3'
local tail4 = piece 'tail4'
local tail5 = piece 'tail5'
local tailgun = piece 'tailgun'
local flare1 = piece 'flare1'

local tailPieces = {tail1, tail2, tail3, tail4, tail5, tailgun}

smokePiece = {base, tailgun}

local weaponPieces = {
	[1] = {aimFrom = body, flare = {body}},
    [2] = {aimFrom = tailgun, flare = {flare1} },
	[3] = {pivot = gunl, pitch = arml1, aimFrom = gunl, flare = {flare1l, flare2l, flare3l} },
	[4] = {pivot = gunr, pitch = armr1, aimFrom = gunr, flare = {flare1r, flare2r, flare3r} },
}

local gun_cycle = {[1] = 1, [2] = 1, [3] = 1, [4] = 1,}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_AIM = {2, 4, 8}
local SIG_RESTORE = 16

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

local restore_delay = 5000

local tailTurnSpeed = math.rad(20)
local tailPitchSpeed = math.rad(10)

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
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(restore_delay)
	local turnSpeed = tailTurnSpeed/2
	local pitchSpeed = tailPitchSpeed/2
	for i=1, #tailPieces do
		Turn( tailPieces[i], x_axis, 0, pitchSpeed )
		Turn( tailPieces[i], y_axis, 0, turnSpeed )
	end
	
	for i=3,4 do
		Turn( weaponPieces[i].pivot, y_axis, 0, math.rad(60) )
		Turn( weaponPieces[i].pitch, x_axis, 0, math.rad(45) )
	end
end

function script.AimWeapon(num, heading, pitch)
	Signal( SIG_AIM[num])
	SetSignalMask( SIG_AIM[num])
	if num == 2 then
		if heading > math.pi then heading = -(2 * math.pi - heading) end
		for i=1, #tailPieces do
			Turn( tailPieces[i], x_axis, -pitch/6, tailPitchSpeed )
			Turn( tailPieces[i], y_axis, heading/6, tailTurnSpeed )
		end
		WaitForTurn(tailgun, y_axis)
		WaitForTurn(tailgun, x_axis)
		StartThread(RestoreAfterDelay)
	elseif num ~= 1 then
		Turn( weaponPieces[num].pivot, y_axis, heading, math.rad(120) )
		Turn( weaponPieces[num].pitch , x_axis, -pitch, math.rad(90) )
		WaitForTurn(weaponPieces[num].pivot, y_axis)
		WaitForTurn(weaponPieces[num].pitch, x_axis)
		StartThread(RestoreAfterDelay)
	end
    return true	
end

function script.AimFromWeapon(num)
	return weaponPieces[num].aimFrom
end

function script.QueryWeapon(num)
    return weaponPieces[num].flare[gun_cycle[num]]
end

function script.BlockShot(num)
	return (num == 1) -- weapon 1 fake
end

function script.Shot(num)
	if num > 2 then
		gun_cycle[num] = gun_cycle[num] + 1
		if gun_cycle[num] > 3 then gun_cycle[num] = 1 end
	else
		EmitSfx(flare1, 1024)
		EmitSfx(flare1, 1025)
	end
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