
--by Chris Mackey
include "smokeunit.lua"

--pieces
local b_dome = piece "b_dome"
local t_dome = piece "t_dome"
local b_eye = piece "b_eye"
local t_eye = piece "t_eye"

-- guns
local l_turn = piece "l_turn"
local l_turret = piece "l_turret"
local l_pivot = piece "l_pivot"
local l_barrel = piece "l_barrel"

local r_turn = piece "r_turn"
local r_turret = piece "r_turret"
local r_pivot = piece "r_pivot"
local r_barrel = piece "r_barrel"

-- legs
local lf_ball = piece "lf_ball"
local lf_thigh = piece "lf_thigh"
local lf_shin = piece "lf_shin"
local lf_ankle = piece "lf_ankle"
local lf_pump = piece "lf_pump"
local lf_foot = piece "lf_foot"

local rf_ball = piece "rf_ball"
local rf_thigh = piece "rf_thigh"
local rf_shin = piece "rf_shin"
local rf_ankle = piece "rf_ankle"
local rf_pump = piece "rf_pump"
local rf_foot = piece "rf_foot"

local lb_ball = piece "lb_ball"
local lb_thigh = piece "lb_thigh"
local lb_shin = piece "lb_shin"
local lb_ankle = piece "lb_ankle"
local lb_pump = piece "lb_pump"
local lb_foot = piece "lb_foot"

local rb_ball = piece "rb_ball"
local rb_thigh = piece "rb_thigh"
local rb_shin = piece "rb_shin"
local rb_ankle = piece "rb_ankle"
local rb_pump = piece "rb_pump"
local rb_foot = piece "rb_foot"

local smokePieces = { t_dome, t_eye, l_turret, r_turret, lf_thigh, rf_thigh, lb_thigh, rb_thigh }

--constants
local sp1 = 1.2
local sp2 = 1
local lf_angle = math.rad( 25 )
local rf_angle = math.rad( -25 )
local lb_angle = math.rad( -65 )
local rb_angle = math.rad( 65 )

local p_angle = -.3
local th_angle = -.3
local th_speed = 1.1
local sh_angle = .4
local sh_speed = 1
local drop = .8

local dirtfling = 1024
local crater = 4098

--variables

--signals
local walk = 2
local aim  = 4

