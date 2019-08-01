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
local l_angle = math.rad(40)
local l_speed = 1
local k_angle = math.rad(45)
local k_speed = 10

local function hover()
	while(true) do
		Spin(glow, y_axis, 1)
		Move(glow, y_axis, math.random(1,5), 2)
		WaitForMove(glow, y_axis)
		Sleep (200)
		Move(glow, y_axis, math.random(-6,-1), 2)
	end
end

local function initialize()
	Move(lf_ball, y_axis, -10, 5)
	Move(rf_ball, y_axis, -10, 5)
	Move(lb_ball, y_axis, -10, 5)
	Move(rb_ball, y_axis, -10, 5)
	
	Turn(lf_knee, x_axis, -k_angle, k_speed)
	Turn(lf_knee, z_axis, k_angle, k_speed)
	Turn(lb_knee, x_axis, k_angle, k_speed)
	Turn(lb_knee, z_axis, k_angle, k_speed)
	Turn(rf_knee, x_axis, -k_angle, k_speed)
	Turn(rf_knee, z_axis, -k_angle, k_speed)
	Turn(rb_knee, x_axis, k_angle, k_speed)
	Turn(rb_knee, z_axis, -k_angle, k_speed)
	Sleep(100)
	
	StartThread(hover)
end
	
	
function script.Create()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1)	-- don't lose jitter effect with on/off button
	Turn(lf_leaf, x_axis, l_angle, l_speed)
	Turn(lf_leaf, z_axis, -l_angle, l_speed)
	
	Turn(rf_leaf, x_axis, l_angle, l_speed)
	Turn(rf_leaf, z_axis, l_angle, l_speed)
	
	Turn(lb_leaf, x_axis, -l_angle, l_speed)
	Turn(lb_leaf, z_axis, -l_angle, l_speed)
	
	Turn(rb_leaf, x_axis, -l_angle, l_speed)
	Turn(rb_leaf, z_axis, l_angle, l_speed)
	
	StartThread(GG.Script.SmokeUnit, {glow})
	StartThread(initialize)
end

function script.Activate()
	--Turn(lf_leaf, x_axis, l_angle, l_speed)
	--Turn(lf_leaf, z_axis, -l_angle, l_speed)
	--
	--Turn(rf_leaf, x_axis, l_angle, l_speed)
	--Turn(rf_leaf, z_axis, l_angle, l_speed)
	--
	--Turn(lb_leaf, x_axis, -l_angle, l_speed)
	--Turn(lb_leaf, z_axis, -l_angle, l_speed)
	--
	--Turn(rb_leaf, x_axis, -l_angle, l_speed)
	--Turn(rb_leaf, z_axis, l_angle, l_speed)
	
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 0, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, true)
end

function script.Deactivate()
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
