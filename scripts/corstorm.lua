local base = piece 'base' 
local head = piece 'head' 
local popup = piece 'popup' 
local l_missile = piece 'l_missile' 
local l_tube = piece 'l_tube' 
local l_door = piece 'l_door' 
local l_doorslid = piece 'l_doorslid' 
local l_flare = piece 'l_flare' 
local r_missile = piece 'r_missile' 
local r_tube = piece 'r_tube' 
local r_door = piece 'r_door' 
local r_doorslid = piece 'r_doorslid' 
local r_flare = piece 'r_flare' 
local l_thigh = piece 'l_thigh' 
local l_leg = piece 'l_leg' 
local l_shin = piece 'l_shin' 
local l_foot = piece 'l_foot' 
local l_toe = piece 'l_toe' 
local lf_toe = piece 'lf_toe' 
local lb_toe = piece 'lb_toe' 
local r_thigh = piece 'r_thigh' 
local r_leg = piece 'r_leg' 
local r_shin = piece 'r_shin' 
local r_foot = piece 'r_foot' 
local r_toe = piece 'r_toe' 
local rf_toe = piece 'rf_toe' 
local rb_toe = piece 'rb_toe' 

include "constants.lua"

local gun_1 = math.random() > 0.5

smokePiece = {base, head}

-- Signal( definitions
local SIG_MOVE = 2
local SIG_AIM = 4

local RESTORE_DELAY = 1000

local function walk()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)

	Move(base, y_axis, 10, 30)
	
	while true do
		--part one
		Move( base , y_axis, 3 , 1 )
		Turn( head , z_axis, math.rad(-(6)), math.rad(3) )
		Turn( head , x_axis, math.rad(4), math.rad(5) )
		--right backward
		Turn( r_thigh , x_axis, math.rad(10), math.rad(140) )
		WaitForTurn(r_thigh, x_axis)
		Turn( r_thigh , x_axis, math.rad(45), math.rad(100) )
		Turn( r_leg , x_axis, math.rad(80), math.rad(140) )
		Turn( r_foot , x_axis, math.rad(-40), math.rad(140) )
		Turn( rf_toe , x_axis, math.rad(-40), math.rad(180) )
		Turn( rb_toe , x_axis, math.rad(-50), math.rad(180) )
		Turn( r_toe , z_axis, math.rad(-(20)), math.rad(140) )
		--left forward
		Turn( l_thigh , x_axis, math.rad(-80), math.rad(220) )
		Turn( l_leg , x_axis, math.rad(120), math.rad(220) )
		Turn( l_foot , x_axis, math.rad(-10), math.rad(190) )
		Turn( lf_toe , x_axis, 0, math.rad(180) )
		Turn( lb_toe , x_axis, 0, math.rad(180) )
		Turn( l_toe , z_axis, math.rad(-(0)), math.rad(140) )
		WaitForTurn(l_thigh, x_axis)
		
		--part two
		Move( base , y_axis, 0 , 1.6 )
		Turn( head , z_axis, math.rad(-(-3)), math.rad(3) )
		Turn( head , x_axis, math.rad(-7), math.rad(5) )
		--right back to front
		Turn( r_leg , x_axis, math.rad(-10), math.rad(150) )
		Turn( r_foot , x_axis, math.rad(-10), math.rad(150) )
		Turn( rf_toe , x_axis, math.rad(40), math.rad(180) )
		Turn( rb_toe , x_axis, math.rad(-30), math.rad(180) )
		Turn( r_toe , z_axis, math.rad(-(25)), math.rad(140) )
		--left front to back
		Turn( l_thigh , x_axis, math.rad(-10), math.rad(140) )
		Turn( l_leg , x_axis, math.rad(30), math.rad(160) )
		Turn( l_foot , x_axis, math.rad(-15), math.rad(60) )
		Sleep(100)
		
		--part three
		Move( base , y_axis, 3 , 1 )
		Turn( head , z_axis, math.rad(-(5)), math.rad(3) )
		Turn( head , x_axis, math.rad(3), math.rad(5) )
		--left backward
		Turn( l_thigh , x_axis, math.rad(10), math.rad(140) )
		WaitForTurn(l_thigh, x_axis)
		Turn( l_thigh , x_axis, math.rad(45), math.rad(100) )
		Turn( l_leg , x_axis, math.rad(80), math.rad(140) )
		Turn( l_foot , x_axis, math.rad(-40), math.rad(140) )
		Turn( lf_toe , x_axis, math.rad(-40), math.rad(180) )
		Turn( lb_toe , x_axis, math.rad(-50), math.rad(180) )
		Turn( l_toe , z_axis, math.rad(-(20)), math.rad(140) )
		--right forward
		Turn( r_thigh , x_axis, math.rad(-80), math.rad(220) )
		Turn( r_leg , x_axis, math.rad(120), math.rad(220) )
		Turn( r_foot , x_axis, math.rad(-10), math.rad(190) )
		Turn( rf_toe , x_axis, 0, math.rad(180) )
		Turn( rb_toe , x_axis, 0, math.rad(180) )
		Turn( r_toe , z_axis, math.rad(-(0)), math.rad(140) )
		WaitForTurn(r_thigh, x_axis)
		
		--part four
		Move( base , y_axis, 0 , 1.6 )
		Turn( head , z_axis, math.rad(-(-5)), math.rad(8) )
		Turn( head , x_axis, math.rad(-3), math.rad(10) )
		--left back to front
		Turn( l_leg , x_axis, math.rad(-10), math.rad(150) )
		Turn( l_foot , x_axis, math.rad(-10), math.rad(150) )
		Turn( lf_toe , x_axis, math.rad(40), math.rad(180) )
		Turn( lb_toe , x_axis, math.rad(-30), math.rad(180) )
		Turn( l_toe , z_axis, math.rad(-(25)), math.rad(140) )
		-- right front to back
		Turn( r_thigh , x_axis, math.rad(-10), math.rad(140) )
		Turn( r_leg , x_axis, math.rad(30), math.rad(160) )
		Turn( r_foot , x_axis, math.rad(-15), math.rad(60) )
		Sleep(100)
	end