local function Walk()

	SetSignalMask( walk )
	
	Turn( lf_pump, x_axis, -p_angle, 1.4 )
	Turn( rf_pump, x_axis, -p_angle, 1.4 )
	Turn( lb_pump, x_axis, p_angle, 1.4 )
	Turn( rb_pump, x_axis, p_angle, 1.4 )
		
	while ( true ) do
	--PART 1 ----------------------------------------------------
		-- lift forward (left)
		Move( b_dome, y_axis, 5, 5 ) -- up
		Turn( t_dome, y_axis, .1, -.2 )
		
		Move( lf_shin, y_axis, 0, 2 ) -- neut
		Move( rf_shin, y_axis, -2, 7 ) -- down
		Move( lb_shin, y_axis, -2, 7 ) -- down
		Move( rb_shin, y_axis, 0, 2 ) -- neut
		
		EmitSfx( rf_foot, dirtfling )
		EmitSfx( lb_foot, dirtfling )
		
		Turn( lf_ball, y_axis, lf_angle, sp1 ) -- left front leg forward
		Turn( rf_ball, y_axis, -rb_angle, sp2 ) -- right front leg backward
		Turn( lb_ball, y_axis, -lf_angle, sp2 ) -- left back leg backward
		Turn( rb_ball, y_axis, rb_angle, sp1 ) -- right back leg forward
		
		Turn( lf_thigh, x_axis, 0, th_speed )
		Turn( rf_thigh, x_axis, -th_angle, th_speed )
		Turn( lb_thigh, x_axis, th_angle, th_speed )
		Turn( rb_thigh, x_axis, 0, th_speed )
		
		Turn( rf_shin, x_axis, 0, sh_speed ) -- down
		Turn( rb_shin, x_axis, 0, sh_speed ) -- down
		Turn( rf_foot, x_axis, -0.3, sh_speed+.7 )
		Turn( rb_foot, x_axis, 0, sh_speed )
		
		Turn( lf_foot, y_axis, math.rad(20), sp1 )
		Turn( rf_foot, y_axis, math.rad(20), sp2 )
		Turn( lb_foot, y_axis, -math.rad(20), sp2 )
		Turn( rb_foot, y_axis, -math.rad(20), sp1 )
		
		WaitForTurn( rb_ball, y_axis )
		Sleep(50)
	
	--PART 2 ----------------------------------------------------
		-- down forward (left)
		Move( b_dome, y_axis, 0, 15 ) -- down
		
		Move( lf_shin, y_axis, 0, 10 ) -- neut
		Move( rf_shin, y_axis, 0, 10 ) -- neut
		Move( lb_shin, y_axis, 0, 10 ) -- neut
		Move( rb_shin, y_axis, 0, 10 ) -- neut
		
		Turn( lf_shin, x_axis, 0, sh_speed ) -- down
		Turn( lb_shin, x_axis, 0, sh_speed ) -- down
		Turn( lf_foot, x_axis, -0.3, sh_speed+.7 )
		Turn( lb_foot, x_axis, 0, sh_speed )
		
		Turn( lf_shin, x_axis, 0, th_speed )
		Turn( rf_shin, x_axis, 0, th_speed )
		Turn( lb_shin, x_axis, 0, th_speed )
		Turn( rb_shin, x_axis, 0, th_speed )
		
		Sleep( 100 )
		
	--PART 3 ----------------------------------------------------
		-- lift forward (right)
		Move( b_dome, y_axis, 5, 5 ) -- up
		Turn( t_dome, y_axis, .1, .2 )
		
		Move( lf_shin, y_axis, -2, 7 ) -- down
		Move( rf_shin, y_axis, 0, 2 ) -- neut
		Move( lb_shin, y_axis, 0, 2 ) -- neut
		Move( rb_shin, y_axis, -2, 7 ) -- down
		
		EmitSfx( lf_foot, dirtfling )
		EmitSfx( rb_foot, dirtfling )
		
		Turn( lf_ball, y_axis, -lb_angle, sp2 ) -- left front leg backward
		Turn( rf_ball, y_axis, rf_angle, sp1 ) -- right front leg forward
		Turn( lb_ball, y_axis, lb_angle, sp1 ) -- left front leg forward
		Turn( rb_ball, y_axis, -rf_angle, sp2 ) -- right back leg backward
		
		Turn( lf_thigh, x_axis, -th_angle, th_speed )
		Turn( rf_thigh, x_axis, 0, th_speed )
		Turn( lb_thigh, x_axis, 0, th_speed )
		Turn( rb_thigh, x_axis, th_angle, th_speed )
		
		Turn( rf_shin, x_axis, -sh_angle, sh_speed ) -- extended
		Turn( rb_shin, x_axis, sh_angle, sh_speed ) -- extended
		Turn( rf_foot, x_axis, sh_angle, sh_speed )
		Turn( rb_foot, x_axis, -sh_angle+0.3, sh_speed+.7 )
		
		Turn( lf_foot, y_axis, -math.rad(20), sp2 )
		Turn( rf_foot, y_axis, -math.rad(20), sp1 )
		Turn( lb_foot, y_axis, math.rad(20), sp1 )
		Turn( rb_foot, y_axis, math.rad(20), sp2 )
		
		WaitForTurn( lb_ball, y_axis )
		Sleep(50)
		
	--PART 4 ----------------------------------------------------
		-- down forward (right)
		Move( b_dome, y_axis, 0, 15 ) -- down
		
		Move( lf_shin, y_axis, 0, 10 ) -- neut
		Move( rf_shin, y_axis, 0, 10 ) -- neut
		Move( lb_shin, y_axis, 0, 10 ) -- neut
		Move( rb_shin, y_axis, 0, 10 ) -- neut
		
		Turn( lf_thigh, x_axis, 0, th_speed )
		Turn( rf_thigh, x_axis, 0, th_speed )
		Turn( lb_thigh, x_axis, 0, th_speed )
		Turn( rb_thigh, x_axis, 0, th_speed )
		
		Turn( lf_shin, x_axis, -sh_angle, sh_speed ) -- extended
		Turn( lb_shin, x_axis, sh_angle, sh_speed ) -- extended
		Turn( lf_foot, x_axis, sh_angle, sh_speed )
		Turn( lb_foot, x_axis, -sh_angle+0.3, sh_speed+.7 )
		
		Sleep( 100 )
		
	end
end

local function RAD()
	Sleep( 1000 )
	Turn( l_turret, y_axis, 0, 1 )
	Turn( l_pivot, x_axis, 0, 1 )
	Turn( r_turret, y_axis, 0, 1 )
	Turn( r_pivot, x_axis, 0, 1 )
end

