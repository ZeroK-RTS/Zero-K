--by Chris Mackey

include "constants.lua"

local ALLY_ACCESS = {allied = true}

--pieces
local base = piece "base"
local glow = piece "glow"

local lf_leaf = piece "lf_leaf"
local lf_ball = piece "lf_ball"
local lf_thigh = piece "lf_thigh"
local lf_knee = piece "lf_knee"
local lf_foot = piece "lf_foot"

local lb_leaf = piece "lb_leaf"
local lb_ball = piece "lb_ball"
local lb_thigh = piece "lb_thigh"
local lb_knee = piece "lb_knee"
local lb_foot = piece "lb_foot"

local rf_leaf = piece "rf_leaf"
local rf_ball = piece "rf_ball"
local rf_thigh = piece "rf_thigh"
local rf_knee = piece "rf_knee"
local rf_foot = piece "rf_foot"

local rb_leaf = piece "rb_leaf"
local rb_ball = piece "rb_ball"
local rb_thigh = piece "rb_thigh"
local rb_knee = piece "rb_knee"
local rb_foot = piece "rb_foot"

--constants
local sp1 = 2.8
local sp2 = 2.5
local deg = math.rad(-30)
local sleep = 250

local lf_angle = deg
local rf_angle = deg
local lb_angle = deg
local rb_angle = deg

local l_angle = math.rad(40)
local l_speed = math.rad(8)
local k_angle = math.rad(25)
local k_speed = 2

--signals
local walk = 2
local aim = 4
local SIG_Flutter = 1

local function Walk()
	Signal(walk)
	SetSignalMask(walk)
	while (true) do
		Turn(base, y_axis, -.2, .5)
		Move(base, y_axis, 2, 5)
		
		Turn(lf_ball, y_axis, lf_angle, sp1) -- left front leg forward
		Turn(lb_ball, y_axis, -lf_angle, sp2) -- left back leg backward
		Turn(rf_ball, y_axis, rf_angle, sp1) -- right front leg forward
		Turn(rb_ball, y_axis, -rf_angle, sp2) -- right back leg backward
		
		Turn(lf_knee, x_axis, -k_angle, k_speed) -- extend
		Turn(lf_knee, z_axis, k_angle, k_speed)
		
		Turn(lb_knee, x_axis, k_angle, k_speed) -- extend
		Turn(lb_knee, z_axis, k_angle, k_speed)
		
		Turn(rf_knee, x_axis, 0, k_speed) -- contract
		Turn(rf_knee, z_axis, 0, k_speed)
		
		Turn(rb_knee, x_axis, 0, k_speed) -- contract
		Turn(rb_knee, z_axis, 0, k_speed)
		
		Sleep(sleep)
		--------------------------------------------------------------------
		Move(base, y_axis, -2, 4)
		
		
		Sleep(sleep)
		--------------------------------------------------------------------
		Turn(base, y_axis, .2, .5)
		Move(base, y_axis, 2, 5)
		
		Turn(lf_ball, y_axis, -lb_angle, sp2) -- left front leg backward
		Turn(lb_ball, y_axis, lb_angle, sp1) -- left front leg forward
		Turn(rf_ball, y_axis, -rb_angle, sp2) -- right front leg backward
		Turn(rb_ball, y_axis, rb_angle, sp1) -- right back leg forward
		
		Turn(lf_knee, x_axis, 0, k_speed) -- contract
		Turn(lf_knee, z_axis, 0, k_speed)
		
		Turn(lb_knee, x_axis, 0, k_speed) -- contract
		Turn(lb_knee, z_axis, 0, k_speed)
		
		Turn(rf_knee, x_axis, -k_angle, k_speed) -- extend
		Turn(rf_knee, z_axis, -k_angle, k_speed)
		
		Turn(rb_knee, x_axis, k_angle, k_speed) -- extend
		Turn(rb_knee, z_axis, -k_angle, k_speed)
		
		Sleep(sleep)
		--------------------------------------------------------------------
		Move(base, y_axis, -2, 4)
		
		
		Sleep(sleep)
		--------------------------------------------------------------------
	end
end

