include 'constants.lua'

local base = piece 'base'
local head = piece 'head'
local l_gun = piece 'l_gun'
local l_gun_barr = piece 'l_gun_barr'
local r_gun = piece 'r_gun'
local r_gun_barr = piece 'r_gun_barr'
local l_thigh, l_leg, l_foot = piece('l_thigh', 'l_leg', 'l_foot')
local r_thigh, r_leg, r_foot = piece('r_thigh', 'r_leg', 'r_foot')
local leftLeg = { thigh=piece 'l_thigh', shin=piece'l_leg', foot=piece'l_foot' }
local rightLeg = { thigh=piece 'r_thigh', shin=piece'r_leg', foot=piece'r_foot' }

-- constants
local smokePiece = {head}

-- signals
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

-- variables
local gun_1

local function Step(front, back)
	Move(back.shin, z_axis, 1.5, 7) --down
	Move(front.shin, z_axis, -1.5, 10) --up
	Move(base, y_axis, 2, 6)
	Move(base, z_axis, 1, 5)
	Sleep(160)

	Turn(back.thigh, x_axis, math.rad(60), math.rad(130)) --back
	Turn(front.thigh, x_axis, 0, math.rad(120)) --forward
	Turn(back.foot, x_axis, math.rad(25))
	Turn(front.foot, x_axis, math.rad(70))
	Move(base, y_axis, -0.5, 9)
	Move(base, z_axis, -1, 5)
	
	if front == leftLeg then
		Turn(base, z_axis, math.rad(8), math.rad(30))
	else
		Turn(base, z_axis, math.rad(-8), math.rad(30))
	end
	
	Sleep(200)
end

local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)

	while true do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
	end
end

function script.Create()
	gun_1 = true
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	Turn(rightLeg.thigh, x_axis, math.rad(60))
	Turn(leftLeg.thigh, x_axis, math.rad(60))
				
	Move(rightLeg.shin, z_axis, 0)
	Move(leftLeg.shin, z_axis, 0)
	
	Turn(rightLeg.foot, x_axis, math.rad(30))
	Turn(leftLeg.foot, x_axis, math.rad(30))
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Turn(rightLeg.thigh, x_axis, math.rad(60), math.rad(200))
	Turn(leftLeg.thigh, x_axis, math.rad(60), math.rad(200))
				
	Move(rightLeg.shin, z_axis, 0, 200)
	Move(leftLeg.shin, z_axis, 0, 200)
	
	Turn(rightLeg.foot, x_axis, math.rad(30), math.rad(200))
	Turn(leftLeg.foot, x_axis, math.rad(30), math.rad(200))
	
	Move(base, y_axis, 0, 200)
	Move(base, z_axis, 0, 200)
	Turn(base, z_axis, math.rad(-(0)), math.rad(200))
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(2750)
	Spin(r_gun_barr, z_axis, 0, math.rad(35))
	Spin(l_gun_barr, z_axis, 0, math.rad(35))
	Turn(head, y_axis, 0, math.rad(90))
	Turn(r_gun, x_axis, 0, math.rad(45))
	Turn(l_gun, x_axis, 0, math.rad(45))
end

function script.AimFromWeapon()
	return head
end

function script.QueryWeapon(num)
	if gun_1 then
		return r_gun_barr
	else
		return l_gun_barr
	end
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)

	Turn(head, y_axis, heading, math.rad(1000))
	Turn(l_gun, x_axis, -pitch, math.rad(500))
	Turn(r_gun, x_axis, -pitch, math.rad(500))
	WaitForTurn(head, y_axis)
	WaitForTurn(l_gun, x_axis)
	WaitForTurn(r_gun, x_axis)
	return true
end

function script.FireWeapon(num)
	gun_1 = not gun_1
	if gun_1 then
		EmitSfx(r_gun_barr, GG.Script.UNIT_SFX1)
		Spin(r_gun_barr, z_axis, math.rad(1000), math.rad(50))
	else
		EmitSfx(l_gun_barr, GG.Script.UNIT_SFX1)
		Spin(l_gun_barr, z_axis, math.rad(1000), math.rad(50))
	end
	StartThread(RestoreAfterDelay)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(head, SFX.NONE)
		Explode(l_gun_barr, SFX.NONE)
		Explode(l_gun, SFX.NONE)
		Explode(r_gun_barr, SFX.NONE)
		Explode(r_gun, SFX.NONE)
		Explode(leftLeg.thigh, SFX.NONE)
		Explode(leftLeg.shin, SFX.NONE)
		Explode(leftLeg.foot, SFX.NONE)
		Explode(rightLeg.thigh, SFX.NONE)
		Explode(rightLeg.shin, SFX.NONE)
		Explode(rightLeg.foot, SFX.NONE)
		Explode(base, SFX.NONE)
		return 1
	elseif severity <= 0.50 then
		Explode(head, SFX.FALL)
		Explode(r_gun, SFX.FALL)
		Explode(l_gun, SFX.FALL)
		Explode(l_gun_barr, SFX.FALL)
		Explode(r_gun_barr, SFX.FALL)
		Explode(leftLeg.thigh, SFX.FALL)
		Explode(leftLeg.shin, SFX.FALL)
		Explode(leftLeg.foot, SFX.FALL)
		Explode(rightLeg.thigh, SFX.FALL)
		Explode(rightLeg.shin, SFX.FALL)
		Explode(rightLeg.foot, SFX.FALL)
		Explode(base, SFX.SHATTER)
		return 1
	else
		Explode(r_gun, SFX.SHATTER)
		Explode(l_gun, SFX.SHATTER)
		Explode(r_gun_barr, SFX.SHATTER)
		Explode(l_gun_barr, SFX.SHATTER)
		Explode(leftLeg.foot, SFX.SHATTER)
		Explode(leftLeg.shin, SFX.SHATTER)
		Explode(leftLeg.thigh, SFX.SHATTER)
		Explode(rightLeg.foot, SFX.SHATTER)
		Explode(rightLeg.shin, SFX.SHATTER)
		Explode(rightLeg.thigh, SFX.SHATTER)
		Explode(base, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE_ON_HIT)
		Explode(head, SFX.FALL + SFX.SMOKE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		return 2
	end
end