end


local function stopWalk()
	Signal( SIG_MOVE)
	SetSignalMask( SIG_MOVE)
	--move all the pieces to their original spots
	Turn( r_thigh , x_axis, math.rad(18), math.rad(200) )
	Turn( r_leg , x_axis, math.rad(30), math.rad(200) )
	Turn( r_foot , x_axis, math.rad(-18), math.rad(200) )
	Turn( r_toe , z_axis, math.rad(-(0)), math.rad(200) )
	Turn( rf_toe , x_axis, 0, math.rad(200) )
	Turn( rb_toe , x_axis, 0, math.rad(200) )
	
	Turn( l_thigh , x_axis, math.rad(18), math.rad(200) )
	Turn( l_leg , x_axis, math.rad(30), math.rad(200) )
	Turn( l_foot , x_axis, math.rad(-18), math.rad(200) )
	Turn( l_toe , z_axis, math.rad(-(0)), math.rad(200) )
	Turn( lf_toe , x_axis, 0, math.rad(200) )
	Turn( lb_toe , x_axis, 0, math.rad(200) )
	
	Move( base , y_axis, 6 , 8 )
	Turn( head , z_axis, math.rad(-(0)), math.rad(200) )
	Turn( head , x_axis, 0, math.rad(200) )

end

function script.StartMoving()
	StartThread(walk)
end

function script.StopMoving()
	StartThread(stopWalk)
end

function script.Create()
	StartThread(SmokeUnit)
	--gun_1 = torso
	Turn( r_thigh , x_axis, math.rad(30) )
	Turn( l_thigh , x_axis, math.rad(30) )
	Move( base , y_axis, 6 )
	StartThread(stopWalk)
end

local function RestoreAfterDelayLeft() 
	Sleep(RESTORE_DELAY)
	Turn( l_tube , x_axis, math.rad(0 ), math.rad(45) )
	Move( l_missile , z_axis, 0  )
	Move( l_missile , y_axis, .4  )
	Move( l_missile , x_axis, 6  )
	WaitForTurn(l_tube, x_axis)
	Show( l_missile)
	Move( l_door , z_axis, 0.5 , 1 )
	Move( l_doorslid , z_axis, -1 , 1 )
	WaitForMove(l_doorslid, z_axis)
	Turn( l_door , z_axis, math.rad(-(-100)), math.rad(90) )
	WaitForTurn(l_door, z_axis)
	Spin( l_missile , z_axis, math.rad(90) )
	Move( l_missile , y_axis, 0 , .4 )
	Move( l_missile , x_axis, -0 , 2 )
	WaitForMove(l_missile, x_axis)
	Spin( l_missile , z_axis, 0 )
	Move( l_door , z_axis, 0 , 1 )
	Move( l_doorslid , z_axis, 0 , 1 )
	Turn( l_door , z_axis, math.rad(-(0)), math.rad(90) )
	
	Sleep(3000)
	Turn( head , y_axis, math.rad(0 ), math.rad(90) )
	Turn( r_tube , x_axis, math.rad(0 ), math.rad(45) )
end