local function Flutter()
	Signal(SIG_Flutter)
	SetSignalMask(SIG_Flutter)
	Sleep(2000)
	while true do
		Turn(lf_leaf, x_axis, l_angle, l_speed)
		Turn(lf_leaf, z_axis, -l_angle, l_speed)
		Turn(rf_leaf, x_axis, l_angle, l_speed)
		Turn(rf_leaf, z_axis, l_angle, l_speed)
		Turn(lb_leaf, x_axis, -l_angle, l_speed)
		Turn(lb_leaf, z_axis, -l_angle, l_speed)
		Turn(rb_leaf, x_axis, -l_angle, l_speed)
		Turn(rb_leaf, z_axis, l_angle, l_speed)
		WaitForTurn(lf_leaf, x_axis)
		WaitForTurn(lf_leaf, z_axis)
		Sleep(1200)
		Turn(lf_leaf, x_axis, l_angle*0.6, l_speed)
		Turn(lf_leaf, z_axis, -l_angle*0.6, l_speed)
		Turn(rf_leaf, x_axis, l_angle*0.6, l_speed)
		Turn(rf_leaf, z_axis, l_angle*0.6, l_speed)
		Turn(lb_leaf, x_axis, -l_angle*0.6, l_speed)
		Turn(lb_leaf, z_axis, -l_angle*0.6, l_speed)
		Turn(rb_leaf, x_axis, -l_angle*0.6, l_speed)
		Turn(rb_leaf, z_axis, l_angle*0.6, l_speed)
		WaitForTurn(lf_leaf, x_axis)
		WaitForTurn(lf_leaf, z_axis)
		Sleep(1200)
	end
end

function script.Create()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1)	-- don't lose jitter effect with on/off button
	Turn(lf_leaf, x_axis, l_angle, 1)
	Turn(lf_leaf, z_axis, -l_angle, 1)
	Turn(rf_leaf, x_axis, l_angle, 1)
	Turn(rf_leaf, z_axis, l_angle, 1)
	Turn(lb_leaf, x_axis, -l_angle, 1)
	Turn(lb_leaf, z_axis, -l_angle, 1)
	Turn(rb_leaf, x_axis, -l_angle, 1)
	Turn(rb_leaf, z_axis, l_angle, 1)

	StartThread(GG.Script.SmokeUnit, {glow})
	StartThread(Flutter)
end

function script.Activate()
	--Turn(lf_leaf, x_axis, l_angle, 1)
	--Turn(lf_leaf, z_axis, -l_angle, 1)
	--Turn(rf_leaf, x_axis, l_angle, 1)
	--Turn(rf_leaf, z_axis, l_angle, 1)
	--Turn(lb_leaf, x_axis, -l_angle, 1)
	--Turn(lb_leaf, z_axis, -l_angle, 1)
	--Turn(rb_leaf, x_axis, -l_angle, 1)
	--Turn(rb_leaf, z_axis, l_angle, 1)
	--StartThread(Flutter)
	
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 0, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, true)
end

function script.Deactivate()
	--Signal(SIG_Flutter)
	--Turn(lf_leaf, x_axis, 0, 1)
	--Turn(lf_leaf, z_axis, 0, 1)
	--
	--Turn(rf_leaf, x_axis, 0, 1)
	--Turn(rf_leaf, z_axis, 0, 1)
	--
	--Turn(lb_leaf, x_axis, 0, 1)
	--Turn(lb_leaf, z_axis, 0, 1)
	--
	--Turn(rb_leaf, x_axis, 0, 1)
	--Turn(rb_leaf, z_axis, 0, 1)
	
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 1, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, false)
end

local function Stopping()
	Signal(walk)
	SetSignalMask(walk)
	--Spin(glow, y_axis, 1)
	Move(base, y_axis, 0, 15)
	Turn(base, y_axis, 0, 1)
	
	Turn(lf_ball, y_axis, 0, 1)
	Turn(rf_ball, y_axis, 0, 1)
	Turn(lb_ball, y_axis, 0, 1)
	Turn(rb_ball, y_axis, 0, 1)
		
	Turn(lf_knee, x_axis, 0, 1)
	Turn(lf_knee, z_axis, 0, 1)
	Turn(rf_knee, x_axis, 0, 1)
	Turn(rf_knee, z_axis, 0, 1)
	Turn(lb_knee, x_axis, 0, 1)
	Turn(lb_knee, z_axis, 0, 1)
	Turn(rb_knee, x_axis, 0, 1)
	Turn(rb_knee, z_axis, 0, 1)
end

function script.StartMoving()
	--StopSpin(glow, y_axis)
	--Turn(glow, y_axis, 0, 1)
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

function script.Killed(recentDamage, maxHealth)
	Explode(base, SFX.EXPLODE)
	
	Explode(lf_leaf, SFX.EXPLODE)
	Explode(rf_leaf, SFX.EXPLODE)
	Explode(lb_leaf, SFX.EXPLODE)
	Explode(rb_leaf, SFX.EXPLODE)
	
	Explode(lf_foot, SFX.EXPLODE)
	Explode(rf_foot, SFX.EXPLODE)
	Explode(lb_foot, SFX.EXPLODE)
	Explode(rb_foot, SFX.EXPLODE)
	
	Explode(lf_ball, SFX.EXPLODE)
	Explode(rf_ball, SFX.EXPLODE)
	Explode(lb_ball, SFX.EXPLODE)
	Explode(rb_ball, SFX.EXPLODE)

	local severity = recentDamage / maxHealth

	if (severity <= .25) then
		return 1 -- corpsetype
	elseif (severity <= .5) then
		return 1 -- corpsetype
	else		
		return 2 -- corpsetype
	end
end
