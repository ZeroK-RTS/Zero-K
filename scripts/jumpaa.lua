--linear constant 65536
--modified from Argh\'s PURE Artillery Shell Script

include "constants.lua"
include "JumpRetreat.lua"

local base, hips, torso = piece('base', 'hips', 'torso')
local launcher, rflare, rblast, lflare, lblast, cflare, cblast = piece('launcher', 'rflare', 'rblast', 'lflare', 'lblast', 'cflare', 'cblast')
local rshoulder, ruarm, rlarm, lshoulder, luarm, llarm = piece('rshoulder', 'ruarm', 'rlarm', 'lshoulder', 'luarm', 'llarm')
local rthigh, rshin, rfoot, lthigh, lshin, lfoot = piece('rthigh', 'rshin', 'rfoot', 'lthigh', 'lshin', 'lfoot')

local SIG_WALK = 1
local SIG_AIM1 = 2
local SIG_AIM2 = 4
local SIG_RESTORE = 8
local RUN_SPEED_FAST = 5

local smokePiece = {torso}

local gun_1 = 0
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------

--------------------------------------------------------------------/RUNNING
local function Walk()
	Signal(SIG_WALK)
	SetSignalMask(SIG_WALK)
	while true do
		--/RIGHT LEG
		Turn(lshoulder, x_axis, math.rad(45), math.rad(22.5*RUN_SPEED_FAST))
		Turn(llarm, x_axis, math.rad(-22.5), math.rad(22.5*RUN_SPEED_FAST))
		Turn(rshoulder, x_axis, 0, math.rad(22.5*RUN_SPEED_FAST))
		Turn(rlarm, x_axis, math.rad(-67.5), math.rad(22.5*RUN_SPEED_FAST))
	
		Turn(lthigh, x_axis, math.rad(16), math.rad(16*RUN_SPEED_FAST))
		Turn(lshin, x_axis, math.rad(15), math.rad(15*RUN_SPEED_FAST))	
		Turn(lfoot, x_axis, math.rad(-26), math.rad(26*RUN_SPEED_FAST))
		
		Turn(rthigh, x_axis, math.rad(-45), math.rad(38*RUN_SPEED_FAST))
		Turn(rshin, x_axis, math.rad(11), math.rad(26*RUN_SPEED_FAST))	
		Turn(rfoot, x_axis, math.rad(36), math.rad(41*RUN_SPEED_FAST))		
		Sleep(1000 / RUN_SPEED_FAST)
		
		--/FINISH CYCLE
		Turn(lthigh, x_axis, math.rad(-7), math.rad(23*RUN_SPEED_FAST))
		Turn(lshin, x_axis, math.rad(-13), math.rad(28*RUN_SPEED_FAST))	
		Turn(lfoot, x_axis, math.rad(-5), math.rad(21*RUN_SPEED_FAST))

		Turn(rthigh, x_axis, 0, math.rad(45*RUN_SPEED_FAST))
		Turn(rshin, x_axis, 0, math.rad(11*RUN_SPEED_FAST))	
		Turn(rfoot, x_axis, 0, math.rad(36*RUN_SPEED_FAST))	
				
		Sleep(1000 / RUN_SPEED_FAST)
		
		--/LEFT LEG
		Turn(rshoulder, x_axis, math.rad(45), math.rad(22.5*RUN_SPEED_FAST))
		Turn(rlarm, x_axis, math.rad(-22.5), math.rad(22.5*RUN_SPEED_FAST))
		Turn(lshoulder, x_axis, 0, math.rad(22.5*RUN_SPEED_FAST))
		Turn(llarm, x_axis, math.rad(-67.5), math.rad(22.5*RUN_SPEED_FAST))
		
		Turn(lthigh, x_axis, math.rad(-45), math.rad(38*RUN_SPEED_FAST))
		Turn(lshin, x_axis, math.rad(11), math.rad(26*RUN_SPEED_FAST))	
		Turn(lfoot, x_axis, math.rad(36), math.rad(41*RUN_SPEED_FAST))		
	
		Turn(rthigh, x_axis, math.rad(16), math.rad(16*RUN_SPEED_FAST))
		Turn(rshin, x_axis, math.rad(15), math.rad(15*RUN_SPEED_FAST))	
		Turn(rfoot, x_axis, math.rad(-26), math.rad(26*RUN_SPEED_FAST))
		
		Sleep(1000 / RUN_SPEED_FAST)
		
		--/FINISH CYCLE
		Turn(lthigh, x_axis, 0, math.rad(45*RUN_SPEED_FAST))
		Turn(lshin, x_axis, 0, math.rad(11*RUN_SPEED_FAST))	
		Turn(lfoot, x_axis, 0, math.rad(36*RUN_SPEED_FAST))		
	
		Turn(rthigh, x_axis, math.rad(-7), math.rad(23*RUN_SPEED_FAST))
		Turn(rshin, x_axis, math.rad(-13), math.rad(28*RUN_SPEED_FAST))	
		Turn(rfoot, x_axis, math.rad(-5), math.rad(21*RUN_SPEED_FAST))
		
		Sleep(1000 / RUN_SPEED_FAST)
	end	
