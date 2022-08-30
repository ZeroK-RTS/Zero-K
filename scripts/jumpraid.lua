local base = piece 'base'
local low_head = piece 'low_head'
local up_head = piece 'up_head'
local tank = piece 'tank'
local firept = piece 'firept'
local l_leg = piece 'l_leg'
local l_shin = piece 'l_shin'
local l_foot = piece 'l_foot'
local l_pist1 = piece 'l_pist1'
local l_pist2 = piece 'l_pist2'
local l_jetpt = piece 'l_jetpt'
local r_leg = piece 'r_leg'
local r_shin = piece 'r_shin'
local r_foot = piece 'r_foot'
local r_pist1 = piece 'r_pist1'
local r_pist2 = piece 'r_pist2'
local r_jetpt = piece 'r_jetpt'
--by Chris Mackey
--linear constant 163840

include "constants.lua"
include "JumpRetreat.lua"

local smokePiece = {base}

local landing = false
local firing = false

local LINEAR_SPEED = 10
local ANGULAR_SPEED = math.rad(160)

local SIG_MOVE = 2
local SIG_AIM = 4

-- JUMPING

local function BeginJumpThread()
	Signal(SIG_MOVE)
	
	--crouch and prepare to jump
	Turn(l_leg, x_axis, 0, ANGULAR_SPEED*6)
	Turn(l_foot, x_axis, math.rad(30), ANGULAR_SPEED*4)
	
	Turn(r_leg, x_axis, 0, ANGULAR_SPEED*6)
	Turn(r_foot, x_axis, math.rad(30), ANGULAR_SPEED*4)
	
	Move(base, y_axis, -3, LINEAR_SPEED*4)
	WaitForTurn(l_leg, x_axis)
	--spring off with lower legs
	Move(base, y_axis, 3, LINEAR_SPEED*4)
	Move(l_shin, y_axis, -2, LINEAR_SPEED*8)
	Move(r_shin, y_axis, -2, LINEAR_SPEED*8)
	--begin rocket boost
	EmitSfx(l_jetpt, 1027)
	EmitSfx(r_jetpt, 1027)
	--small adjustments in flight
	Sleep(600)
	
	--move to neutral
	Move(base, y_axis, 0, LINEAR_SPEED)
	Move(base, z_axis, -4, LINEAR_SPEED)
	Move(l_shin, y_axis, 0, LINEAR_SPEED/2)
	Move(r_shin, y_axis, 0, LINEAR_SPEED/2)
	
	--wiggle legs in glee
	Turn(l_leg, x_axis, math.rad(-20), ANGULAR_SPEED)
	Turn(r_leg, x_axis, math.rad(-50), ANGULAR_SPEED)
	WaitForTurn(r_leg, x_axis)
	Turn(l_leg, x_axis, math.rad(-60), ANGULAR_SPEED)
	Turn(r_leg, x_axis, math.rad(-10), ANGULAR_SPEED)
	WaitForTurn(l_leg, x_axis)
	Turn(l_leg, x_axis, math.rad(-10), ANGULAR_SPEED)
	Turn(r_leg, x_axis, math.rad(-70), ANGULAR_SPEED)
	WaitForTurn(l_leg, x_axis)
	Turn(l_leg, x_axis, math.rad(-50), ANGULAR_SPEED)
	Turn(r_leg, x_axis, math.rad(-20), ANGULAR_SPEED)
	WaitForTurn(r_leg, x_axis)
	
	--move legs to landing position
	Turn(l_leg, x_axis, math.rad(-40), ANGULAR_SPEED/2)
	Turn(l_foot, x_axis, math.rad(30), ANGULAR_SPEED)
	Turn(r_leg, x_axis, math.rad(-40), ANGULAR_SPEED/2)
	Turn(r_foot, x_axis, math.rad(30), ANGULAR_SPEED)
	WaitForMove(r_shin, y_axis)
	Move(l_shin, y_axis, -1, LINEAR_SPEED/2)
	Move(r_shin, y_axis, -1, LINEAR_SPEED/2)
end

