-- original bos animation by Chris Mackey
-- converted to lua by psimyn

include 'constants.lua'

local base = piece 'base' 
local head = piece 'head' 
local l_gun = piece 'l_gun' 
local r_gun = piece 'r_gun' 
local firept1 = piece 'firept1' 
local r_barrel = piece 'r_barrel' 
local firept2 = piece 'firept2' 
local l_barrel = piece 'l_barrel' 
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
	Move( base , y_axis, 0 , 2 )
	
	-- move and turn front leg
	Move( front.leg, z_axis, 1, 3 * PACE)
	Turn( front.blever , x_axis, math.rad(-50), math.rad(95) * PACE)
	Turn( front.foot , x_axis, math.rad(45), math.rad(80) * PACE)
	Turn( front.flever , x_axis, math.rad(-45), math.rad(65) * PACE)
	Turn( front.heeltoe , x_axis, math.rad(10), math.rad(20) * PACE)
	-- move and turn back leg
	Move( back.leg, z_axis, -2, 3 * PACE)
	Turn( back.blever , x_axis, math.rad(45), math.rad(95) * PACE)
	Turn( back.foot , x_axis, math.rad(-35), math.rad(80) * PACE)
	Turn( back.flever , x_axis, math.rad(20), math.rad(65) * PACE)
	Turn( back.heeltoe , x_axis, math.rad(-10), math.rad(20) * PACE)
	
	Move( base , y_axis, -1 , 2 )
	WaitForTurn(front.foot, x_axis)
	WaitForTurn(back.foot, x_axis)
	-- sleep for 1 gameframe; stops animation breaking in the Walk loop
	Sleep(0)
end

local function Walk()
	Signal( SIG_WALK )
	SetSignalMask( SIG_WALK )

	while  true  do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
	end
end

function script.Create()
	gun_1 = true
	StartThread(SmokeUnit)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal( SIG_WALK )
	Move( leftLeg.leg, z_axis, 0, 2)
	Move( rightLeg.leg, z_axis, 0, 2)
	for i=1, #leftLeg do
		Turn( leftLeg[i] , x_axis, 0, math.rad(180) )
		Turn( rightLeg[i] , x_axis, 0, math.rad(180) )
	end
end

local function RestoreAfterDelay()
	Signal( SIG_RESTORE )
	SetSignalMask( SIG_RESTORE )
	Sleep(3000)
	--move all the pieces to their original spots
	Turn( head , y_axis, 0, math.rad(100) )
	Turn( l_gun , x_axis, 0, math.rad(100) )
	Turn( r_gun , x_axis, 0, math.rad(100) )
end

-- gun functions
function script.QueryWeapon1()
	if gun_1 then
		return firept1
	else 
		return firept2
	end
end

function script.AimWeapon1(heading, pitch)
	Signal( SIG_AIM )
	SetSignalMask( SIG_AIM )
	-- turn to face target
	Turn( head , y_axis, heading, math.rad(100) )
	-- aim down when shooting close, up a little for farther away
	local guntilt
	if pitch < 0.25 then
		guntilt = pitch
	else
		guntilt = -pitch/2
	end
	Turn( l_gun , x_axis, guntilt, math.rad(100) )
	Turn( r_gun , x_axis, guntilt, math.rad(100) )
	WaitForTurn(head, y_axis)
	
	StartThread(RestoreAfterDelay)
	return 1 -- allows fire weapon after WaitForTurn
end

function script.FireWeapon1() 
	gun_1 = not gun_1
	if gun_1 then
		EmitSfx( firept1, UNIT_SFX1 )
		EmitSfx( firept1, UNIT_SFX2 )
		Move( r_barrel , z_axis, -2 , 500 )
		WaitForMove(r_barrel, z_axis)
		Move( r_barrel , z_axis, 0 , 5 )
	else
		EmitSfx( firept2, UNIT_SFX1 )
		EmitSfx( firept2, UNIT_SFX2 )
		Move( l_barrel , z_axis, -2 , 500 )
		WaitForMove(l_barrel, z_axis)
		Move( l_barrel , z_axis, 0 , 5 )
	end
end

-- shield
function script.QueryWeapon2()
	return base
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= 0.25  then
		Explode(head, sfxNone)
		Explode(l_gun, sfxNone)
		Explode(r_gun, sfxNone)
		for i=1, #leftLeg do
			Explode(leftLeg[i], sfxNone)
			Explode(rightLeg[i], sfxNone)
		end
		return 1
	elseif  severity <= 0.5  then
		Explode(head, sfxNone)
		Explode(l_gun, sfxNone)
		Explode(r_gun, sfxFall + sfxExplodeOnHit )
		Explode(l_leg, sfxFall + sfxExplodeOnHit )
		Explode(r_leg, sfxNone)
		Explode(l_foot, sfxNone)
		Explode(r_foot, sfxNone)
		Explode(lb_lever, sfxNone)
		Explode(rb_lever, sfxNone)
		Explode(lf_lever, sfxNone)
		Explode(rf_lever, sfxNone)
		Explode(l_heel, sfxNone)
		Explode(r_heel, sfxNone)
		Explode(l_heeltoe, sfxNone)
		Explode(r_heeltoe, sfxNone)
		return 1
	else
		Explode(head, sfxShatter + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(l_gun, sfxNone)
		Explode(r_gun, sfxFall + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(leftLeg.leg, sfxFall + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(rightLeg.leg, sfxFall + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(leftLeg.foot, sfxShatter + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(rightLeg.foot, sfxNone)
		Explode(leftLeg.blever, sfxNone)
		Explode(rightLeg.blever, sfxNone)
		Explode(leftLeg.flever, sfxFall + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(rightLeg.flever, sfxShatter + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(leftLeg.heel, sfxNone)
		Explode(rightLeg.heel, sfxNone)
		Explode(leftLeg.heeltoe, sfxShatter + sfxFire  + sfxSmoke  + sfxExplodeOnHit )
		Explode(rightLeg.heeltoe, sfxNone)
		return 2
	end
end
