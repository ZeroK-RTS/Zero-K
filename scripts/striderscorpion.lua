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

local smokePiece = {base, tailgun}

local weaponPieces = {
	[1] = {aimFrom = body, flare = {body}},
	[2] = {aimFrom = tailgun, flare = {flare1} },
	[3] = {aimFrom = tailgun, flare = {flare1} },
	[4] = {pivot = gunl, pitch = arml1, aimFrom = gunl, flare = {flare1l, flare2l, flare3l} },
	[5] = {pivot = gunr, pitch = armr1, aimFrom = gunr, flare = {flare1r, flare2r, flare3r} },
}

local gun_cycle = {1, 1, 1, 1, 1}

--------------------------------------------------------------------------------
-- constants
--------------------------------------------------------------------------------
-- Signal definitions
local SIG_WALK = 1
local SIG_RESTORE = 2

local PERIOD = 0.22

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
		
		GG.SpiderWalk.walk(leg1, leg2, leg3, leg4, leg5, leg6,
			legRaiseAngle, legRaiseSpeed, legLowerSpeed,
			legForwardAngle, legForwardOffset, legForwardSpeed, legForwardTheta,
			legMiddleAngle, legMiddleOffset, legMiddleSpeed, legMiddleTheta,
			legBackwardAngle, legBackwardOffset, legBackwardSpeed, legBackwardTheta,
			sleepTime)
	end
end

local function RestoreLegs()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	GG.SpiderWalk.restoreLegs(leg1, leg2, leg3, leg4, leg5, leg6,
		legRaiseSpeed, legForwardSpeed, legMiddleSpeed,legBackwardSpeed)
end


function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
--	Turn(armr1, z_axis, math.rad(30), 100)
--	Turn(arml1, z_axis, math.rad(-30), 100)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(RestoreLegs)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(restore_delay)
	local turnSpeed = tailTurnSpeed/2
	local pitchSpeed = tailPitchSpeed/2
	for i=1, #tailPieces do
		Turn(tailPieces[i], x_axis, 0, pitchSpeed)
		Turn(tailPieces[i], y_axis, 0, turnSpeed)
	end
	
	for i=4,5 do
		Turn(weaponPieces[i].pivot, y_axis, 0, math.rad(60))
		Turn(weaponPieces[i].pitch, x_axis, 0, math.rad(45))
	end
end

function script.AimWeapon(num, heading, pitch)
	local sig = 2^num
	Signal(sig)
	SetSignalMask(sig)
	if num == 2 or num == 3 then
		if heading > math.pi then heading = -(2 * math.pi - heading) end
		for i=1, #tailPieces do
			Turn(tailPieces[i], x_axis, -pitch/6, tailPitchSpeed)
			Turn(tailPieces[i], y_axis, heading/6, tailTurnSpeed)
		end
		WaitForTurn(tailgun, y_axis)
		WaitForTurn(tailgun, x_axis)
		StartThread(RestoreAfterDelay)
	elseif num ~= 1 then
		Turn(weaponPieces[num].pivot, y_axis, heading, math.rad(120))
		Turn(weaponPieces[num].pitch, x_axis, -pitch, math.rad(90))
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
	if num > 3 then
		gun_cycle[num] = gun_cycle[num] + 1
		if gun_cycle[num] > 3 then gun_cycle[num] = 1 end
	elseif num == 2 then
		EmitSfx(flare1, 1024)
		EmitSfx(flare1, 1025)
	elseif num == 3 then
		EmitSfx(flare1, 1026)
		EmitSfx(flare1, 1027)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(tail2, SFX.NONE)
		Explode(body, SFX.NONE)
		Explode(tail1, SFX.NONE)
		Explode(leg1, SFX.NONE)
		Explode(leg2, SFX.NONE)
		Explode(leg3, SFX.NONE)
		Explode(leg4, SFX.NONE)
		Explode(leg5, SFX.NONE)
		Explode(leg6, SFX.NONE)
		Explode(tailgun, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(tail2, SFX.FALL)
		Explode(body, SFX.NONE)
		Explode(tail1, SFX.FALL)
		Explode(leg1, SFX.FALL)
		Explode(leg2, SFX.FALL)
		Explode(leg3, SFX.FALL)
		Explode(leg4, SFX.FALL)
		Explode(leg5, SFX.FALL)
		Explode(leg6, SFX.FALL)
		Explode(tailgun, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(tail2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(body, SFX.NONE)
		Explode(tail1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(tailgun, SFX.SHATTER)
		return 2
	else
		Explode(tail2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(base, SFX.NONE)
		Explode(tail1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg1, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg2, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg3, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg4, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg5, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(leg6, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(tailgun, SFX.SHATTER)
		return 2
	end
end
