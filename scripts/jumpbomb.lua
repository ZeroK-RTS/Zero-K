local base = piece 'base'
local Left_Back_Leg = piece 'left_back_leg'
local Left_Back_Foot = piece 'left_back_foot'
local Right_Back_Leg = piece 'right_back_leg'
local Right_Back_Foot = piece 'right_back_foot'
local Left_Front_Leg = piece 'left_front_leg'
local Left_Front_Foot = piece 'left_front_foot'
local Right_Front_Leg = piece 'right_front_leg'
local Right_Front_Foot = piece 'right_front_foot'
local Hump = piece 'hump'
local Tail = piece 'tail'

include "constants.lua"

local smokePiece = { Hump }

local moving = false
local SIG_MOVE = 1

local spGetUnitRulesParam = Spring.GetUnitRulesParam

local pi6 = math.rad(30)
local pi3 = math.rad(60)
local pi18 = math.rad(10)
local pi12 = math.rad(15)

local function WalkThread ()
	SetSignalMask (SIG_MOVE)
	while true do

		local slow_mult = (Spring.GetUnitRulesParam(unitID,"baseSpeedMult") or 1)
		local anim_speed = math.rad(150) * slow_mult

		Turn (Left_Back_Leg, y_axis, pi6, anim_speed)
		Turn (Right_Back_Leg, y_axis, pi6, anim_speed)
		Turn (Left_Front_Leg, y_axis, -pi6, anim_speed)
		Turn (Right_Front_Leg, y_axis, -pi6, anim_speed)
		Turn (Tail, y_axis, pi18, anim_speed / 3)
		Sleep (400 / slow_mult)

		Turn (Left_Back_Leg, y_axis, -pi6, anim_speed)
		Turn (Right_Back_Leg, y_axis, -pi6, anim_speed)
		Turn (Left_Front_Leg, y_axis, pi6, anim_speed)
		Turn (Right_Front_Leg, y_axis, pi6, anim_speed)
		Turn (Tail, y_axis, pi18, anim_speed / 3)
		Sleep (400 / slow_mult)
	end
end

function script.StartMoving()
	if not moving then
		moving = true
		StartThread (WalkThread)
	end
end

function script.StopMoving()
	Signal (SIG_MOVE)
	moving = false

	Turn (Left_Back_Leg, y_axis, 0, pi3)
	Turn (Right_Back_Leg, y_axis, 0, pi3)
	Turn (Left_Front_Leg, y_axis, 0, pi3)
	Turn (Right_Front_Leg, y_axis, 0, pi3)
	Turn (Tail, y_axis, 0, math.rad(20))
end

function beginJump ()
	Turn (base, x_axis, math.rad(-40), pi3)
	Turn (Left_Back_Leg, y_axis, -pi6, pi3)
	Turn (Right_Back_Leg, y_axis, pi6, pi3)
	Turn (Left_Front_Leg, y_axis, -pi6, pi3)
	Turn (Right_Front_Leg, y_axis, pi6, pi3)

	Turn (Left_Back_Leg, z_axis, -pi12, pi3)
	Turn (Right_Back_Leg, z_axis, pi12, pi3)
	Turn (Left_Front_Leg, z_axis, -pi12, pi3)
	Turn (Right_Front_Leg, z_axis, pi12, pi3)
end

function halfJump ()
	Turn (base, x_axis, 0, pi3)
	Turn (Left_Back_Leg, z_axis, 0, pi3)
	Turn (Right_Back_Leg, z_axis, 0, pi3)
	Turn (Left_Front_Leg, z_axis, 0, pi3)
	Turn (Right_Front_Leg, z_axis, 0, pi3)
end

function endJump ()
	Turn (Left_Back_Leg, y_axis, 0, pi3)
	Turn (Right_Back_Leg, y_axis, 0, pi3)
	Turn (Left_Front_Leg, y_axis, 0, pi3)
	Turn (Right_Front_Leg, y_axis, 0, pi3)
end

function preJump () end
function jumping() end

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Create ()
	StartThread (GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Killed(recentDamage, maxHealth)

	Explode (Tail, SFX.SMOKE + SFX.FIRE)
	Explode (Left_Back_Leg, SFX.SMOKE + SFX.FIRE)
	Explode (Left_Back_Foot, SFX.SMOKE + SFX.FIRE)
	Explode (Right_Back_Leg, SFX.SMOKE + SFX.FIRE)
	Explode (Right_Back_Foot, SFX.SMOKE + SFX.FIRE)
	Explode (Left_Front_Leg, SFX.SMOKE + SFX.FIRE)
	Explode (Left_Front_Foot, SFX.SMOKE + SFX.FIRE)
	Explode (Right_Front_Foot, SFX.SMOKE + SFX.FIRE)
	Explode (Right_Front_Leg, SFX.SMOKE + SFX.FIRE)

	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1
	else
		return 2
	end
end
