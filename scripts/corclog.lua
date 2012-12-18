include 'constants.lua'

local pelvis = piece 'pelvis'
local lthigh, lcalf, lfoot = piece('lthigh', 'lcalf', 'lfoot')
local rthigh, rcalf, rfoot = piece('rthigh', 'rcalf', 'rfoot')
local leftLeg = { thigh=piece'lthigh', calf=piece'lcalf', foot=piece'lfoot'}
local rightLeg = { thigh=piece'rthigh', calf=piece'rcalf', foot=piece'rfoot'}
local base = piece 'base' 
local box = piece 'box'

local smokePiece = { box }

-- signals
local SIG_Walk = 1

-- walk animation
local function Step(front, back)
	Turn( front.thigh , x_axis, math.rad(70), math.rad(230) )
	Turn( front.calf , x_axis, math.rad(20), math.rad(270) )
	Turn( front.foot , x_axis, math.rad(-100), math.rad(420) )
	
	Turn( back.thigh , x_axis, math.rad(-20), math.rad(420) )
	Turn( back.calf , x_axis, math.rad(50), math.rad(420) )
	Turn( back.foot , x_axis, math.rad(30), math.rad(420) )
	
	Turn( pelvis , z_axis, math.rad(-(5)), math.rad(40) )
	Turn( front.thigh , z_axis, math.rad(-(-5)), math.rad(40) )
	Turn( front.thigh , z_axis, math.rad(-(-5)), math.rad(40) )
	Move( pelvis , y_axis, 0.7 , 8000 )
	
	WaitForTurn(front.thigh, x_axis)
	
	Turn( front.thigh , x_axis, math.rad(-10), math.rad(320) )
	Turn( front.calf , x_axis, math.rad(-60), math.rad(500) )
	Turn( front.foot , x_axis, math.rad(70), math.rad(270) )
	
	Turn( back.thigh , x_axis, math.rad(40), math.rad(270) )
	Turn( back.calf , x_axis, math.rad(-40), math.rad(270) )
	Turn( back.foot , x_axis, 0, math.rad(270) )
	
	Move( pelvis , y_axis, 0, 8000 )
	Turn( box , x_axis, math.rad(10), math.rad(40) )
	WaitForTurn(front.calf, x_axis)
	
	Turn( box , x_axis, math.rad(-10), math.rad(40) )
end

local function Walk()
	Signal( SIG_Walk )
	SetSignalMask( SIG_Walk )
	
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
	StartThread(SmokeUnit)
	--StartThread(SpinScienceThread)
end

-- jump functions
local doingSomersault = false

local function jumpTuckInLegs(leg)
	Turn( leg.thigh , x_axis, math.rad(-120), math.rad(100) )
	Turn( leg.calf , x_axis, math.rad(-10), math.rad(100) )
	Turn( leg.foot , x_axis, math.rad(-20), math.rad(100) )
end

local function jumpUnTuckLegs(leg)
	Turn( leg.thigh , x_axis, math.rad(0), math.rad(200) )
	Turn( leg.calf , x_axis, math.rad(0), math.rad(200) )
	Turn( leg.foot , x_axis, math.rad(0), math.rad(200) )
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
	Signal( SIG_Walk )
	Turn( leg.thigh , x_axis, math.rad(0))
	Turn( leg.calf , x_axis, math.rad(0))
	Turn( leg.foot , x_axis, math.rad(-40))
	
	Turn( leg.thigh , x_axis, math.rad(-30), math.rad(100) )
	Turn( leg.calf , x_axis, math.rad(60), math.rad(500) )
	Turn( leg.foot , x_axis, math.rad(-10), math.rad(600) )
end

local function jumpLegLand(leg)
	Turn( leg.thigh , x_axis, math.rad(0), math.rad(100) )
	Turn( leg.calf , x_axis, math.rad(-30), math.rad(300) )
	Turn( leg.foot , x_axis, math.rad(10), math.rad(100) )
end

function beginJump(turn,lineDist,flightDist,duration)
	Turn( box , x_axis, math.rad(20) )
	jumpLegLaunch(leftLeg)
	jumpLegLaunch(rightLeg)
	Turn( box , x_axis, math.rad(0), math.rad(150) )
	
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
	Spring.UnitScript.StopSpin(pelvis , x_axis)
	Turn(box, x_axis, math.rad(40),math.rad(400))
	Move(pelvis, y_axis, -8, 80)
	jumpLegLand(leftLeg)
	jumpLegLand(rightLeg)
end

-- the usual things
local function RestoreAfterDelay()
	Sleep(2750)
	Turn( box , y_axis, 0, math.rad(90.021978) )
end

function script.StartMoving()
	StartThread(Walk)
end

function script.StopMoving()
	Signal( SIG_Walk )
	Move( pelvis , y_axis, 0.000000 , 1.000000 )
	for i,v in pairs(rightLeg) do
		Turn( rightLeg[i], x_axis, 0, math.rad(200.000000) )
	end
	for i,v in pairs(leftLeg) do
		Turn( leftLeg[i], x_axis, 0, math.rad(200.000000) )
	end
end

function script.Killed(recentDamage, maxHealth)
    Explode(box, sfxShatter + sfxSmoke)
    return 4 --leave no wreckage
end