local function PrepareJumpLand()
	Sleep(100)
	Turn(low_head, x_axis, math.rad(50), ANGULAR_SPEED*2.5)
	Move(base, y_axis, -2, LINEAR_SPEED*2)
	Turn(base, x_axis, math.rad(10), ANGULAR_SPEED)
	
	Move(l_shin, y_axis, 2, LINEAR_SPEED*2)
	Turn(l_leg, x_axis, math.rad(-15), ANGULAR_SPEED)
	Turn(l_foot, x_axis, math.rad(15), ANGULAR_SPEED)
	
	Move(r_shin, y_axis, 2, LINEAR_SPEED*2)
	Turn(r_leg, x_axis, math.rad(-15), ANGULAR_SPEED)
	Turn(r_foot, x_axis, math.rad(15), ANGULAR_SPEED)
	
	WaitForTurn(low_head, x_axis)
	Turn(low_head, x_axis, 0, ANGULAR_SPEED)
	Turn(base, x_axis, 0, ANGULAR_SPEED)
	WaitForMove(r_shin, y_axis)
	Move(base, y_axis, 0, LINEAR_SPEED)
	Move(l_shin, y_axis, 0, LINEAR_SPEED)
	Move(r_shin, y_axis, 0, LINEAR_SPEED)
end

local function EndJumpThread()
	EmitSfx(l_foot, 1027)
	EmitSfx(r_foot, 1027)
	
	--stumble forward
	Move(base, z_axis, 0, LINEAR_SPEED*1.8)
	
	Turn(l_leg, x_axis, 0, ANGULAR_SPEED)--left max back
	Turn(l_foot, x_axis, 0, ANGULAR_SPEED)
	
	Turn(r_leg, x_axis, math.rad(-65), ANGULAR_SPEED)--right max forward
	Turn(r_foot, x_axis, math.rad(65), ANGULAR_SPEED)
	Move(r_shin, y_axis, -1.3, LINEAR_SPEED)
	WaitForTurn(r_leg, x_axis)
	
	Turn(l_leg, x_axis, math.rad(-20), ANGULAR_SPEED)
	Turn(l_foot, x_axis, math.rad(20), ANGULAR_SPEED)
	Move(l_shin, y_axis, 1, LINEAR_SPEED)
	
	Turn(r_leg, x_axis, math.rad(-35), ANGULAR_SPEED)
	Turn(r_foot, x_axis, math.rad(35), ANGULAR_SPEED)
	WaitForTurn(r_leg, x_axis)
	
	Turn(l_leg, x_axis, math.rad(-65), ANGULAR_SPEED)--left max forward
	Turn(l_foot, x_axis, math.rad(65), ANGULAR_SPEED)
	Move(l_shin, y_axis, -1.3, LINEAR_SPEED)
	Turn(l_pist1, x_axis, math.rad(-60), ANGULAR_SPEED*1.2)
	--Move(l_pist3, y_axis, 0.55, LINEAR_SPEED)
	Move(l_pist2, y_axis, 0.55, LINEAR_SPEED)
	
	Turn(r_leg, x_axis, 0, ANGULAR_SPEED)--right max back
	Turn(r_foot, x_axis, 0, ANGULAR_SPEED)
	WaitForTurn(l_leg, x_axis)
	Turn(r_pist1, x_axis, math.rad(-50), ANGULAR_SPEED)
	Move(r_pist1, y_axis, -0.45, LINEAR_SPEED)
	Move(r_pist2, y_axis, -0.45, LINEAR_SPEED)
end

function jumping(jumpPercent)
	if jumpPercent < 20 then
		GG.PokeDecloakUnit(unitID, unitDefID)
		EmitSfx(l_jetpt, 1026)
		EmitSfx(r_jetpt, 1026)
	end
	
	if jumpPercent > 95 and not landing then
		landing = true
		--StartThread(PrepareJumpLand)
	end
end

function beginJump()
	StartThread(BeginJumpThread)
end

function endJump()
	landing = false
	StartThread(EndJumpThread)
end

-- MOVING

