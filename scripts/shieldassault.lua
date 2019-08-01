-- original bos animation by Chris Mackey
-- converted to lua by psimyn

include 'constants.lua'

local base = piece 'base' 
local shield = piece 'shield' 
local head = piece 'head' 
local l_gun = piece 'l_gun' 
local r_gun = piece 'r_gun' 
local firept1 = piece 'firept1' 
local r_barrel = piece 'r_barrel' 
local firept2 = piece 'firept2' 
local l_barrel = piece 'l_barrel'
local l_leg, lf_lever, lb_lever, l_foot, l_heel, l_heeltoe = piece('l_leg', 'lf_lever', 'lb_lever', 'l_foot', 'l_heel', 'l_heeltoe')
local r_leg, rf_lever, rb_lever, r_foot, r_heel, r_heeltoe = piece('r_leg', 'rf_lever', 'rb_lever', 'r_foot', 'r_heel', 'r_heeltoe')
local leftLeg = { leg=piece'l_leg', flever=piece'lf_lever', blever=piece'lb_lever', foot=piece'l_foot', heel=piece'l_heel', heeltoe=piece'l_heeltoe'}
local rightLeg = { leg=piece'r_leg', flever=piece'rf_lever', blever=piece'rb_lever', foot=piece'r_foot', heel=piece'r_heel', heeltoe=piece'r_heeltoe' }

-- constants
local smokePiece = { head, l_gun, r_gun }
local PACE = 2

-- signals
local SIG_WALK = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

-- variables
local gun_1

local function Step(front, back)
	Move(base, y_axis, 0, 2)
	
	-- move and turn front leg
	Move(front.leg, z_axis, 1, 3 * PACE)
	Turn(front.blever, x_axis, math.rad(-50), math.rad(95) * PACE)
	Turn(front.foot, x_axis, math.rad(45), math.rad(80) * PACE)
	Turn(front.flever, x_axis, math.rad(-45), math.rad(65) * PACE)
	Turn(front.heeltoe, x_axis, math.rad(10), math.rad(20) * PACE)
	-- move and turn back leg
	Move(back.leg, z_axis, -2, 3 * PACE)
	Turn(back.blever, x_axis, math.rad(45), math.rad(95) * PACE)
	Turn(back.foot, x_axis, math.rad(-35), math.rad(80) * PACE)
	Turn(back.flever, x_axis, math.rad(20), math.rad(65) * PACE)
	Turn(back.heeltoe, x_axis, math.rad(-10), math.rad(20) * PACE)
	
	Move(base, y_axis, -1, 2)
	WaitForTurn(front.foot, x_axis)
	WaitForTurn(back.foot, x_axis)
	-- sleep for 1 gameframe; stops animation breaking in the Walk loop
	Sleep(0)
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
	StartThread(GG.Script.SmokeUnit, smokePiece)
	Move(base, x_axis, -2)
end

local function Stopping()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	
	Move(leftLeg.leg, z_axis, 0, 2)
	Move(rightLeg.leg, z_axis, 0, 2)
	Turn(leftLeg.blever, x_axis, 0, math.rad(45))
	Turn(leftLeg.foot, x_axis, 0, math.rad(45))
	Turn(leftLeg.flever, x_axis, 0, math.rad(45))
	Turn(leftLeg.heeltoe, x_axis, 0, math.rad(45))
	Turn(rightLeg.blever, x_axis, 0, math.rad(45))
	Turn(rightLeg.foot, x_axis, 0, math.rad(45))
	Turn(rightLeg.flever, x_axis, 0, math.rad(45))
	Turn(rightLeg.heeltoe, x_axis, 0, math.rad(45))
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
	Sleep(3000)
	--move all the pieces to their original spots
	Turn(head, y_axis, 0, math.rad(100))
	Turn(l_gun, x_axis, 0, math.rad(100))
	Turn(r_gun, x_axis, 0, math.rad(100))
end

function script.AimFromWeapon() 
	return head
end

