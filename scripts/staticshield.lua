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

local function hover()
	local spGetUnitShieldState = Spring.GetUnitShieldState
	while true do
		local shieldEnabled, shieldHealth = spGetUnitShieldState(unitID)
		Spin(glow, y_axis, shieldEnabled and (shieldHealth / 3000) or 0)
		Move(glow, y_axis, math.random(11,15), 2)
		WaitForMove(glow, y_axis)
		Sleep (200)
		Move(glow, y_axis, math.random(4,9), 2)
		WaitForMove(glow, y_axis)
		Sleep (200)
	end
end

local function initialize()
	local spGetUnitHealth = Spring.GetUnitHealth
	local sel = select
	while sel(5, spGetUnitHealth(unitID)) < 1 do
		Sleep(100)
	end

	Move(glow, y_axis, 10, 4)
	Sleep(500)

	-- FIXME: rotations don't stack sensibly, needs the solar cardinal rotation hax
	Turn(lf_leaf, x_axis, math.rad( 40), math.rad(15))
	Turn(lf_leaf, z_axis, math.rad(-40), math.rad(15))
	Turn(rf_leaf, x_axis, math.rad( 40), math.rad(15))
	Turn(rf_leaf, z_axis, math.rad( 40), math.rad(15))
	Turn(lb_leaf, x_axis, math.rad(-40), math.rad(15))
	Turn(lb_leaf, z_axis, math.rad(-40), math.rad(15))
	Turn(rb_leaf, x_axis, math.rad(-40), math.rad(15))
	Turn(rb_leaf, z_axis, math.rad( 40), math.rad(15))

	WaitForMove(glow, y_axis)
	WaitForTurn(lf_leaf, x_axis)
	StartThread(hover)
end

function script.Create()
	Spring.SetUnitRulesParam(unitID, "unitActiveOverride", 1)	-- don't lose jitter effect with on/off button

	-- FIXME: these should be reflected in the model (building ghost mismatch)
	Move(base, y_axis, -8)
	Turn(lf_knee, x_axis, math.rad(-45))
	Turn(lf_knee, z_axis, math.rad( 45))
	Turn(lb_knee, x_axis, math.rad( 45))
	Turn(lb_knee, z_axis, math.rad( 45))
	Turn(rf_knee, x_axis, math.rad(-45))
	Turn(rf_knee, z_axis, math.rad(-45))
	Turn(rb_knee, x_axis, math.rad( 45))
	Turn(rb_knee, z_axis, math.rad(-45))

	StartThread(GG.Script.SmokeUnit, unitID, {glow})
	StartThread(initialize)
end

function script.Activate()
	Spring.SetUnitRulesParam(unitID, "shieldChargeDisabled", 0, ALLY_ACCESS)
	--spSetUnitShieldState(unitID, 1, true)
end

function script.Deactivate()
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