-- Jumping
function preJump(turn,distance)

	local radians = turn*2*math.pi/2^16
	local x = math.cos(radians)
	local z = -math.sin(radians)
	
	local disFactor = distance/300
	
	local lf_Factor = (-x + z)*disFactor
	local rf_Factor = (-x - z)*disFactor
	local lb_Factor = (x + z)*disFactor
	local rb_Factor = (x - z)*disFactor
	
	Turn( b_dome, x_axis, disFactor*x/3, math.abs(x)/2 )
	Turn( b_dome, z_axis, disFactor*z/3, math.abs(z)/2 )
	
	Signal( walk ) 	
	Move( t_dome, y_axis, 0, 10 )
	Move( b_dome, y_axis, 0, 20 )

	Turn( lf_ball, y_axis, math.rad(45), sp1 )
	Turn( rf_ball, y_axis, math.rad(-45), sp1 )
	Turn( lb_ball, y_axis, math.rad(-45), sp1 )
	Turn( rb_ball, y_axis, math.rad(45), sp1 )
	
	Turn( lf_thigh, x_axis, math.rad(30)*lf_Factor+math.rad(5), th_speed )
	Turn( rf_thigh, x_axis, math.rad(30)*rf_Factor+math.rad(5), th_speed )
	Turn( lb_thigh, x_axis, math.rad(-30)*lb_Factor+math.rad(-5), th_speed )
	Turn( rb_thigh, x_axis, math.rad(-30)*rb_Factor+math.rad(-5), th_speed )
		
	Move( lf_shin, y_axis, 0, 10 )
	Move( rf_shin, y_axis, 0, 10 )
	Move( lb_shin, y_axis, 0, 10 )
	Move( rb_shin, y_axis, 0, 10 )
	
	Turn( t_dome, y_axis, 0, 1 )
	
	Turn( lf_shin, x_axis, math.rad(40), th_speed )
	Turn( rf_shin, x_axis, math.rad(40), th_speed )
	Turn( lb_shin, x_axis, math.rad(-40), th_speed )
	Turn( rb_shin, x_axis, math.rad(-40), th_speed )
	
	Turn( lf_pump, x_axis, 0, 1.4 )
	Turn( rf_pump, x_axis, 0, 1.4 )
	Turn( lb_pump, x_axis, 0, 1.4 )
	Turn( rb_pump, x_axis, 0, 1.4 )
		
	Turn( lf_foot, x_axis, math.rad(-35), sp1 )
	Turn( rf_foot, x_axis, math.rad(-35), sp1 )
	Turn( lb_foot, x_axis, math.rad(35), sp1 )
	Turn( rb_foot, x_axis, math.rad(35), sp1 )
	
	Turn( lf_foot, y_axis, 0, sp1 )
	Turn( rf_foot, y_axis, 0, sp1 )
	Turn( lb_foot, y_axis, 0, sp1 )
	Turn( rb_foot, y_axis, 0, sp1 )
end

function beginJump()

	Turn( b_dome, x_axis, 0, 0.2 )
	Turn( b_dome, z_axis, 0, 0.2)

	Turn( lf_thigh, x_axis, math.rad(80), 7 )
	Turn( rf_thigh, x_axis, math.rad(80),  7)
	Turn( lb_thigh, x_axis, math.rad(-80), 7 )
	Turn( rb_thigh, x_axis, math.rad(-80), 7 )
	
	Turn( lf_shin, x_axis, math.rad(-70), 7.8 )
	Turn( rf_shin, x_axis, math.rad(-70), 7.8 )
	Turn( lb_shin, x_axis, math.rad(70), 7.8 )
	Turn( rb_shin, x_axis, math.rad(70), 7.8 )
	
	Turn( lf_pump, x_axis, math.rad(40), 7 )
	Turn( rf_pump, x_axis, math.rad(40), 7 )
	Turn( lb_pump, x_axis, math.rad(-40), 7 )
	Turn( rb_pump, x_axis, math.rad(-40), 7 )
	
	Turn( lf_foot, x_axis, 0, 7 )
	Turn( rf_foot, x_axis, 0, 7 )
	Turn( lb_foot, x_axis, 0, 7 )
	Turn( rb_foot, x_axis, 0, 7 )

end

function jumping()
end

function halfJump()
	
	Turn( lf_thigh, x_axis, 0, 2 )
	Turn( rf_thigh, x_axis, 0, 2 )
	Turn( lb_thigh, x_axis, 0, 2 )
	Turn( rb_thigh, x_axis, 0, 2 )
	
	Turn( lf_shin, x_axis, 0, 2 )
	Turn( rf_shin, x_axis, 0, 2 )
	Turn( lb_shin, x_axis, 0, 2 )
	Turn( rb_shin, x_axis, 0, 2 )
	
	Turn( lf_pump, x_axis, 0, 1.4 )
	Turn( rf_pump, x_axis, 0, 1.4 )
	Turn( lb_pump, x_axis, 0, 1.4 )
	Turn( rb_pump, x_axis, 0, 1.4 )

end


function endJump()
	
	EmitSfx( b_dome, crater )
	
	EmitSfx( rf_foot, dirtfling )
	EmitSfx( lf_foot, dirtfling )
	EmitSfx( rb_foot, dirtfling )
	EmitSfx( lb_foot, dirtfling )
end

-- Other stuff