local function walk()

	Signal(SIG_MOVE)
	SetSignalMask(SIG_MOVE)
	
	Turn(l_leg, x_axis, math.rad(-65), ANGULAR_SPEED)
	Turn(l_foot, x_axis, math.rad(65), ANGULAR_SPEED)
	Move(l_shin, y_axis, -2, LINEAR_SPEED)
	
	Turn(r_leg, x_axis, 0, ANGULAR_SPEED)
	Turn(r_foot, x_axis, 0, ANGULAR_SPEED)
	Move(r_shin, y_axis, 0, LINEAR_SPEED)

	while true do
	
		Move(base, y_axis, 1.5, LINEAR_SPEED)
		Turn(low_head, z_axis, math.rad(-(-7)), ANGULAR_SPEED/4)
		Turn(low_head, x_axis, math.rad(-5), ANGULAR_SPEED/2.4)
		
		Turn(l_leg, x_axis, math.rad(-35), ANGULAR_SPEED*1.4)
		Turn(l_foot, x_axis, math.rad(35), ANGULAR_SPEED)
		Move(l_shin, y_axis, -1.5, LINEAR_SPEED/1.5)
		
		Turn(r_leg, x_axis, math.rad(-20), ANGULAR_SPEED*1.4)
		Turn(r_foot, x_axis, math.rad(20), ANGULAR_SPEED)
		Move(r_shin, y_axis, 1, LINEAR_SPEED)
		Move(r_pist1, y_axis, 0.1, LINEAR_SPEED/2)
		Move(r_pist2, y_axis, 0.5, LINEAR_SPEED/2)
		
		WaitForTurn(low_head, x_axis)
	
		Move(base, y_axis, 0, LINEAR_SPEED/3)
		Turn(low_head, x_axis, math.rad(10), ANGULAR_SPEED/3)
		
		Turn(l_leg, x_axis, 0, ANGULAR_SPEED*1.6)--left max back
		Turn(l_foot, x_axis, 0, ANGULAR_SPEED*1.2)
		Turn(l_pist1, x_axis, math.rad(-50), ANGULAR_SPEED*1.2)
		Move(l_pist1, y_axis, -0.45, LINEAR_SPEED/2)
		Move(l_pist2, y_axis, -0.45, LINEAR_SPEED/2)
		
		Turn(r_leg, x_axis, math.rad(-65), ANGULAR_SPEED*1.4)--right max forward
		Turn(r_foot, x_axis, math.rad(65), ANGULAR_SPEED*1.2)
		Move(r_shin, y_axis, -1.3, LINEAR_SPEED/1.5)
		Turn(r_pist1, x_axis, math.rad(-60), ANGULAR_SPEED)
		
		WaitForTurn(r_leg, x_axis)
		Move(l_shin, y_axis, .5, LINEAR_SPEED*2)
	
		Move(base, y_axis, 1.5, LINEAR_SPEED)
		Turn(low_head, z_axis, math.rad(-(7)), ANGULAR_SPEED/4)
		Turn(low_head, x_axis, math.rad(-5), ANGULAR_SPEED/2.4)
		
		Turn(l_leg, x_axis, math.rad(-20), ANGULAR_SPEED*1.4)
		Turn(l_foot, x_axis, math.rad(20), ANGULAR_SPEED)
		Move(l_shin, y_axis, 1, LINEAR_SPEED)
		Move(l_pist1, y_axis, 0.1, LINEAR_SPEED/2)
		Move(l_pist2, y_axis, 0.5, LINEAR_SPEED/2)
		
		Turn(r_leg, x_axis, math.rad(-35), ANGULAR_SPEED*1.4)
		Turn(r_foot, x_axis, math.rad(35), ANGULAR_SPEED)
		Move(r_shin, y_axis, -1.5, LINEAR_SPEED/1.5)
		
		WaitForTurn(low_head, x_axis)
	
		Move(base, y_axis, 0, LINEAR_SPEED/3)
		Turn(low_head, x_axis, math.rad(10), ANGULAR_SPEED/3)
		
		Turn(l_leg, x_axis, math.rad(-65), ANGULAR_SPEED*1.4)--left max forward
		Turn(l_foot, x_axis, math.rad(65), ANGULAR_SPEED*1.2)
		Move(l_shin, y_axis, -1.3, LINEAR_SPEED/1.5)
		Turn(l_pist1, x_axis, math.rad(-60), ANGULAR_SPEED)
		
		Turn(r_leg, x_axis, 0, ANGULAR_SPEED*1.6)--right max back
		Turn(r_foot, x_axis, 0, ANGULAR_SPEED*1.4)
		Turn(r_pist1, x_axis, math.rad(-50), ANGULAR_SPEED*1.2)
		Move(r_pist1, y_axis, -0.45, LINEAR_SPEED/2)
		Move(r_pist2, y_axis, -0.45, LINEAR_SPEED/2)
		
		WaitForTurn(l_leg, x_axis)
		Move(r_shin, y_axis, .5, LINEAR_SPEED*2)
	
	end