end

function script.StartMoving()
	bMoving = true
	StartThread(Walk)
end

function script.StopMoving()
	bMoving = false
	Signal(SIG_WALK)
end

function script.Create()
--[[	Hide(rflare)
	Hide(lflare)
	Hide(cflare)
	Hide(rblast)
	Hide(lblast)
	Hide(cblast)]]--
	
	Turn(rblast, y_axis, math.rad(180))
	Turn(lblast, y_axis, math.rad(180))
	Turn(cblast, y_axis, math.rad(180))

	Turn(rshoulder, x_axis, math.rad(22.5))
	Turn(rlarm, x_axis, math.rad(-45))
	Turn(lshoulder, x_axis, math.rad(22.5))
	Turn(llarm, x_axis, math.rad(-45))

	StartThread(GG.Script.SmokeUnit, smokePiece)	
end

local function RestoreAfterDelay()
	Signal(SIG_RESTORE)
	SetSignalMask(SIG_RESTORE)
	Sleep(5000)
	Turn(torso, y_axis, 0, math.rad(65))
	Turn(launcher, x_axis, 0, math.rad(47.5))
end

function script.AimFromWeapon()
	return torso
end

function script.AimWeapon(num, heading, pitch)
	if num == 1 then
		Signal(SIG_AIM1)
		SetSignalMask(SIG_AIM1)
		Turn(torso, y_axis, heading, math.rad(600))
		Turn(launcher, x_axis, -pitch, math.rad(300))		
		WaitForTurn(torso, y_axis)
		WaitForTurn(launcher, x_axis)
		return true
	else
		Signal(SIG_AIM2)
		SetSignalMask(SIG_AIM2)
		Turn(torso, y_axis, heading, math.rad(600))
		Turn(launcher, x_axis, -pitch, math.rad(300))
		WaitForTurn(torso, y_axis)
		WaitForTurn(launcher, x_axis)
		StartThread(RestoreAfterDelay)
		return true
	end
end

function script.QueryWeapon(num)
	if num == 1 then
		return gun_1 == 0 and rflare or lflare
	else
		return cflare
	end
end

function script.FireWeapon(num)
	if num == 1 then
		gun_1 = 1 - gun_1
	end
end


-- Jumping
local turnSpeed