function script.AimWeapon(num, heading, pitch)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	
	Turn(head, y_axis, heading, math.rad(100))
	Turn(l_gun, x_axis, -pitch, math.rad(100))
	Turn(r_gun, x_axis, -pitch, math.rad(100))
	WaitForTurn(head, y_axis)
	
	StartThread(RestoreAfterDelay)
	return 1 -- allows fire weapon after WaitForTurn
end

function script.FireWeapon() 
	gun_1 = not gun_1
	if gun_1 then
		EmitSfx(firept1, GG.Script.UNIT_SFX1)
		EmitSfx(firept1, GG.Script.UNIT_SFX2)
		Move(r_barrel, z_axis, -4, 0)
		Move(r_gun, z_axis, -2, 0)

		Move(r_barrel, z_axis, 0, 2.5)
		Move(r_gun, z_axis, 0, 1.25)
		else
		EmitSfx(firept2, GG.Script.UNIT_SFX1)
		EmitSfx(firept2, GG.Script.UNIT_SFX2)
		Move(l_barrel, z_axis, -4, 0)
		Move(l_gun, z_axis, -2, 0)

		Move(l_barrel, z_axis, 0, 2.5)
		Move(l_gun, z_axis, 0, 1.25)
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		-- Gun
		if gun_1 then
			return firept1
		else 
			return firept2
		end
	else
		-- Shield
		return shield
	end
end

function script.BlockShot(num, targetID)
	if Spring.ValidUnitID(targetID) then
		local distMult = (Spring.GetUnitSeparation(unitID, targetID) or 0)/280
		return GG.OverkillPrevention_CheckBlock(unitID, targetID, 170.1, 35 * distMult, false, false, true)
	end
	return false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= 0.25 then
		Explode(head, SFX.NONE)
		Explode(l_gun, SFX.NONE)
		Explode(r_gun, SFX.NONE)
		Explode(leftLeg.leg, SFX.NONE)
		Explode(leftLeg.flever, SFX.NONE)
		Explode(leftLeg.blever, SFX.NONE)
		Explode(leftLeg.foot, SFX.NONE)
		Explode(leftLeg.heel, SFX.NONE)
		Explode(leftLeg.heeltoe, SFX.NONE)
		Explode(rightLeg.leg, SFX.NONE)
		Explode(rightLeg.flever, SFX.NONE)
		Explode(rightLeg.blever, SFX.NONE)
		Explode(rightLeg.foot, SFX.NONE)
		Explode(rightLeg.heel, SFX.NONE)
		Explode(rightLeg.heeltoe, SFX.NONE)
		return 1
	elseif severity <= 0.5 then
		Explode(head, SFX.NONE)
		Explode(l_gun, SFX.NONE)
		Explode(r_gun, SFX.FALL + SFX.EXPLODE_ON_HIT)
		Explode(leftLeg.leg, SFX.FALL + SFX.EXPLODE_ON_HIT)
		Explode(rightLeg.leg, SFX.NONE)
		Explode(leftLeg.foot, SFX.NONE)
		Explode(rightLeg.foot, SFX.NONE)
		Explode(leftLeg.blever, SFX.NONE)
		Explode(rightLeg.blever, SFX.NONE)
		Explode(leftLeg.flever, SFX.NONE)
		Explode(rightLeg.flever, SFX.NONE)
		Explode(leftLeg.heel, SFX.NONE)
		Explode(rightLeg.heel, SFX.NONE)
		Explode(leftLeg.heeltoe, SFX.NONE)
		Explode(rightLeg.heeltoe, SFX.NONE)
		return 1
	else
		Explode(head, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(l_gun, SFX.NONE)
		Explode(r_gun, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(leftLeg.leg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rightLeg.leg, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(leftLeg.foot, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rightLeg.foot, SFX.NONE)
		Explode(leftLeg.blever, SFX.NONE)
		Explode(rightLeg.blever, SFX.NONE)
		Explode(leftLeg.flever, SFX.FALL + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rightLeg.flever, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(leftLeg.heel, SFX.NONE)
		Explode(rightLeg.heel, SFX.NONE)
		Explode(leftLeg.heeltoe, SFX.SHATTER + SFX.FIRE + SFX.SMOKE + SFX.EXPLODE_ON_HIT)
		Explode(rightLeg.heeltoe, SFX.NONE)
		return 2
	end
end