end

function script.StartMoving()
	StartThread(walk)
end

function script.StopMoving()

	Signal(SIG_MOVE)
	--move all the pieces to their original spots
	
	Move(base, y_axis, 0, LINEAR_SPEED)
	if not firing then
		Turn(low_head, z_axis, math.rad(-(0)), ANGULAR_SPEED)
		Turn(low_head, x_axis, 0, ANGULAR_SPEED)
	end
	
	Turn(l_leg, x_axis, math.rad(-30), ANGULAR_SPEED)
	Turn(l_foot, x_axis, math.rad(30), ANGULAR_SPEED)
	Move(l_shin, y_axis, 0, LINEAR_SPEED)
	Turn(l_pist1, x_axis, math.rad(-50), ANGULAR_SPEED)
	Move(l_pist1, y_axis, 0, LINEAR_SPEED)
	Move(l_pist2, y_axis, 0, LINEAR_SPEED)
	
	Turn(r_leg, x_axis, math.rad(-30), ANGULAR_SPEED)
	Turn(r_foot, x_axis, math.rad(30), ANGULAR_SPEED)
	Move(r_shin, y_axis, 0, LINEAR_SPEED)
	Turn(r_pist1, x_axis, math.rad(-50), ANGULAR_SPEED)
	Move(r_pist1, y_axis, 0, LINEAR_SPEED)
	Move(r_pist2, y_axis, 0, LINEAR_SPEED)
end

function script.Create()
	Move(up_head, y_axis, -0.5) -- no mouth breathing

	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	
	Spin(tank, z_axis, 70)
	
	--initialize pieces
	
	Turn(l_leg, x_axis, math.rad(-30))
	Turn(l_foot, x_axis, math.rad(30))
	Turn(l_pist1, x_axis, math.rad(-50))
	
	Turn(r_leg, x_axis, math.rad(-30))
	Turn(r_foot, x_axis, math.rad(30))
	Turn(r_pist1, x_axis, math.rad(-50))
	
	Turn(l_jetpt, x_axis, math.rad(50))
	Turn(r_jetpt, x_axis, math.rad(50))
end


function script.AimFromWeapon()
	return low_head
end

function script.QueryWeapon()
	return firept
end

local function RestoreAfterDelay()
	Sleep(2500)
	Turn(low_head, y_axis, 0, math.rad(200))
	Turn(low_head, x_axis, 0, math.rad(45))
	Move(up_head, y_axis, -0.5, LINEAR_SPEED/3)
	firing = false
end

function script.AimWeapon(num, heading, pitch)

	Signal(SIG_AIM)
	SetSignalMask(SIG_AIM)
	firing = true
	--turn head, open mouth/limbs
	Turn(low_head, y_axis, heading, math.rad(650))
	Turn(low_head, x_axis, -pitch, math.rad(200))

	-- NB: lower_head (ie. jaw) shouldn't move because
	-- it is actually the parent piece for the upper head
	Move(up_head, y_axis, 3, LINEAR_SPEED*2)

	WaitForTurn(low_head, y_axis)
	WaitForTurn(low_head, x_axis)
	StartThread(RestoreAfterDelay)
	return true
end

function script.FireWeapon(num)
	EmitSfx(firept, 1026)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage / maxHealth
	if (severity <= 0.5) then
		Explode(base, SFX.NONE)
		Explode(l_foot, SFX.NONE)
		Explode(l_leg, SFX.NONE)
		Explode(r_foot, SFX.NONE)
		Explode(r_leg, SFX.NONE)
		return 1
	end
	Explode(base, SFX.SHATTER)
	Explode(l_foot, SFX.SHATTER)
	Explode(l_leg, SFX.SHATTER)
	Explode(r_foot, SFX.SHATTER)
	Explode(r_leg, SFX.SHATTER)
	return 2
end
