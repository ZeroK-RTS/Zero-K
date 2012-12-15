include 'constants.lua'

local pelvis = piece 'pelvis'
local leftLeg = { thigh=piece'lthigh', calf=piece'lcalf', foot=piece'lfoot' }
local rightLeg = { thigh=piece'rthigh', calf=piece'rcalf', foot=piece'rfoot' }
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
	Turn( box , x_axis, math.rad(-10), math.rad(40) )
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
end

local function Walk()
	Signal( SIG_Walk )
	SetSignalMask( SIG_Walk )
	
	while true do
		Step(leftLeg, rightLeg)
		Step(rightLeg, leftLeg)
	end
end

function script.Create()
	StartThread(SmokeUnit)
end

-- jump functions
function preJump(turn,distance)
end

function beginJump()
	script.StartMoving()
end

function jumping()
end

function halfJump()
end

function endJump()
	script.StopMoving()
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