local function RestoreAfterDelayRight() 
	Sleep(RESTORE_DELAY)
	Turn( r_tube , x_axis, math.rad(0 ), math.rad(45) )
	Move( r_missile , z_axis,5* 0  )
	Move( r_missile , y_axis, .4  )
	Move( r_missile , x_axis, -6 )
	WaitForTurn(r_tube, x_axis)
	Show( r_missile)
	Move( r_door , z_axis, 0.5 , 1 )
	Move( r_doorslid , z_axis, -1 , 1 )
	WaitForMove(r_doorslid, z_axis)
	Turn( r_door , z_axis, math.rad(-(100)), math.rad(90) )
	WaitForTurn(r_door, z_axis)
	Spin( r_missile , z_axis, math.rad(-90) )
	Move( r_missile , y_axis, 0 , .4 )
	Move( r_missile , x_axis, -0 , 2 )
	WaitForMove(r_missile, x_axis)
	Spin( r_missile , z_axis, 0 )
	Move( r_door , z_axis, 0 , 1 )
	Move( r_doorslid , z_axis, 0 , 1 )
	Turn( r_door , z_axis, math.rad(-(0)), math.rad(90) )
	
	Sleep(2000)
	Turn( head , y_axis, math.rad(0 ), math.rad(90) )
	Turn( l_tube , x_axis, math.rad(0 ), math.rad(45) )
end

function script.AimWeapon(num, heading, pitch) 

	Signal( SIG_AIM)
	SetSignalMask( SIG_AIM)
	Turn( head , y_axis, heading , math.rad(90) )
	if gun_1 then
	
		Turn( l_tube , x_axis, -pitch , math.rad(45) )
		WaitForTurn(head, y_axis)
		WaitForTurn(l_tube, x_axis)
	end
	if not gun_1 then
	
		Turn( r_tube , x_axis, -pitch, math.rad(45) )
		WaitForTurn(head, y_axis)
		WaitForTurn(r_tube, x_axis)
	end
	return true
end

function script.AimFromWeapon(num) 
	return popup
end

function script.QueryWeapon(num) 
	if gun_1 then 
		return l_flare
	else 
		return r_flare
	end
end

function script.FireWeapon(num) 

	if gun_1 then 
	
		Move( l_missile , z_axis, 10 , 100 )
		WaitForMove(l_missile, z_axis)
		Hide( l_missile)
		StartThread(RestoreAfterDelayLeft)
	else 
	
		Move( r_missile , z_axis, 10 , 100 )
		WaitForMove(r_missile, z_axis)
		Hide( r_missile)
		StartThread(RestoreAfterDelayRight)
	end
	
	gun_1 = not gun_1
	--StartThread(RestoreAfterDelay)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25  then
		Explode(base, sfxNone)
		Explode(r_tube, sfxNone)
		Explode(l_missile, sfxNone)
		Explode(l_foot, sfxNone)
		Explode(l_leg, sfxNone)
		Explode(l_thigh, sfxNone)
		Explode(popup, sfxNone)
		Explode(r_missile, sfxNone)
		Explode(r_foot, sfxNone)
		Explode(r_leg, sfxNone)
		Explode(r_thigh, sfxNone)
		Explode(head, sfxNone)
		Explode(l_tube, sfxNone)
		return 1
	end
	if  severity <= 50  then
	
		corpsetype = 2
		Explode(base, sfxFall)
		Explode(r_tube, sfxShatter)
		Explode(l_missile, sfxFall)
		Explode(l_foot, sfxFall)
		Explode(l_leg, sfxFall)
		Explode(l_thigh, sfxFall)
		Explode(popup, sfxFall)
		Explode(r_missile, sfxFall)
		Explode(r_foot, sfxFall)
		Explode(r_leg, sfxFall)
		Explode(r_thigh, sfxFall)
		Explode(head, sfxFall)
		Explode(l_tube, sfxFall)
		return (0)
	end
	if  severity <= 99  then
	
		corpsetype = 3
		Explode(base, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(r_tube, sfxShatter)
		Explode(l_missile, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(l_foot, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(l_leg, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(l_thigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(popup, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(r_missile, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(r_foot, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(r_leg, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(r_thigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(head, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		Explode(l_tube, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
		return (0)
	end
	corpsetype = 3
	Explode(base, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(r_tube, sfxShatter + sfxExplodeOnHit )
	Explode(l_missile, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(l_foot, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(l_leg, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(l_thigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(popup, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(r_missile, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(r_foot, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(r_leg, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(r_thigh, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(head, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
	Explode(l_tube, sfxFall + sfxSmoke  + sfxFire  + sfxExplodeOnHit )
end