function script.Create()
	Turn( l_turn, z_axis, math.rad(-45) )
	Turn( r_turn, z_axis, math.rad(45) )
	Turn( lf_ball, y_axis, math.rad(45) )
	Turn( rf_ball, y_axis, math.rad(-45) )
	Turn( lb_ball, y_axis, math.rad(-45) )
	Turn( rb_ball, y_axis, math.rad(45) )
	StartThread(SmokeUnit, smokePieces)
end

function script.StartMoving()
	StartThread( Walk )
end

function script.StopMoving()

	Signal( walk )
	StartThread( RAD )
	Move( t_dome, y_axis, 0, 10 )
	Move( b_dome, y_axis, 0, 20 )

	Turn( lf_ball, y_axis, math.rad(45), sp1 )
	Turn( rf_ball, y_axis, math.rad(-45), sp1 )
	Turn( lb_ball, y_axis, math.rad(-45), sp1 )
	Turn( rb_ball, y_axis, math.rad(45), sp1 )
	
	Turn( lf_thigh, x_axis, 0, th_speed )
	Turn( rf_thigh, x_axis, 0, th_speed )
	Turn( lb_thigh, x_axis, 0, th_speed )
	Turn( rb_thigh, x_axis, 0, th_speed )
		
	Move( lf_shin, y_axis, 0, 10 )
	Move( rf_shin, y_axis, 0, 10 )
	Move( lb_shin, y_axis, 0, 10 )
	Move( rb_shin, y_axis, 0, 10 )
	
	Turn( t_dome, y_axis, 0, 1 )
	
	Turn( lf_shin, x_axis, 0, th_speed )
	Turn( rf_shin, x_axis, 0, th_speed )
	Turn( lb_shin, x_axis, 0, th_speed )
	Turn( rb_shin, x_axis, 0, th_speed )
	
	Turn( lf_pump, x_axis, 0, 1.4 )
	Turn( rf_pump, x_axis, 0, 1.4 )
	Turn( lb_pump, x_axis, 0, 1.4 )
	Turn( rb_pump, x_axis, 0, 1.4 )
		
	Turn( lf_foot, y_axis, 0, sp1 )
	Turn( rf_foot, y_axis, 0, sp1 )
	Turn( lb_foot, y_axis, 0, sp1 )
	Turn( rb_foot, y_axis, 0, sp1 )
	
	Turn( lf_foot, x_axis, 0, sp1 )
	Turn( rf_foot, x_axis, 0, sp1 )
	Turn( lb_foot, x_axis, 0, sp1 )
	Turn( rb_foot, x_axis, 0, sp1 )
end

function script.QueryWeapon1() return l_barrel end

function script.AimFromWeapon1() return l_turret end

function script.AimWeapon1( heading, pitch )
	Signal( aim )
	SetSignalMask( aim )
	Turn( l_turret, y_axis, heading, 5 )
	Turn( l_pivot,  x_axis, math.sin(heading) * .1/math.sin(pitch), 10 ) 
	-- if someone could make this better, please do :)
	return true
end

function script.FireWeapon1()
	--effects
end

function script.QueryWeapon2() return r_barrel end

function script.AimFromWeapon2() return r_turret end

function script.AimWeapon2( heading, pitch )
	Signal( aim )
	SetSignalMask( aim )
	Turn( r_turret, y_axis, heading, 5 )
	Turn( r_pivot,  x_axis, math.sin(heading) * -.1/math.sin(pitch), 10 )
	return true
end

function script.FireWeapon2()
	--effects
end

function script.Killed(recentDamage, maxHealth)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		Explode( t_eye, SFX.EXPLODE )
		Explode( b_eye, SFX.EXPLODE )
		return 1 -- corpsetype

	elseif (severity <= .5) then
		Explode( t_eye, SFX.EXPLODE )
		Explode( b_eye, SFX.EXPLODE )
		return 2 -- corpsetype

	else		
		Explode( t_dome, SFX.EXPLODE )
		Explode( t_eye, SFX.EXPLODE )
		Explode( b_eye, SFX.EXPLODE )
	
		Explode( lf_thigh, SFX.EXPLODE )
		Explode( lf_shin, SFX.EXPLODE )
		Explode( lf_foot, SFX.EXPLODE )
		
		Explode( rf_thigh, SFX.EXPLODE )
		Explode( rf_shin, SFX.EXPLODE )
		Explode( rf_foot, SFX.EXPLODE )
		
		Explode( lb_thigh, SFX.EXPLODE )
		Explode( lb_shin, SFX.EXPLODE )
		Explode( lb_foot, SFX.EXPLODE )
		
		Explode( rb_thigh, SFX.EXPLODE )
		Explode( rb_shin, SFX.EXPLODE )
		Explode( rb_foot, SFX.EXPLODE )
		return 3 -- corpsetype
	end
end
