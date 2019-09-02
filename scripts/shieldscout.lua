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

-- signals
local SIG_Walk = 1
local SIG_AIM = 2
local SIG_RESTORE = 4

-- walk animation
local function Step(front, back)
	Turn(front.thigh, x_axis, math.rad(70), math.rad(230))
	Turn(front.calf, x_axis, math.rad(20), math.rad(270))
	Turn(front.foot, x_axis, math.rad(-100), math.rad(420))
	
	Turn(back.thigh, x_axis, math.rad(-20), math.rad(420))
	Turn(back.calf, x_axis, math.rad(50), math.rad(420))
	Turn(back.foot, x_axis, math.rad(30), math.rad(420))
	
	Turn(pelvis, z_axis, math.rad(-(5)), math.rad(40))
	Turn(front.thigh, z_axis, math.rad(-(-5)), math.rad(40))
	Turn(front.thigh, z_axis, math.rad(-(-5)), math.rad(40))
	Move(pelvis, y_axis, 0.7, 8000)
	
	WaitForTurn(front.thigh, x_axis)
	
	Turn(front.thigh, x_axis, math.rad(-10), math.rad(320))
	Turn(front.calf, x_axis, math.rad(-60), math.rad(500))
	Turn(front.foot, x_axis, math.rad(70), math.rad(270))
	
	Turn(back.thigh, x_axis, math.rad(40), math.rad(270))
	Turn(back.calf, x_axis, math.rad(-40), math.rad(270))
	Turn(back.foot, x_axis, 0, math.rad(270))
	
	Move(pelvis, y_axis, 0, 8000)
	Turn(box, x_axis, math.rad(10), math.rad(40))
	WaitForTurn(front.calf, x_axis)
	
	Turn(box, x_axis, math.rad(-10), math.rad(40))
end

local function Walk()
	Signal(SIG_Walk)
	SetSignalMask(SIG_Walk)
	
	while true do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
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
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
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
	
	local speed = 4*math.pi/(9/16*jumpDuration/1000)
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
		StartThread(somersaultThread, duration*GG.Script.frameToMs)
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
	
	Move(pelvis, y_axis, 0.000000, 1.000000)
	Turn(rightLeg.thigh, x_axis, 0, math.rad(200))
	Turn(rightLeg.calf, x_axis, 0, math.rad(200))
	Turn(rightLeg.foot, x_axis, 0, math.rad(200))
	Turn(leftLeg.thigh, x_axis, 0, math.rad(200))
	Turn(leftLeg.calf, x_axis, 0, math.rad(200))
	Turn(leftLeg.foot, x_axis, 0, math.rad(200))
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

function Detonate() -- Giving an order causes recursion.
	GG.QueueUnitDescruction(unitID)
end

function script.Killed(recentDamage, maxHealth)
	Explode(box, SFX.SHATTER + SFX.SMOKE)
	
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		return 1 -- corpsetype
	else
		return 2 -- corpsetype
	end
end
