include 'constants.lua'
include "JumpRetreat.lua"

local pelvis = piece 'pelvis'
local pole = piece 'pole'
local aimpitch = piece 'aimpitch'
local aimyaw = piece 'aimyaw'
local lthigh, lcalf, lfoot = piece('lthigh', 'lcalf', 'lfoot')
local rthigh, rcalf, rfoot = piece('rthigh', 'rcalf', 'rfoot')
local leftLeg = { thigh = piece'lthigh', calf = piece'lcalf', foot = piece'lfoot'}
local rightLeg = { thigh = piece'rthigh', calf = piece'rcalf', foot = piece'rfoot'}
local base = piece 'base' 
local box = piece 'box'

local smokePiece = { box }

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- walk anim constants
local PACE = 3

local THIGH_FRONT_ANGLE = math.rad(-50)
local THIGH_FRONT_SPEED = math.rad(60) * PACE
local THIGH_BACK_ANGLE = math.rad(10)
local THIGH_BACK_SPEED = math.rad(60) * PACE
local CALF_RETRACT_ANGLE = math.rad(0)
local CALF_RETRACT_SPEED = math.rad(90) * PACE
local CALF_STRAIGHTEN_ANGLE = math.rad(70)
local CALF_STRAIGHTEN_SPEED = math.rad(90) * PACE
local FOOT_FRONT_ANGLE = -THIGH_FRONT_ANGLE - math.rad(10)
local FOOT_FRONT_SPEED = 2*THIGH_FRONT_SPEED
local FOOT_BACK_ANGLE = -(THIGH_BACK_ANGLE + CALF_STRAIGHTEN_ANGLE)
local FOOT_BACK_SPEED = THIGH_BACK_SPEED + CALF_STRAIGHTEN_SPEED
local BODY_TILT_ANGLE = math.rad(5)
local BODY_TILT_SPEED = math.rad(10)
local BODY_RISE_HEIGHT = 4
local BODY_RISE_SPEED = 6*PACE

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- signals
local SIG_Walk = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- four-stroke bipedal (reverse-jointed) walkscript
local function WalkAnim()
	local speed = 1 - (Spring.GetUnitRulesParam(unitID,"slowState") or 0)
	--straighten left leg and draw it back, raise body, center right leg
	Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
	Turn(pelvis, z_axis, BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
	Turn(lthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
	Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
	Turn(lfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
	Turn(rthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
	Turn(rcalf, x_axis, 0, CALF_RETRACT_SPEED*speed)
	Turn(rfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)
	WaitForTurn(lthigh, x_axis)
	Sleep(0)
	
	-- lower body, draw right leg forwards
	Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
	Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
	--Turn(lcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
	Turn(rthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
	Turn(rfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)	
	WaitForMove(pelvis, y_axis)
	Sleep(0)
	
	--straighten right leg and draw it back, raise body, center left leg
	Move(pelvis, y_axis, BODY_RISE_HEIGHT, BODY_RISE_SPEED*speed)
	Turn(pelvis, z_axis, -BODY_TILT_ANGLE, BODY_TILT_SPEED*speed)
	Turn(lthigh, x_axis, 0, THIGH_FRONT_SPEED*speed)
	Turn(lcalf, x_axis, 0, CALF_RETRACT_SPEED*speed)
	Turn(lfoot, x_axis, 0, FOOT_FRONT_SPEED*speed)		
	Turn(rthigh, x_axis, THIGH_BACK_ANGLE, THIGH_BACK_SPEED*speed)
	Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED*speed)
	Turn(rfoot, x_axis, FOOT_BACK_ANGLE, FOOT_BACK_SPEED*speed)		
	WaitForTurn(rthigh, x_axis)
	Sleep(0)
	
	-- lower body, draw left leg forwards
	Move(pelvis, y_axis, 0, BODY_RISE_SPEED*speed)
	Turn(pelvis, z_axis, 0, BODY_TILT_SPEED*speed)
	Turn(lthigh, x_axis, THIGH_FRONT_ANGLE, THIGH_FRONT_SPEED*speed)
	Turn(lfoot, x_axis, FOOT_FRONT_ANGLE, FOOT_FRONT_SPEED*speed)			
	--Turn(rcalf, x_axis, CALF_STRAIGHTEN_ANGLE, CALF_STRAIGHTEN_SPEED)
	WaitForMove(pelvis, y_axis)
	Sleep(0)
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while true do
		WalkAnim()
	end
end

--[[ messy but does tell you how spin works
local function SpinScienceThread()
	local startSpinTime = Spring.GetGameFrame()
	
	local startFrame = Spring.GetGameFrame()
	Turn(pelvis, y_axis, 0)
	Spin(pelvis, y_axis, math.rad(1000000), math.rad(1))
	
	while true do
		Sleep(30)
		local frame = Spring.GetGameFrame()
		--Spring.Echo(frame - startFrame)
		local x,y,z = Spring.UnitScript.GetPieceRotation(pelvis)
		Spring.Echo(y)
	end
end
--]]

function script.Create()
	StartThread(SmokeUnit, smokePiece)
	--StartThread(SpinScienceThread)
end

-----------------------------
-- Jumping

local doingSomersault = false

local function jumpTuckInLegs(leg)
	Turn(leg.thigh, x_axis, math.rad(-120), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(-10), math.rad(100))
	Turn(leg.foot, x_axis, math.rad(-20), math.rad(100))
end

local function jumpUnTuckLegs(leg)
	Turn(leg.thigh, x_axis, math.rad(0), math.rad(200))
	Turn(leg.calf, x_axis, math.rad(0), math.rad(200))
	Turn(leg.foot, x_axis, math.rad(0), math.rad(200))
end

local function somersaultThread(jumpDuration)
	Turn(pelvis, x_axis, math.rad(0))
	Sleep(jumpDuration/4)

	jumpTuckInLegs(leftLeg)
	jumpTuckInLegs(rightLeg)
	
	local speed = 4*pi/(9/16*jumpDuration/1000)
	local accel = speed*(16/6)/(jumpDuration/1000)/30
	
	Spin(pelvis, x_axis, speed, accel)
	
	Sleep(jumpDuration/2)
	
	jumpUnTuckLegs(leftLeg)
	jumpUnTuckLegs(rightLeg)
end

local function jumpLegLaunch(leg)
	Signal(SIG_Walk)
	Turn(leg.thigh, x_axis, math.rad(0))
	Turn(leg.calf, x_axis, math.rad(0))
	Turn(leg.foot, x_axis, math.rad(-40))
	
	Turn(leg.thigh, x_axis, math.rad(-30), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(60), math.rad(500))
	Turn(leg.foot, x_axis, math.rad(-10), math.rad(600))
end

local function jumpLegLand(leg)
	Turn(leg.thigh, x_axis, math.rad(0), math.rad(100))
	Turn(leg.calf, x_axis, math.rad(-30), math.rad(300))
	Turn(leg.foot, x_axis, math.rad(10), math.rad(100))
end

function beginJump(turn,lineDist,flightDist,duration)
	Turn(box, x_axis, math.rad(20))
	jumpLegLaunch(leftLeg)
	jumpLegLaunch(rightLeg)
	Turn(box, x_axis, math.rad(0), math.rad(150))
	
	doingSomersault = math.random() < 0.15
	
	if doingSomersault then
		StartThread(somersaultThread, duration*frameToMs)
	end
end

function jumping()
end

function halfJump()
	if not doingSomersault then
		script.StopMoving()
	end
end

function endJump()
	Spring.UnitScript.StopSpin(pelvis, x_axis)
	Turn(pelvis, x_axis, math.rad(0))
	Turn(box, x_axis, math.rad(40),math.rad(400))
	Move(pelvis, y_axis, -8, 80)
	jumpLegLand(leftLeg)
	jumpLegLand(rightLeg)
end

-----------------------------
-- Walking

local function Stopping()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	Turn(rthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(rcalf, x_axis, 0, math.rad(120)*PACE)
	Turn(rfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(lthigh, x_axis, 0, math.rad(80)*PACE)
	Turn(lcalf, x_axis, 0, math.rad(80)*PACE)
	Turn(lfoot, x_axis, 0, math.rad(80)*PACE)
	Turn(pelvis, z_axis, 0, math.rad(20)*PACE)
	Move(pelvis, y_axis, 0, 12*PACE)
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	StartThread(Stopping)
end

-----------------------------
-- Weapon

function script.AimFromWeapon()
	return pelvis
end

function script.QueryWeapon()
	return pelvis
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(1000)
	Turn(aimyaw, y_axis, 0, math.rad(135))
	Turn(aimpitch, x_axis, 0, math.rad(85))
end

function script.AimWeapon(num, heading, pitch)
	
	StartThread(RestoreAfterDelay)
	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	Turn(aimyaw, y_axis, heading, math.rad(360)) -- left-right
	Turn(aimpitch, x_axis, -pitch, math.rad(270)) --up-down
	WaitForTurn(aimyaw, y_axis)
	WaitForTurn(aimpitch, x_axis)
	gunHeading = heading
	return true
end

function script.FireWeapon(num)
	Turn(pole, x_axis, math.rad(90), math.rad(40000))
	Turn(box, x_axis, -math.rad(50), math.rad(40000))
	Move(box, y_axis, 15, 300)
	Sleep(30)
	Turn(pole, x_axis, math.rad(0), math.rad(80))
	Turn(box, x_axis, math.rad(0), math.rad(40))
	Move(box, y_axis, 0, 10)
end


-----------------------------
-- Death

function script.Killed(recentDamage, maxHealth)
	Explode(box, sfxShatter + sfxSmoke)
	
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