--function preJump(turn,distance,airDistance)
--	Signal(SIG_WALK)
--	local radians = turn*2*math.pi/2^16
--	turnSpeed = math.abs(turn*2*math.pi/2^16)
--	Turn(base, y_axis, radians, turnSpeed*1.5)
--	turnSpeed = turnSpeed*airDistance/1300
--	Move(base, y_axis, -12, 18)
--	--Turn(torso, x_axis, math.rad(10), math.rad(80))
--	
--	Turn(rshoulder, x_axis, math.rad(55), math.rad(200))
--	Turn(rlarm, x_axis, math.rad(-110), math.rad(200))
--	Turn(lshoulder, x_axis, math.rad(55), math.rad(200))
--	Turn(llarm, x_axis, math.rad(-110), math.rad(200))
--	
--	Turn(lthigh, x_axis, math.rad(50),math.rad(300))
--	Turn(lshin, x_axis, math.rad(-35), math.rad(150))	
--	Turn(lfoot, x_axis, math.rad(-10), math.rad(80))		
--
--	Turn(rthigh, x_axis, math.rad(50),math.rad(300))
--	Turn(rshin, x_axis, math.rad(-35), math.rad(150))	
--	Turn(rfoot, x_axis, math.rad(-10), math.rad(80))	
--end

function beginJump() 
	Signal(SIG_WALK)
	--Turn(base, y_axis, 0, turnSpeed)
	bJumping = true
	
	Turn(rshoulder, x_axis, math.rad(25), math.rad(30))
	Turn(rlarm, x_axis, math.rad(-25), math.rad(30))
	Turn(lshoulder, x_axis, math.rad(25), math.rad(30))
	Turn(llarm, x_axis, math.rad(-25), math.rad(30))
	
	Turn(lthigh, x_axis, math.rad(-20),math.rad(300))
	Turn(lshin, x_axis, math.rad(45), math.rad(400))	
	Turn(lfoot, x_axis, math.rad(-30), math.rad(80))		

	Turn(rthigh, x_axis, math.rad(-20),math.rad(300))
	Turn(rshin, x_axis, math.rad(45), math.rad(400))	
	Turn(rfoot, x_axis, math.rad(-30), math.rad(80))	
	
	--StartThread(JumpExhaust)
end

function jumping()
end

function halfJump()
	--Turn(torso, x_axis, math.rad(0), math.rad(80))
	Move(base, y_axis, 0, 18)
	
	Turn(lshin, x_axis, math.rad(0), math.rad(200))	
	Turn(lfoot, x_axis, math.rad(0), math.rad(80))	
	
	Turn(rshin, x_axis, math.rad(0), math.rad(200))	
	Turn(rfoot, x_axis, math.rad(0), math.rad(80))	
end

function endJump() 
	bJumping = false
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity <= .25 then
		Explode(lfoot, SFX.NONE)
		Explode(lshin, SFX.NONE)
		Explode(llarm, SFX.NONE)
		Explode(lthigh, SFX.NONE)
		Explode(luarm, SFX.NONE)
		Explode(hips, SFX.NONE)
		Explode(rfoot, SFX.NONE)
		Explode(rshin, SFX.NONE)
		Explode(rlarm, SFX.NONE)
		Explode(rthigh, SFX.NONE)
		Explode(ruarm, SFX.NONE)
		Explode(torso, SFX.NONE)
		return 1
	elseif severity <= .50 then
		Explode(lfoot, SFX.FALL)
		Explode(lshin, SFX.FALL)
		Explode(llarm, SFX.FALL)
		Explode(lthigh, SFX.FALL)
		Explode(luarm, SFX.FALL)
		Explode(hips, SFX.FALL)
		Explode(rfoot, SFX.FALL)
		Explode(rshin, SFX.FALL)
		Explode(rlarm, SFX.FALL)
		Explode(rthigh, SFX.FALL)
		Explode(ruarm, SFX.FALL)
		Explode(torso, SFX.SHATTER)
		return 1
	elseif severity <= .99 then
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(llarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(luarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(hips, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rlarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(ruarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER)
		return 2
	else
		Explode(lfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(llarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(lthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(luarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(hips, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rfoot, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rshin, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rlarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(rthigh, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(ruarm, SFX.FALL + SFX.SMOKE + SFX.FIRE + SFX.EXPLODE)
		Explode(torso, SFX.SHATTER + SFX.EXPLODE)
		return 2
	end
end